//
//  AXLinkChip.swift
//  AevonX
//
//  Pill-shaped link with icon + label, opens an external URL.
//  Used for hero links on plugin headers (Website, Docs, GitHub, Discord).
//

import SwiftUI

struct AXLinkChip: View {
    let label: String
    let icon: String
    let url: URL
    var tint: Color = .axAccentBlue

    @Environment(\.openURL) private var openURL
    @State private var isHovered = false

    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isHovered ? .white : tint)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs)
            .background(
                Capsule()
                    .fill(isHovered ? tint : tint.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(tint.opacity(isHovered ? 0 : 0.35), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(url.absoluteString)
    }
}

#Preview("AXLinkChip") {
    HStack(spacing: AXSpacing.sm) {
        AXLinkChip(label: "Website", icon: "globe",
                   url: URL(string: "https://aevonx.app")!,
                   tint: .axEmerald)
        AXLinkChip(label: "Docs", icon: "book.fill",
                   url: URL(string: "https://aevonx.app/docs")!,
                   tint: .axEmerald)
        AXLinkChip(label: "GitHub", icon: "chevron.left.forwardslash.chevron.right",
                   url: URL(string: "https://github.com/aevonxapp")!,
                   tint: .axEmerald)
    }
    .padding()
    .background(Color.axBackground)
}
