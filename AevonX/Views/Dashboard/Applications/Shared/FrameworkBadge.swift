//
//  FrameworkBadge.swift
//  AevonX
//
//  Reusable framework badge component for displaying detected frameworks
//  (Django, Flask, FastAPI, Next.js, Express, NestJS, etc.)
//

import SwiftUI

struct FrameworkBadge: View {
    let name: String
    let version: String?
    let icon: String
    let color: Color
    var extras: [String] = []

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Framework icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if let ver = version {
                    Text("v\(ver)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            // Extra badges (e.g., "TypeScript", "Celery")
            ForEach(extras, id: \.self) { extra in
                Text(extra)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AXCornerRadius.sm)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Python Framework Badge Factory

extension FrameworkBadge {
    static func python(framework: String, version: String?, hasCelery: Bool = false, hasRedis: Bool = false) -> FrameworkBadge {
        let (icon, color, name): (String, Color, String) = {
            switch framework.lowercased() {
            case "django": return ("d.circle.fill", Color(hex: "#092E20"), "Django")
            case "flask": return ("flask.fill", Color(hex: "#000000"), "Flask")
            case "fastapi": return ("bolt.circle.fill", Color(hex: "#009688"), "FastAPI")
            default: return ("chevron.left.forwardslash.chevron.right", Color(hex: "#3776AB"), "Python")
            }
        }()

        var extras: [String] = []
        if hasCelery { extras.append("Celery") }
        if hasRedis { extras.append("Redis") }

        return FrameworkBadge(name: name, version: version, icon: icon, color: color, extras: extras)
    }

    static func nodejs(framework: String, version: String?, hasTypeScript: Bool = false) -> FrameworkBadge {
        let (icon, color, name): (String, Color, String) = {
            switch framework.lowercased() {
            case "nextjs", "next.js": return ("n.circle.fill", Color(hex: "#000000"), "Next.js")
            case "express": return ("e.circle.fill", Color(hex: "#000000"), "Express")
            case "nestjs": return ("bird.fill", Color(hex: "#E0234E"), "NestJS")
            case "nuxt": return ("n.square.fill", Color(hex: "#00DC82"), "Nuxt")
            case "remix": return ("r.circle.fill", Color(hex: "#121212"), "Remix")
            case "fastify": return ("bolt.circle.fill", Color(hex: "#000000"), "Fastify")
            case "koa": return ("k.circle.fill", Color(hex: "#33333D"), "Koa")
            case "adonis", "adonisjs": return ("a.circle.fill", Color(hex: "#5A45FF"), "AdonisJS")
            default: return ("server.rack", Color(hex: "#339933"), "Node.js")
            }
        }()

        var extras: [String] = []
        if hasTypeScript { extras.append("TypeScript") }

        return FrameworkBadge(name: name, version: version, icon: icon, color: color, extras: extras)
    }
}
