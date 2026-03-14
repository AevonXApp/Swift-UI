//
//  PluginControlBar.swift
//  AevonX
//
//  A unified status + control strip rendered at the top of each plugin namespace view.
//  Shows: icon · name · version · live service state · Start / Stop / Restart buttons.
//  Driven by `health_check` in the namespace _manifest.json — hidden when not present.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Plugin Control Bar

public struct PluginControlBar: View {
    public let namespace: HookNamespace
    public let serverId: String

    @StateObject private var controller = PluginServiceController.shared
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isActing: Bool = false

    public init(namespace: HookNamespace, serverId: String) {
        self.namespace = namespace
        self.serverId = serverId
    }

    private var manifest: HookNamespaceManifest? { namespace.manifest }
    private var serviceName: String { manifest?.healthCheck?.serviceName ?? namespace.id }
    private var state: PluginServiceState { controller.states[namespace.id] ?? .unknown }
    private var hasHealthCheck: Bool { manifest?.healthCheck != nil }

    public var body: some View {
        HStack(spacing: 12) {
            // ── Left: identity ───────────────────────────────────────────
            pluginIdentity

            Spacer()

            // ── Right: status + controls ─────────────────────────────────
            HStack(spacing: AXSpacing.sm) {
                ServiceStateBadge(state: state)

                if hasHealthCheck {
                    controlButtons
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(stateAccent.opacity(0.25), lineWidth: 1)
                )
        )
        .alert("Service Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            if let m = manifest {
                await controller.fetchStatus(namespace: namespace.id, manifest: m, serverId: serverId)
            }
        }
    }

    // MARK: - Sub-views

    private var pluginIdentity: some View {
        HStack(spacing: 10) {
            // Icon
            if let icon = manifest?.icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(stateAccent)
                    .frame(width: 28, height: 28)
            }

            // Name + version
            VStack(alignment: .leading, spacing: 2) {
                Text(namespace.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                if let ver = manifest?.version {
                    Text("v\(ver)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 6) {
            // Start
            if state == .stopped || state == .unknown || state == .failed("") {
                ControlButton(
                    label: "Start",
                    icon: "play.fill",
                    color: .green,
                    isLoading: isActing && state == .checking
                ) {
                    await performAction {
                        try await controller.start(namespace: namespace.id, serviceName: serviceName, serverId: serverId)
                    }
                }
            }

            // Stop
            if state == .running {
                ControlButton(
                    label: "Stop",
                    icon: "stop.fill",
                    color: .red,
                    isLoading: isActing && state == .checking
                ) {
                    await performAction {
                        try await controller.stop(namespace: namespace.id, serviceName: serviceName, serverId: serverId)
                    }
                }
            }

            // Restart (always available when health check exists)
            ControlButton(
                label: "Restart",
                icon: "arrow.clockwise",
                color: .orange,
                isLoading: isActing && state == .checking
            ) {
                await performAction {
                    try await controller.restart(namespace: namespace.id, serviceName: serviceName, serverId: serverId)
                }
            }

            // Refresh status
            ControlButton(
                label: "",
                icon: "arrow.triangle.2.circlepath",
                color: .secondary,
                isLoading: state == .checking && !isActing
            ) {
                if let m = manifest {
                    await controller.fetchStatus(namespace: namespace.id, manifest: m, serverId: serverId)
                }
            }
        }
    }

    // MARK: - Helpers

    private var stateAccent: Color {
        switch state {
        case .running:  return .green
        case .stopped:  return .secondary
        case .failed:   return .red
        default:        return .accentColor
        }
    }

    private func performAction(_ action: @escaping () async throws -> Void) async {
        isActing = true
        defer { isActing = false }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Service State Badge

public struct ServiceStateBadge: View {
    public let state: PluginServiceState
    public init(state: PluginServiceState) { self.state = state }

    public var body: some View {
        HStack(spacing: 5) {
            // Animated dot
            ZStack {
                if state == .running {
                    Circle()
                        .fill(dotColor.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: state)
                }
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
            }
            .frame(width: 14, height: 14)

            Text(state.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(dotColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(dotColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var dotColor: Color {
        switch state {
        case .running:  return .green
        case .stopped:  return .secondary
        case .failed:   return .red
        case .checking: return .orange
        case .unknown:  return .secondary
        }
    }
}

// MARK: - Control Button

private struct ControlButton: View {
    let label: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, label.isEmpty ? 7 : 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
