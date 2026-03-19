//
//  AppOptimizationComponents.swift
//  AevonX
//
//  Shared optimization UI components used by Nginx, PHP, and future adapters.
//  Extracted from NginxOptimizationSection's grouped design — the design standard.
//

import SwiftUI

// MARK: - Optimization Settings Group

/// A visually distinct group of optimization settings with a colored icon header.
/// Used to organize related settings into logical sections.
///
/// Example:
/// ```
/// AppOptimizationGroup(title: "Core", icon: "cpu.fill", color: .cyan) {
///     AppOptimizationRow(label: "worker_processes", value: $value, hint: "...", placeholder: "auto")
/// }
/// ```
struct AppOptimizationGroup<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.axTextPrimary)
            }

            VStack(spacing: 1) {
                content()
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Optimization Setting Row

/// A single text-input setting row with label, value, hint, and placeholder.
struct AppOptimizationRow: View {
    let label: String
    @Binding var value: String
    let hint: String
    let placeholder: String

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 240, alignment: .trailing)

            TextField(placeholder, text: $value)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(.plain)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .frame(width: 120)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                )

            Text(hint)
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Optimization Setting Row (with icon)

/// A compact setting row variant with an icon for PHP-style optimization layouts.
struct AppOptimizationIconRow: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var value: String

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextPrimary)
            Spacer()
            TextField("", text: $value)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 120)
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
}

// MARK: - Optimization Toggle Row

/// A segmented picker (Open/Close) row for on/off settings.
struct AppOptimizationToggle: View {
    let label: String
    @Binding var value: String
    let hint: String

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 240, alignment: .trailing)

            Picker("", selection: $value) {
                Text("Open").tag("on")
                Text("Close").tag("off")
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            Text(hint)
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Optimization Save Button

/// A styled gradient save button for optimization pages.
struct AppOptimizationSaveButton: View {
    let title: String
    let color: Color
    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                if isSaving { ProgressView().controlSize(.small) }
                Image(systemName: "checkmark.circle.fill").font(.system(size: 12))
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: 280)
            .padding(AXSpacing.md)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AXCornerRadius.lg)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isSaving)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton Loading Row

/// Skeleton loading state matching AppOptimizationRow dimensions.
struct AppOptimizationSkeletonRow: View {
    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface.opacity(0.5))
                .frame(width: 200, height: 14)
                .shimmer()

            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurface.opacity(0.5))
                .frame(width: 120, height: 28)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface.opacity(0.5))
                .frame(width: 150, height: 12)
                .shimmer()

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}
