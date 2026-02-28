//
//  AXToggleRow.swift
//  AevonX
//
//  Labeled toggle row with optional description and icon.
//  Replaces inline toggle patterns in SSH config, Firewall,
//  Website Security, PHP config, and Nginx security sections.
//

import SwiftUI

// MARK: - AXToggleRow

struct AXToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = .axAccentBlue
    var onChange: ((Bool) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(iconColor.opacity(isOn ? 0.12 : 0.05))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isOn ? iconColor : .axTextMuted)
                }
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(label)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.axAccentBlue)
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .padding(.vertical, AXSpacing.xs)
    }
}

// MARK: - Preview

#Preview("AXToggleRow") {
    AXCard {
        VStack(spacing: AXSpacing.sm) {
            AXToggleRow(
                label: "Root Login",
                isOn: .constant(false),
                subtitle: "Allow root user to connect via SSH",
                icon: "person.fill.xmark",
                iconColor: .axError
            )
            Divider()
            AXToggleRow(
                label: "Password Authentication",
                isOn: .constant(true),
                subtitle: "Allow password-based SSH authentication",
                icon: "key.fill",
                iconColor: .axAccentBlue
            )
            Divider()
            AXToggleRow(
                label: "X11 Forwarding",
                isOn: .constant(false)
            )
        }
    }
    .padding()
    .frame(width: 500)
    .background(Color.axBackground)
}
