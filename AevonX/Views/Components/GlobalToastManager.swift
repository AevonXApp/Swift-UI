//
//  GlobalToastManager.swift
//  AevonX
//
//  Global toast notification system
//  Displays non-blocking notifications in top-trailing corner
//

import SwiftUI
import Combine

// MARK: - Toast Types

public enum ToastType {
    case success
    case error
    case warning
    case info
    case loading

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .loading: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .success: return .axSuccess
        case .error: return .axError
        case .warning: return .axWarning
        case .info: return .axAccentBlue
        case .loading: return .axAccentBlue
        }
    }
}

public struct ToastItem: Identifiable, Equatable {
    public let id: String
    public let message: String
    public let type: ToastType
    public let timestamp: Date
    public var autoDismiss: Bool

    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

@MainActor
public final class GlobalToastManager: ObservableObject {
    public static let shared = GlobalToastManager()

    @Published public var toasts: [ToastItem] = []

    private var dismissTasks: [String: Task<Void, Never>] = [:]

    private init() {}

    public func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0) {
        let id = UUID().uuidString
        let toast = ToastItem(
            id: id,
            message: message,
            type: type,
            timestamp: Date(),
            autoDismiss: type != .loading
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toasts.append(toast)
            // Keep max 3 visible
            if toasts.count > 3 {
                let removed = toasts.removeFirst()
                dismissTasks[removed.id]?.cancel()
                dismissTasks.removeValue(forKey: removed.id)
            }
        }

        if toast.autoDismiss {
            scheduleDismiss(id: id, after: duration)
        }
    }

    public func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .success, duration: duration)
    }

    public func showError(_ message: String, duration: TimeInterval = 8.0) {
        show(message, type: .error, duration: duration)
    }

    public func showWarning(_ message: String, duration: TimeInterval = 5.0) {
        show(message, type: .warning, duration: duration)
    }

    public func showInfo(_ message: String, duration: TimeInterval = 4.0) {
        show(message, type: .info, duration: duration)
    }

    @discardableResult
    public func showProgress(_ message: String) -> String {
        let id = UUID().uuidString
        let toast = ToastItem(
            id: id,
            message: message,
            type: .loading,
            timestamp: Date(),
            autoDismiss: false
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toasts.append(toast)
            if toasts.count > 3 {
                let removed = toasts.removeFirst()
                dismissTasks[removed.id]?.cancel()
                dismissTasks.removeValue(forKey: removed.id)
            }
        }
        return id
    }

    public func updateProgress(id: String, message: String) {
        if let idx = toasts.firstIndex(where: { $0.id == id }) {
            toasts[idx] = ToastItem(
                id: id,
                message: message,
                type: .loading,
                timestamp: toasts[idx].timestamp,
                autoDismiss: false
            )
        }
    }

    public func dismiss(id: String) {
        dismissTasks[id]?.cancel()
        dismissTasks.removeValue(forKey: id)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toasts.removeAll { $0.id == id }
        }
    }

    public func dismissAll() {
        for (_, task) in dismissTasks { task.cancel() }
        dismissTasks.removeAll()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toasts.removeAll()
        }
    }

    private func scheduleDismiss(id: String, after duration: TimeInterval) {
        dismissTasks[id]?.cancel()
        dismissTasks[id] = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            dismiss(id: id)
        }
    }
}

// MARK: - Toast Overlay View

struct GlobalToastOverlay: View {
    @ObservedObject private var manager = GlobalToastManager.shared

    var body: some View {
        VStack(alignment: .trailing, spacing: AXSpacing.sm) {
            ForEach(manager.toasts) { toast in
                toastCard(toast)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .padding(.top, AXSpacing.xl)
        .padding(.trailing, AXSpacing.lg)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.toasts.count)
    }

    private func toastCard(_ toast: ToastItem) -> some View {
        HStack(spacing: AXSpacing.sm) {
            if toast.type == .loading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: toast.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(toast.type.color)
            }

            Text(toast.message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
                .lineLimit(2)

            Button {
                manager.dismiss(id: toast.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 18, height: 18)
                    .background(Color.axTextMuted.opacity(0.15))
                    .cornerRadius(9)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .frame(maxWidth: 400, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(toast.type.color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(toast.type.color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
