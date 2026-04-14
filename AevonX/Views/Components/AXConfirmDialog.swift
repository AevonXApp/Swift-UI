//
//  AXConfirmDialog.swift
//  AevonX
//
//  Async-await confirmation dialog used for destructive or high-impact
//  actions (Setup Webhook, Remove Webhook, Delete Database, etc.).
//
//  Pattern: `let ok = await AXConfirmDialog.shared.present(...)` — returns
//  true when the user confirms, false when they cancel or dismiss.
//

import SwiftUI
import Combine

@MainActor
public final class AXConfirmDialog: ObservableObject {
    public static let shared = AXConfirmDialog()

    @Published var request: ConfirmRequest? = nil

    private var continuation: CheckedContinuation<Bool, Never>?

    private init() {}

    /// Presents a confirmation dialog and suspends until the user answers.
    /// - Parameters:
    ///   - title: Short heading (e.g. "Setup Webhook").
    ///   - message: Prompt text — supports the plugin's `confirm_message`.
    ///   - confirmLabel: Text on the confirm button. Defaults to "Confirm".
    ///   - cancelLabel: Text on the cancel button. Defaults to "Cancel".
    ///   - isDestructive: When true, paints the confirm button red.
    /// - Returns: `true` when confirmed, `false` when cancelled.
    public func present(
        title: String,
        message: String,
        confirmLabel: String = "Confirm",
        cancelLabel: String = "Cancel",
        isDestructive: Bool = false
    ) async -> Bool {
        // If a request is already in-flight, drop the new one rather than
        // stacking sheets.
        if request != nil { return false }

        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.request = ConfirmRequest(
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                isDestructive: isDestructive
            )
        }
    }

    fileprivate func resolve(_ confirmed: Bool) {
        let cont = continuation
        continuation = nil
        request = nil
        cont?.resume(returning: confirmed)
    }
}

struct ConfirmRequest: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let isDestructive: Bool
}

// MARK: - Overlay

struct AXConfirmDialogOverlay: View {
    @ObservedObject private var dialog = AXConfirmDialog.shared

    var body: some View {
        ZStack {
            if let req = dialog.request {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dialog.resolve(false)
                    }

                card(for: req)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: dialog.request)
    }

    private func card(for req: ConfirmRequest) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: req.isDestructive ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(req.isDestructive ? .axError : .axAccentBlue)
                Text(req.title)
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
            }

            Text(req.message)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AXSpacing.sm) {
                Spacer()
                AXActionButton(
                    label: req.cancelLabel,
                    style: .ghost,
                    size: .regular
                ) {
                    dialog.resolve(false)
                }
                AXActionButton(
                    label: req.confirmLabel,
                    icon: req.isDestructive ? "trash" : "checkmark",
                    style: req.isDestructive ? .destructive : .primary,
                    size: .regular
                ) {
                    dialog.resolve(true)
                }
            }
            .padding(.top, AXSpacing.xs)
        }
        .padding(AXSpacing.xl)
        .frame(maxWidth: 460)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .fill(Color.axBackgroundElevated.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .strokeBorder(Color.axBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

#Preview {
    ZStack {
        Color.axBackground.ignoresSafeArea()
        AXConfirmDialogOverlay()
    }
    .task {
        try? await Task.sleep(nanoseconds: 200_000_000)
        _ = await AXConfirmDialog.shared.present(
            title: "Remove Webhook",
            message: "This will unregister the bot's Telegram webhook and switch to polling mode. Continue?",
            confirmLabel: "Remove",
            isDestructive: true
        )
    }
}
