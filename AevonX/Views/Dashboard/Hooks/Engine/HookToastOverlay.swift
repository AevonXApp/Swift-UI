//
//  HookToastOverlay.swift
//  AevonX
//
//  SwiftUI overlay view for displaying toast notifications.
//  Uses HookToastManager from AevonXCore for state.
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

// MARK: - Toast Overlay View

public struct HookToastOverlay: View {
    @ObservedObject private var manager = HookToastManager.shared

    public init() {}

    public var body: some View {
        VStack(spacing: AXSpacing.sm) {
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.activeToasts.count)
    }

    private func toastView(_ toast: HookToast) -> some View {
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

    private func toastIconColor(_ type: HookToast.ToastType) -> Color {
        switch type {
        case .success: return .axSuccess
        case .error:   return .axError
        case .warning: return .axWarning
        case .info:    return .axAccentBlue
        }
    }

    private func toastBorderColor(_ type: HookToast.ToastType) -> Color {
        toastIconColor(type).opacity(0.3)
    }
}

// Backward compatibility
public typealias PluginToastOverlay = HookToastOverlay
