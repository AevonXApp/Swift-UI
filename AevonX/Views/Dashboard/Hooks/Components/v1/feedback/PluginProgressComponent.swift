//
//  PluginProgressComponent.swift
//  AevonX
//
//  Multi-step progress tracker with percentage, step status,
//  current action display, and cancel support.
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

public struct PluginProgressComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var progressData: ProgressState?
    @State private var pollingTask: Task<Void, Never>?

    struct ProgressState {
        let status: String
        let progress: Double
        let currentStep: String
        let steps: [StepInfo]
        let message: String

        struct StepInfo: Identifiable {
            let id = UUID()
            let name: String
            let status: String
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(statusColor.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    if let data = progressData {
                        Text(data.message.isEmpty ? data.status.capitalized : data.message)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
                if let data = progressData {
                    Text("\(Int(data.progress))%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor)
                }
            }

            if let data = progressData {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.axBackground)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [statusColor.opacity(0.8), statusColor],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(data.progress / 100))
                            .animation(.easeInOut(duration: 0.4), value: data.progress)
                    }
                }
                .frame(height: 10)

                if !data.steps.isEmpty {
                    VStack(spacing: AXSpacing.xs) {
                        ForEach(data.steps) { step in
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: stepIcon(step.status))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(stepColor(step.status))
                                    .frame(width: 16)
                                Text(step.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(step.status == "pending" ? .axTextMuted : .axTextPrimary)
                                Spacer()
                                if step.status == "running" {
                                    ProgressView().scaleEffect(0.5)
                                }
                            }
                        }
                    }
                    .padding(.top, AXSpacing.xs)
                }

                if !data.currentStep.isEmpty && data.status == "running" {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.axAccentBlue)
                        Text(data.currentStep)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: AXSpacing.sm) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.axTextMuted)
                        Text("Waiting to start...")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextMuted)
                    }
                    Spacer()
                }
                .padding(.vertical, AXSpacing.lg)
            }

            HStack(spacing: AXSpacing.md) {
                if let command = plugin.command, progressData?.status != "running" {
                    Button(action: {
                        Task {
                            await vm.execute(command: command, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)
                            startPolling()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text("Start")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axAccentBlue))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .onDisappear { pollingTask?.cancel() }
    }

    private var statusColor: Color {
        switch progressData?.status {
        case "done":    return .axSuccess
        case "error":   return .axError
        case "running": return .axAccentBlue
        default:        return .axTextMuted
        }
    }

    private func stepIcon(_ status: String) -> String {
        switch status {
        case "done":    return "checkmark.circle.fill"
        case "running": return "circle.dashed"
        case "error":   return "xmark.circle.fill"
        default:        return "circle"
        }
    }

    private func stepColor(_ status: String) -> Color {
        switch status {
        case "done":    return .axSuccess
        case "running": return .axAccentBlue
        case "error":   return .axError
        default:        return .axTextMuted
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            guard let ds = plugin.dataSource else { return }
            let pollVM = HookPluginViewModel()
            let cmd = HookPluginCommand(type: ds.type ?? .pluginCmd, action: ds.action, payload: ds.payload)

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { break }

                await pollVM.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

                if let output = pollVM.resultOutput,
                   let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    let steps = (json["steps"] as? [[String: String]] ?? []).map {
                        ProgressState.StepInfo(name: $0["name"] ?? "", status: $0["status"] ?? "pending")
                    }

                    await MainActor.run {
                        progressData = ProgressState(
                            status: json["status"] as? String ?? "idle",
                            progress: json["progress"] as? Double ?? 0,
                            currentStep: json["current_step"] as? String ?? "",
                            steps: steps,
                            message: json["message"] as? String ?? ""
                        )
                    }

                    if ["done", "error", "idle"].contains(json["status"] as? String ?? "") {
                        break
                    }
                }
            }
        }
    }
}
