//
//  AXLaunchFrameworkBadge.swift
//  AevonX
//
//  Badge showing detected framework with icon and confidence.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchFrameworkBadge: View {
    let info: AXProjectInfo

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            frameworkIcon
                .font(.system(size: 28))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Text(L10n.AXLaunch.matchPercent(Int(info.confidence * 100)))
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentGreen)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axAccentGreen.opacity(0.15))
                        .cornerRadius(AXCornerRadius.sm)
                }
                detailLine
            }

            Spacer()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var displayName: String {
        var name = info.type.capitalized
        if let ver = info.version, !ver.isEmpty {
            name += " \(ver)"
        }
        return name
    }

    @ViewBuilder
    private var frameworkIcon: some View {
        let icon: String = switch info.type.lowercased() {
        case "laravel": "leaf.fill"
        case "wordpress": "w.circle.fill"
        case "nextjs", "react": "atom"
        case "nodejs": "server.rack"
        case "django", "fastapi": "tortoise.fill"
        case "go", "golang": "hare.fill"
        case "docker": "shippingbox.fill"
        default: "folder.fill"
        }
        Image(systemName: icon)
            .foregroundStyle(Color.axAccentBlue)
    }

    @ViewBuilder
    private var detailLine: some View {
        let parts = buildDetailParts()
        if !parts.isEmpty {
            Text(parts.joined(separator: "  ·  "))
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
        }
    }

    private func buildDetailParts() -> [String] {
        var parts: [String] = []
        if let php = info.phpVersion { parts.append("PHP \(php)") }
        if let node = info.nodeVersion { parts.append("Node \(node)") }
        if let py = info.pythonVersion { parts.append("Python \(py)") }
        if let go = info.goVersion { parts.append("Go \(go)") }
        if info.hasDatabase { parts.append(info.databaseType?.capitalized ?? "Database") }
        if info.requiresRedis { parts.append("Redis") }
        if info.requiresNode { parts.append("npm") }
        return parts
    }
}
