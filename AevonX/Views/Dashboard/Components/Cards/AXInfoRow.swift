//
//  AXInfoRow.swift
//  AevonX
//
//  Simple label-value pair row with optional color accent.
//  Replaces statRow() in BruteForceSubTab, config display rows in SSHSubTab, etc.
//

import SwiftUI

// MARK: - AXInfoRow

struct AXInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .axTextPrimary
    var valueFont: Font = .system(size: 16, weight: .bold, design: .rounded)
    var icon: String? = nil
    var iconColor: Color = .axTextMuted
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
            }
            
            Text(label)
                .font(AXTypography.body)
                .foregroundColor(.axTextMuted)
            
            Spacer()
            
            Text(value)
                .font(valueFont)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Preview

#Preview("AXInfoRow") {
    AXCard {
        VStack(spacing: AXSpacing.lg) {
            AXInfoRow(label: "Currently Banned", value: "4", valueColor: .axError)
            AXInfoRow(label: "Total Banned", value: "127", valueColor: .axWarning)
            AXInfoRow(label: "Active Jail", value: "sshd", valueColor: .axSuccess)
            AXInfoRow(label: "Whitelisted", value: "3", valueColor: .axAccentBlue, icon: "shield.fill", iconColor: .axAccentBlue)
        }
    }
    .padding()
    .background(Color.axBackground)
    .frame(width: 400)
}
