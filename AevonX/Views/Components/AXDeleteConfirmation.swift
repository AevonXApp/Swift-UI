//
//  AXDeleteConfirmation.swift
//  AevonX
//
//  Enhanced deletion confirmation dialog with type-to-confirm support
//

import SwiftUI

struct AXDeleteConfirmation: View {
    let title: String
    let itemName: String
    let icon: String
    let warning: String
    let confirmLabel: String
    let requireTypeConfirm: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var confirmText = ""

    init(
        title: String,
        itemName: String,
        icon: String = "trash",
        warning: String = "This action cannot be undone.",
        confirmLabel: String = "Delete",
        requireTypeConfirm: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.itemName = itemName
        self.icon = icon
        self.warning = warning
        self.confirmLabel = confirmLabel
        self.requireTypeConfirm = requireTypeConfirm
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { onCancel() }

            dialogCard
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Dialog Card

    private var dialogCard: some View {
        VStack(spacing: 0) {
            headerSection
            contentSection

            Divider()
                .background(Color.axBorder)

            actionsSection
        }
        .frame(width: 380)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
    }

    private var headerSection: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axError.opacity(0.15))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.axError)
            }
            .frame(width: 36, height: 36)

            Text(title)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.md)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Item name pill
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextTertiary)

                Text(itemName)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(2)

                Image(systemName: "quote.closing")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextTertiary)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.sm)

            // Warning note
            HStack(alignment: .top, spacing: AXSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.axWarning)
                    .padding(.top, 2)

                Text(warning)
                    .font(AXTypography.caption)
                    .foregroundColor(.axWarning)
                    .italic()
            }
            .padding(AXSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.axWarning.opacity(0.05))
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axWarning.opacity(0.1), lineWidth: 1)
            )

            // Type-to-confirm field
            if requireTypeConfirm {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Type **\(itemName)** to confirm:")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)

                    TextField("", text: $confirmText)
                        .textFieldStyle(.plain)
                        .font(AXTypography.monoMd)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.sm)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(
                                    confirmText == itemName ? Color.axError : Color.axBorder,
                                    lineWidth: 1
                                )
                        )
                }
            }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.bottom, AXSpacing.xl)
    }

    private var actionsSection: some View {
        HStack(spacing: AXSpacing.md) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onConfirm) {
                Text(confirmLabel)
                    .font(AXTypography.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(isConfirmEnabled ? Color.axError : Color.axError.opacity(0.3))
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
            .disabled(!isConfirmEnabled)
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackgroundTertiary.opacity(0.5))
    }

    private var isConfirmEnabled: Bool {
        if requireTypeConfirm {
            return confirmText == itemName
        }
        return true
    }
}
