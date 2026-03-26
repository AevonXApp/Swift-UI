//
//  SettingsRowComponents.swift
//  AevonX
//
//  Reusable row components for settings sections
//

import SwiftUI

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool
    var tint: Color = .axAccentBlue

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(tint)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(title)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: tint))
                .frame(width: 40)
        }
    }
}

// MARK: - Settings Slider Row

struct SettingsSliderRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var unit: String = ""
    var formatter: ((Double) -> String)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 20)
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(title)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                }

                Spacer()

                Text(displayValue)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .monospacedDigit()
            }

            Slider(value: $value, in: range, step: step)
                .tint(.axAccentBlue)
        }
    }

    private var displayValue: String {
        if let formatter { return formatter(value) }
        return "\(Int(value))\(unit)"
    }
}

// MARK: - Settings Int Slider Row

struct SettingsIntSliderRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var unit: String = ""

    var body: some View {
        SettingsSliderRow(
            title: title,
            subtitle: subtitle,
            icon: icon,
            value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ),
            range: Double(range.lowerBound)...Double(range.upperBound),
            step: Double(step),
            unit: unit
        )
    }
}

// MARK: - Settings Picker Row

struct SettingsPickerRow<T: Hashable>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var selection: T
    let options: [(label: String, value: T)]

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(title)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 150)
        }
    }
}

// MARK: - Settings Stepper Row

struct SettingsStepperRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var value: Int
    let range: ClosedRange<Int>
    var unit: String = ""

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(title)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                Text("\(value)\(unit)")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .monospacedDigit()

                Stepper("", value: $value, in: range)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Settings Button Row

struct SettingsButtonRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var buttonLabel: String = ""
    var buttonColor: Color = .axAccentBlue
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        if !buttonLabel.isEmpty {
            labeledButtonRow
        } else {
            chevronRow
        }
    }

    private var labeledButtonRow: some View {
        HStack(spacing: AXSpacing.md) {
            rowIcon
            rowText
            Spacer()
            Button(action: action) {
                Text(buttonLabel)
                    .font(AXTypography.subheadline)
                    .foregroundColor(isDestructive ? .axError : buttonColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var chevronRow: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                rowIcon
                rowText
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var rowIcon: some View {
        if let icon {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isDestructive ? .axError : .axAccentBlue)
                .frame(width: 20)
        }
    }

    private var rowText: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
        }
    }
}

// MARK: - Settings Section Header

struct SettingsSectionHeader: View {
    let title: String
    let description: String
    let icon: String
    var iconColor: Color = .axAccentBlue

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.3), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(title)
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)

                Text(description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()
        }
    }
}

// MARK: - Settings Segmented Row

struct SettingsSegmentedRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var selection: String
    let options: [(label: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 20)
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(title)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                }

                Spacer()
            }

            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}
