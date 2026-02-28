//
//  AXIconButton.swift
//  AevonX
//
//  Compact icon-only action button with color background.
//  Used for row-level actions (play, stop, edit, delete, etc.)
//  Replaces actionButton() in CronJobRow, UnifiedServiceControlButtonInner
//  in ServiceControlButtons, and inline icon buttons in 30+ files.
//

import SwiftUI

// MARK: - AXIconButton

struct AXIconButton: View {
    let icon: String
    var color: Color = .axAccentBlue
    var size: CGFloat = 24
    var iconSize: CGFloat? = nil
    var tooltip: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var computedIconSize: CGFloat {
        iconSize ?? (size * 0.42)
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: size, height: size)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: computedIconSize, weight: .medium))
                        .foregroundColor(isEnabled ? color : .axTextMuted)
                }
            }
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(isEnabled
                          ? (isHovered ? color.opacity(0.15) : color.opacity(0.08))
                          : Color.axSurface.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .stroke(isHovered && isEnabled ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .help(tooltip ?? "")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview("AXIconButton") {
    HStack(spacing: AXSpacing.md) {
        AXIconButton(icon: "play.fill", color: .axSuccess, tooltip: "Start") {}
        AXIconButton(icon: "stop.fill", color: .axError, tooltip: "Stop") {}
        AXIconButton(icon: "arrow.clockwise", color: .axAccentBlue, tooltip: "Restart") {}
        AXIconButton(icon: "pencil", color: .axAccentBlue, tooltip: "Edit") {}
        AXIconButton(icon: "doc.text", color: .purple, tooltip: "Logs") {}
        AXIconButton(icon: "trash", color: .axError, tooltip: "Delete") {}
        AXIconButton(icon: "play.fill", color: .axSuccess, tooltip: "Disabled", isEnabled: false) {}
        AXIconButton(icon: "hourglass", color: .axAccentBlue, isLoading: true) {}
    }
    .padding()
    .background(Color.axBackground)
}
