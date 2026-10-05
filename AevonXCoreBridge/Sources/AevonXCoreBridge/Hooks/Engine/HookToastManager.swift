//
//  HookToastManager.swift
//  AevonXCoreBridge
//
//  Global toast notification system for hooks.
//  Hooks can trigger toasts via on_success/on_error in JSON command responses.
//

import Foundation
import Combine

// MARK: - Toast Model

public struct HookToast: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let message: String
    public let type: ToastType
    public let icon: String?
    public let duration: TimeInterval

    public enum ToastType: Equatable, Sendable {
        case success, error, warning, info
    }

    public static func == (lhs: HookToast, rhs: HookToast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

@MainActor
public final class HookToastManager: ObservableObject {
    public static let shared = HookToastManager()

    @Published public var activeToasts: [HookToast] = []

    private init() {}

    public func show(_ message: String, type: HookToast.ToastType = .info, icon: String? = nil, duration: TimeInterval = 3.0) {
        let toast = HookToast(message: message, type: type, icon: icon, duration: duration)
        activeToasts.append(toast)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                activeToasts.removeAll { $0.id == toast.id }
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

// Backward compatibility
public typealias PluginToastManager = HookToastManager
public typealias PluginToast = HookToast
