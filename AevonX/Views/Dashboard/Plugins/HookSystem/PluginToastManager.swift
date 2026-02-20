//
//  PluginToastManager.swift
//  AevonX
//
//  Global toast notification system for plugins.
//  Plugins can trigger toasts via on_success/on_error in JSON command responses.
//  Use PluginToastManager.shared.show(...) from anywhere.
//

import SwiftUI
import Combine

// MARK: - Toast Model

public struct PluginToast: Identifiable, Equatable {
    public let id = UUID()
    public let message: String
    public let type: ToastType
    public let icon: String?
    public let duration: TimeInterval

    public enum ToastType: Equatable {
        case success, error, warning, info
    }

    public static func == (lhs: PluginToast, rhs: PluginToast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

@MainActor
public final class PluginToastManager: ObservableObject {
    public static let shared = PluginToastManager()

    @Published public var activeToasts: [PluginToast] = []

    private init() {}

    public func show(_ message: String, type: PluginToast.ToastType = .info, icon: String? = nil, duration: TimeInterval = 3.0) {
        let toast = PluginToast(message: message, type: type, icon: icon, duration: duration)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            activeToasts.append(toast)
        }

        // Auto-dismiss
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    activeToasts.removeAll { $0.id == toast.id }
                }
            }
        }
    }

    public func success(_ message: String, icon: String? = nil) {
        show(message, type: .success, icon: icon ?? "checkmark.circle.fill")
    }

    public func error(_ message: String, icon: String? = nil) {
        show(message, type: .error, icon: icon ?? "exclamationmark.triangle.fill")
    }

    public func warning(_ message: String, icon: String? = nil) {
        show(message, type: .warning, icon: icon ?? "exclamationmark.circle.fill")
    }

    public func info(_ message: String, icon: String? = nil) {
        show(message, type: .info, icon: icon ?? "info.circle.fill")
    }
}

// MARK: - Toast Overlay View

/// Place this at the root of your app to show toast notifications.
/// Usage: .overlay(PluginToastOverlay())
public struct PluginToastOverlay: View {
    @ObservedObject private var manager = PluginToastManager.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            Spacer()
            ForEach(manager.activeToasts) { toast in
                toastView(toast)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.bottom, AXSpacing.xxl)
        .allowsHitTesting(false)
    }

    private func toastView(_ toast: PluginToast) -> some View {
        HStack(spacing: AXSpacing.sm) {
            if let icon = toast.icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(toastIconColor(toast.type))
            }

            Text(toast.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextPrimary)
                .lineLimit(2)

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    manager.activeToasts.removeAll { $0.id == toast.id }
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(true)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(toastBorderColor(toast.type), lineWidth: 1)
        )
        .frame(maxWidth: 420)
    }

    private func toastIconColor(_ type: PluginToast.ToastType) -> Color {
        switch type {
        case .success: return .axSuccess
        case .error:   return .axError
        case .warning: return .axWarning
        case .info:    return .axAccentBlue
        }
    }

    private func toastBorderColor(_ type: PluginToast.ToastType) -> Color {
        toastIconColor(type).opacity(0.3)
    }
}
