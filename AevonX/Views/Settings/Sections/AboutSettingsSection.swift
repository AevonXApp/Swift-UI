//
//  AboutSettingsSection.swift
//  AevonX
//
//  Premium About section with 3D depth, glassmorphism, and immersive hero
//

import SwiftUI
import AevonXCoreBridge

struct AboutSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager
    @ObservedObject private var updateService = AppUpdateService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxl) {
            heroHeader
            socialGrid
            legalStrip
            debugSection
            copyrightFooter
        }
    }

    // MARK: - Hero Header (3D floating card)

    private var heroHeader: some View {
        AboutHeroCard(updateChannel: settings.updateChannel)
    }

    // MARK: - Social Grid (2×3 cards)

    private var socialGrid: some View {
        AboutSocialGrid()
    }

    // MARK: - Legal Strip

    private var legalStrip: some View {
        AboutLegalStrip()
    }

    // MARK: - Debug & Support

    private var debugSection: some View {
        AboutDebugSection(
            updateService: updateService,
            updateChannel: settings.updateChannel
        )
    }

    // MARK: - Copyright

    private var copyrightFooter: some View {
        AboutCopyrightFooter()
    }
}

// MARK: - Hero Card

private struct AboutHeroCard: View {
    let updateChannel: String
    @State private var iconFloat: Bool = false
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // Layered glow background
            RoundedRectangle(cornerRadius: AXCornerRadius.xxl)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "00D4AA").opacity(glowPulse ? 0.12 : 0.06),
                            Color(hex: "00B4D8").opacity(glowPulse ? 0.08 : 0.03),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 300
                    )
                )

            VStack(spacing: AXSpacing.xl) {
                // Floating app icon with 3D shadow stack
                ZStack {
                    // Deep shadow
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 88, height: 88)
                        .offset(y: 8)
                        .blur(radius: 16)

                    // Mid shadow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "00D4AA").opacity(0.15))
                        .frame(width: 84, height: 84)
                        .offset(y: 4)
                        .blur(radius: 8)

                    // Icon
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .offset(y: iconFloat ? -3 : 3)
                }
                .padding(.top, AXSpacing.lg)

                // App name
                Text("AevonX")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4AA"), Color(hex: "00B4D8"), Color(hex: "7C6AFF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Tagline
                Text("Server Management, Reimagined.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .tracking(0.5)

                // Version + Build pills
                HStack(spacing: AXSpacing.sm) {
                    infoPill("v\(BuildConfiguration.appVersion)", icon: "tag.fill", color: Color(hex: "00D4AA"))
                    infoPill("Build \(BuildConfiguration.buildNumber)", icon: "hammer.fill", color: .axAccentBlue)
                    channelPill(updateChannel)
                }

                // Platform
                Text("\(BuildConfiguration.platform) · \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .padding(.bottom, AXSpacing.lg)
            }
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xxl)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xxl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D4AA").opacity(0.3),
                                    Color.axBorder.opacity(0.5),
                                    Color(hex: "00B4D8").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 20, y: 10)
                .shadow(color: Color(hex: "00D4AA").opacity(0.08), radius: 40, y: 20)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                iconFloat = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private func infoPill(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextSecondary)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs + 1)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.15), lineWidth: 0.5))
    }

    private func channelPill(_ channel: String) -> some View {
        let isStable = channel == "stable"
        let color: Color = isStable ? .axAccentGreen : .axWarning
        return Text(channel.capitalized)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs + 1)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Social Grid

private struct AboutSocialGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionLabel("Connect", icon: "link.circle.fill")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AXSpacing.md),
                GridItem(.flexible(), spacing: AXSpacing.md),
                GridItem(.flexible(), spacing: AXSpacing.md)
            ], spacing: AXSpacing.md) {
                SocialCard(
                    sfIcon: "globe",
                    title: "Website",
                    subtitle: "aevonx.app",
                    color: .axAccentBlue,
                    url: AppURLs.website
                )
                SocialCard(
                    assetIcon: "github",
                    title: "GitHub",
                    subtitle: "AevonXApp",
                    color: .white.opacity(0.7),
                    url: AppURLs.github
                )
                SocialCard(
                    assetIcon: "x",
                    title: "X",
                    subtitle: "@AevonXApp",
                    color: .white.opacity(0.7),
                    url: AppURLs.twitter
                )
                SocialCard(
                    sfIcon: "book.fill",
                    title: "Docs",
                    subtitle: "docs.aevonx.app",
                    color: .axAccentGreen,
                    url: AppURLs.docs
                )
                SocialCard(
                    sfIcon: "megaphone.fill",
                    title: "Changelog",
                    subtitle: "What's new",
                    color: .axAccentPurple,
                    url: AppURLs.changelog
                )
                SocialCard(
                    sfIcon: "exclamationmark.bubble.fill",
                    title: "Issues",
                    subtitle: "Report a bug",
                    color: .axWarning,
                    url: URL(string: "\(AppURLs.github.absoluteString)/issues")!
                )
            }
        }
    }
}

private struct SocialCard: View {
    var sfIcon: String?
    var assetIcon: String?
    let title: String
    let subtitle: String
    let color: Color
    let url: URL

    @State private var isHovered = false

    var body: some View {
        Link(destination: url) {
            VStack(spacing: AXSpacing.sm) {
                // Icon with 3D depth
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(color.opacity(0.06))
                        .frame(width: 48, height: 48)
                        .offset(y: isHovered ? 1 : 3)
                        .blur(radius: 5)

                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(color.opacity(isHovered ? 0.15 : 0.08))
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(color.opacity(isHovered ? 0.3 : 0.15), lineWidth: 0.5)
                        )
                        .offset(y: isHovered ? -1 : 0)

                    Group {
                        if let assetIcon {
                            Image(assetIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        } else if let sfIcon {
                            Image(systemName: sfIcon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(color)
                        }
                    }
                    .offset(y: isHovered ? -1 : 0)
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextPrimary)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(
                                isHovered ? color.opacity(0.3) : Color.axBorder.opacity(0.6),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isHovered ? color.opacity(0.12) : Color.black.opacity(0.08),
                        radius: isHovered ? 12 : 6,
                        y: isHovered ? 4 : 3
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { over in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = over
            }
        }
    }
}

// MARK: - Legal Strip

private struct AboutLegalStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionLabel("Legal", icon: "doc.text.fill")

            HStack(spacing: AXSpacing.md) {
                LegalPill("Privacy", icon: "hand.raised.fill", url: AppURLs.privacy)
                LegalPill("Terms", icon: "doc.plaintext", url: AppURLs.terms)
                LegalPill("License", icon: "checkmark.seal.fill", url: AppURLs.license)
                LegalPill("OSS", icon: "heart.fill", url: URL(string: "\(AppURLs.base)/oss")!)
            }
        }
    }
}

private struct LegalPill: View {
    let title: String
    let icon: String
    let url: URL
    @State private var isHovered = false

    init(_ title: String, icon: String, url: URL) {
        self.title = title
        self.icon = icon
        self.url = url
    }

    var body: some View {
        Link(destination: url) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(isHovered ? .axAccentBlue : .axTextTertiary)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isHovered ? .axTextPrimary : .axTextSecondary)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isHovered ? Color.axSurfaceHover : Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(isHovered ? Color.axAccentBlue.opacity(0.3) : Color.axBorder.opacity(0.5), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { over in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isHovered = over
            }
        }
    }
}

// MARK: - Debug Section

private struct AboutDebugSection: View {
    @ObservedObject var updateService: AppUpdateService
    let updateChannel: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionLabel("Debug & Support", icon: "ladybug.fill")

            AXCard {
                VStack(spacing: AXSpacing.md) {
                    SettingsButtonRow(
                        title: "Copy Debug Info",
                        subtitle: "Copy diagnostic information to clipboard",
                        icon: "doc.on.doc",
                        buttonLabel: "Copy",
                        action: { copyDebugInfo(updateChannel: updateChannel) }
                    )
                    SettingsButtonRow(
                        title: "Open Logs Directory",
                        subtitle: "View application log files",
                        icon: "folder",
                        buttonLabel: "Open",
                        action: {
                            if let logDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs/AevonX") {
                                NSWorkspace.shared.open(logDir)
                            }
                        }
                    )
                    SettingsButtonRow(
                        title: "Check for Updates",
                        subtitle: updateStatusText,
                        icon: "arrow.triangle.2.circlepath",
                        buttonLabel: updateService.state == .checking ? "Checking..." : "Check Now",
                        action: { Task { await updateService.checkForUpdate() } }
                    )
                }
            }
        }
    }

    private var updateStatusText: String? {
        switch updateService.state {
        case .upToDate: return "You're up to date"
        case .updateAvailable: return "Version \(updateService.availableVersion?.version ?? "") available"
        case .downloading: return "Downloading..."
        case .downloaded: return "Ready to install"
        case .error(let msg): return msg
        default: return nil
        }
    }
}

// MARK: - Copyright Footer

private struct AboutCopyrightFooter: View {
    var body: some View {
        VStack(spacing: AXSpacing.xs) {
            // Subtle separator line
            LinearGradient(
                colors: [.clear, Color.axBorder.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, AXSpacing.xxxxl)

            Text(copyrightText)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.axTextMuted)

            Text("Made with passion for server engineers worldwide")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextMuted.opacity(0.6))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AXSpacing.lg)
        .padding(.bottom, AXSpacing.md)
    }

    private var copyrightText: String {
        let year = Calendar.current.component(.year, from: Date())
        return "© \(year) AevonX. All rights reserved."
    }
}

// MARK: - Shared Helpers

private func sectionLabel(_ title: String, icon: String) -> some View {
    HStack(spacing: AXSpacing.sm) {
        Image(systemName: icon)
            .font(.system(size: 13))
            .foregroundColor(.axAccentBlue)
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.axTextPrimary)
    }
}

private func copyDebugInfo(updateChannel: String) {
    let info = """
    AevonX Debug Information
    ========================
    App Version: \(BuildConfiguration.appVersion) (\(BuildConfiguration.buildNumber))
    Platform: \(BuildConfiguration.platform)
    macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
    Memory: \(ProcessInfo.processInfo.physicalMemory / 1_073_741_824) GB
    Locale: \(Locale.current.identifier)
    Timezone: \(TimeZone.current.identifier)
    Update Channel: \(updateChannel)
    Generated: \(ISO8601DateFormatter().string(from: Date()))
    """
    #if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(info, forType: .string)
    #endif
}
