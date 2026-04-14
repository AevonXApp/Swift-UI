//
//  AXSegmentedControl.swift
//  AevonX
//
//  Tinted segmented switcher used by tab bars (Marketplace/Installed) and
//  inline mode toggles (Configure/Edit Raw File). Replaces SwiftUI's default
//  SegmentedPickerStyle, which doesn't honour the AX design tokens.
//

import SwiftUI

struct AXSegmentedControl<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String, icon: String?)]
    var tint: Color = .axAccentBlue
    var size: Size = .regular

    enum Size {
        case compact, regular

        var fontSize: CGFloat { self == .compact ? 11 : 12 }
        var hPad: CGFloat { self == .compact ? AXSpacing.sm : AXSpacing.md }
        var vPad: CGFloat { self == .compact ? AXSpacing.xxs : AXSpacing.xs }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                segmentButton(option)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .strokeBorder(Color.axBorder, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func segmentButton(_ option: (value: Value, label: String, icon: String?)) -> some View {
        let isSelected = option.value == selection
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = option.value
            }
        } label: {
            HStack(spacing: AXSpacing.xxs) {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize - 1, weight: .semibold))
                }
                Text(option.label)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(isSelected ? .white : .axTextSecondary)
            .padding(.horizontal, size.hPad)
            .padding(.vertical, size.vPad)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(isSelected ? tint : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("AXSegmentedControl") {
    struct Wrapper: View {
        @State var tab: String = "marketplace"
        @State var mode: String = "configure"
        var body: some View {
            VStack(spacing: AXSpacing.lg) {
                AXSegmentedControl(
                    selection: $tab,
                    options: [
                        ("marketplace", "Marketplace", "bag.fill"),
                        ("installed", "Installed", "checkmark.seal.fill")
                    ],
                    tint: .axEmerald
                )
                .frame(width: 280)

                AXSegmentedControl(
                    selection: $mode,
                    options: [
                        ("configure", "Configure", nil),
                        ("raw", "Edit Raw File", nil)
                    ],
                    tint: .axCyan,
                    size: .compact
                )
                .frame(width: 240)
            }
            .padding()
            .background(Color.axBackground)
        }
    }
    return Wrapper()
}
