//
//  ServerSettingsComponents.swift
//  AevonX
//
//  Reusable UI components for server settings sections.
//  No business logic — display only.
//

import SwiftUI

// MARK: - Gradient Header

struct SettingsGradientHeader: View {
    let icon: String
    let title: String
    let subtitle: String?
    let gradient: [Color]

    init(icon: String, title: String, subtitle: String? = nil, gradient: [Color] = [.axAccentBlue, .axAccentBlue.opacity(0.6)]) {
        self.icon = icon; self.title = title; self.subtitle = subtitle; self.gradient = gradient
    }

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                    .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, y: 2)
                Image(systemName: icon)
                    .font(AXTypography.title3)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(title)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
    }
}

// MARK: - Collapsible Section Header

struct CollapsibleSectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String?
    let gradient: [Color]
    @Binding var isExpanded: Bool
    var trailing: AnyView?

    init(icon: String, title: String, subtitle: String? = nil, gradient: [Color] = [.axAccentBlue, .axAccentBlue.opacity(0.6)], isExpanded: Binding<Bool>, trailing: AnyView? = nil) {
        self.icon = icon; self.title = title; self.subtitle = subtitle; self.gradient = gradient
        self._isExpanded = isExpanded; self.trailing = trailing
    }

    var body: some View {
        HStack {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                SettingsGradientHeader(icon: icon, title: title, subtitle: subtitle, gradient: gradient)
            }
            .buttonStyle(PlainButtonStyle())

            if let trailing { trailing }

            Image(systemName: "chevron.right")
                .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? L10n.Status.enabled : L10n.Status.disabled)
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Info Row

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color

    init(icon: String, title: String, value: String, valueColor: Color = .axTextSecondary) {
        self.icon = icon; self.title = title; self.value = value; self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(AXTypography.callout)
                .foregroundColor(.axTextMuted)
                .frame(width: 22)
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(AXTypography.monoSm)
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value.isEmpty ? "none" : value)")
    }
}

// MARK: - Toggle Row

struct ServerSettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(AXTypography.callout)
                .foregroundColor(.axTextMuted)
                .frame(width: 22)
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Toggle(title, isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: tint))
                .labelsHidden()
                .frame(width: 40)
        }
    }
}

// MARK: - Inline Message

struct SettingsInlineMsg: View {
    let text: String
    let isSuccess: Bool

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(AXTypography.subheadline)
            Text(text)
                .font(AXTypography.caption)
                .lineLimit(2)
        }
        .foregroundColor(isSuccess ? .axSuccess : .axError)
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isSuccess ? Color.axSuccess : Color.axError).opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
}

// MARK: - Password Row

struct SettingsPasswordRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var newPwd: String
    @Binding var confirmPwd: String
    let isChanging: Bool
    let message: (String, Bool)?
    let action: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(AXTypography.callout).fontWeight(.semibold)
                    .foregroundColor(.axWarning)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(AXTypography.subheadline).fontWeight(.medium).foregroundColor(.axTextPrimary)
                    Text(subtitle).font(AXTypography.footnote).foregroundColor(.axTextTertiary)
                }
            }

            HStack(spacing: AXSpacing.sm) {
                SecureField(L10n.ServerSettings.newPassword, text: $newPwd)
                    .font(AXTypography.callout)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xs)
                    .background(Color.axBackgroundTertiary)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    .cornerRadius(AXCornerRadius.sm)

                SecureField(L10n.ServerSettings.confirmPassword, text: $confirmPwd)
                    .font(AXTypography.callout)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xs)
                    .background(Color.axBackgroundTertiary)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    .cornerRadius(AXCornerRadius.sm)

                Button(action: { Task { await action() } }) {
                    HStack(spacing: AXSpacing.xxs) {
                        if isChanging { ProgressView().scaleEffect(0.6) }
                        else { Image(systemName: "lock.rotation").font(AXTypography.footnote) }
                        Text(L10n.Button.change).font(AXTypography.footnote).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
                    .background(LinearGradient(colors: [.axWarning, .axWarning.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isChanging || newPwd.isEmpty || confirmPwd.isEmpty)
            }

            if let msg = message {
                SettingsInlineMsg(text: msg.0, isSuccess: msg.1)
            }
        }
    }
}

// MARK: - Disk Usage Bar

struct DiskUsageBar: View {
    let percent: Int

    private var barColor: Color {
        if percent >= 90 { return .axError }
        if percent >= 70 { return .axWarning }
        return .axAccentGreen
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.axBackgroundTertiary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [barColor, barColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(percent) / 100)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("Disk usage \(percent) percent")
        .accessibilityValue("\(percent)%")
    }
}
