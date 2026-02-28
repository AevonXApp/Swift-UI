//
//  AXTabSwitcher.swift
//  AevonX
//
//  Generic tab selector with highlight animation.
//  Replaces inline tab button patterns in 5+ files
//  (AuditLogSection, FileIntegritySection, AISecuritySection, SSHSubTab, etc.)
//

import SwiftUI

// MARK: - Tab Item

struct AXTabItem: Identifiable {
    let id: String
    let label: String
    var icon: String? = nil
    
    init(id: String? = nil, label: String, icon: String? = nil) {
        self.id = id ?? label
        self.label = label
        self.icon = icon
    }
}

// MARK: - AXTabSwitcher

struct AXTabSwitcher: View {
    let tabs: [AXTabItem]
    @Binding var selected: Int
    var accentColor: Color = .axAccentBlue
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = index
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if let icon = tab.icon {
                            Image(systemName: icon)
                                .font(.system(size: 11))
                        }
                        Text(tab.label)
                            .font(.system(size: 12, weight: selected == index ? .semibold : .regular))
                    }
                    .foregroundColor(selected == index ? .axTextPrimary : .axTextMuted)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(selected == index ? accentColor.opacity(0.15) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
    }
}

// Convenience for simple string array
extension AXTabSwitcher {
    init(labels: [String], selected: Binding<Int>, accentColor: Color = .axAccentBlue) {
        self.tabs = labels.map { AXTabItem(label: $0) }
        self._selected = selected
        self.accentColor = accentColor
    }
}

// MARK: - Preview

#Preview("AXTabSwitcher") {
    VStack(spacing: AXSpacing.xl) {
        AXTabSwitcher(
            labels: ["Auth Log", "Sudo Log", "System Log"],
            selected: .constant(0)
        )
        
        AXTabSwitcher(
            tabs: [
                AXTabItem(label: "SUID/SGID Files", icon: "lock.open.fill"),
                AXTabItem(label: "World-Writable", icon: "pencil.circle.fill"),
            ],
            selected: .constant(1),
            accentColor: .axWarning
        )
    }
    .padding()
    .background(Color.axBackground)
}
