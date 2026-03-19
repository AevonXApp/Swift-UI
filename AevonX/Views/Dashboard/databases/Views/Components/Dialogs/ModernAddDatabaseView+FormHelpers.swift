//
//  ModernAddDatabaseView+FormHelpers.swift
//  AevonX
//
//  Footer, error toast, and reusable building blocks
//  for the add database dialog.
//

import SwiftUI
import AevonXCoreBridge

extension ModernAddDatabaseView {
    // MARK: - Footer

    var footerBar: some View {
        HStack(spacing: AXSpacing.md) {
            if viewModel.didSucceed {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AXTypography.headline)
                        .foregroundColor(.axSuccess)
                    Text("Database created!")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axSuccess)
                }
                Spacer()
                Button(action: { onCreated(); dismiss() }) {
                    Text("Done")
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.xl)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axSuccess)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            } else {
                if viewModel.isSubmitting {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(.axTextMuted)
                        Text(viewModel.operationResult.message ?? "Creating...")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSubmitting)

                Button(action: { Task { await viewModel.submitForm() } }) {
                    Text(viewModel.isSubmitting ? "Creating..." : "Create Database")
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.xl)
                        .padding(.vertical, AXSpacing.md)
                        .background(
                            Group {
                                if viewModel.isFormValid && !viewModel.isSubmitting {
                                    LinearGradient(
                                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    LinearGradient(
                                        colors: [Color.axTextMuted.opacity(0.3), Color.axTextMuted.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .shadow(color: viewModel.isFormValid ? Color.axAccentBlue.opacity(0.25) : .clear, radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            Color.axSurface.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(Color.axBorder.opacity(0.5))
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Error Toast

    @ViewBuilder
    var errorToast: some View {
        if viewModel.operationResult.isFailure {
            VStack {
                Spacer()
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "xmark.octagon.fill")
                        .font(AXTypography.headline)
                        .foregroundColor(.axError)

                    Text(viewModel.operationResult.message ?? "Something went wrong")
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.axError)
                        .lineLimit(2)

                    Spacer()

                    Button { viewModel.operationResult = .idle } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axError.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axError.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, AXSpacing.xl)
                .padding(.bottom, 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring(response: 0.4), value: viewModel.operationResult.isFailure)
        }
    }

    // MARK: - Reusable Building Blocks

    func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
            Text(title)
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }

    func styledTextField(placeholder: String, text: Binding<String>, hasError: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .font(AXTypography.body)
            .foregroundColor(.axTextPrimary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm + 2)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(hasError ? Color.axError.opacity(0.8) : Color.axBorder, lineWidth: 1)
            )
    }

    func styledPicker(
        label: String,
        icon: String,
        selection: Binding<String>,
        options: [String],
        displayTransform: ((String) -> String)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionLabel(label, icon: icon)

            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayTransform?(option) ?? option).tag(option)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xs)
            .padding(.horizontal, AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
    }

    func errorHint(_ message: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: "exclamationmark.circle")
                .font(AXTypography.caption2)
            Text(message)
                .font(AXTypography.caption2)
        }
        .foregroundColor(.axError)
    }
}
