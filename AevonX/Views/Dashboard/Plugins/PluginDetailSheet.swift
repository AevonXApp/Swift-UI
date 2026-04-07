//
//  PluginDetailSheet.swift
//  AevonX
//
//  Premium plugin detail view with developer info, versions, rating, and docs
//

import SwiftUI
import AevonXCoreBridge

struct PluginDetailSheet: View {
    let plugin: Plugin
    let serverId: String?
    var serverIP: String = ""
    let isInstalled: Bool
    var installSource: InstallSource? = nil
    var updateInfo: PluginUpdateInfo?
    @ObservedObject var viewModel: PluginsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showAllVersions = false

    private var installedVersionNumber: String? {
        guard isInstalled else { return nil }
        // Prefer the actual installed version from update check (server-side config.avx)
        return updateInfo?.installedVersion ?? plugin.activeVersion?.versionNumber
    }

    private var ratingValue: Double {
        Double(plugin.rating ?? "0") ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().background(Color.axBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xxl) {
                    heroSection
                    statsRow
                    actionBar
                    aboutSection

                    if let version = plugin.activeVersion, let changelog = version.changelog, !changelog.isEmpty {
                        whatsNewSection(changelog)
                    }

                    versionsSection
                    developerSection
                }
                .padding(AXSpacing.xxl)
            }
        }
        .frame(width: 620, height: 680)
        .background(Color.axBackground)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(alignment: .top, spacing: AXSpacing.xl) {
            pluginIconLarge
            heroInfo
        }
    }

    private var pluginIconLarge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [Color.axAccentBlue.opacity(0.12), Color.axAccentGreen.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            if let imageUrl = plugin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.axAccentBlue.opacity(0.4))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(AXCornerRadius.xl)
                .clipped()
            } else {
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.axAccentBlue.opacity(0.4))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var heroInfo: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            // Name + badges
            HStack(spacing: AXSpacing.sm) {
                Text(plugin.name)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                if plugin.isOfficial {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.axAccentBlue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .help(L10n.Plugin.official)
                }

                Spacer()

                pricingBadgeLarge
            }

            // Developer
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 12))
                Text(plugin.user?.name ?? L10n.Plugin.community)
                    .font(AXTypography.body)
                    .fontWeight(.medium)

                if plugin.user?.isVerifiedDeveloper == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.axAccentGreen, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .foregroundColor(.axAccentBlue)

            // Version + Category
            HStack(spacing: AXSpacing.md) {
                if let version = plugin.activeVersion {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text("v\(version.versionNumber)")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axTextSecondary)
                }

                if let cat = plugin.category {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: sfSymbolForDetail(cat.icon ?? "folder"))
                            .font(.system(size: 10))
                        Text(cat.name)
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.axTextSecondary)
                }

                if isInstalled {
                    HStack(spacing: AXSpacing.xxs) {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 6, height: 6)
                        Text(L10n.Plugin.installed)
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axSuccess)
                }
            }

            // Star rating
            if ratingValue > 0 {
                HStack(spacing: AXSpacing.xs) {
                    StarRatingView(rating: ratingValue, size: 13)
                    Text(String(format: "%.1f", ratingValue))
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                }
            } else {
                HStack(spacing: AXSpacing.xs) {
                    StarRatingView(rating: 0, size: 13)
                    Text(L10n.Plugin.Detail.newPlugin)
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextMuted)
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(icon: "arrow.down.circle.fill", value: formatCount(plugin.downloadsCount), label: L10n.Plugin.downloads, color: .axSuccess)

            Divider().frame(height: 32)

            statCell(
                icon: "star.fill",
                value: ratingValue > 0 ? String(format: "%.1f", ratingValue) : L10n.Plugin.Detail.newPlugin,
                label: L10n.Plugin.rating,
                color: ratingValue > 0 ? .yellow : .axTextMuted
            )
            Divider().frame(height: 32)

            if let cat = plugin.category {
                statCell(icon: sfSymbolForDetail(cat.icon ?? "folder"), value: cat.name, label: L10n.Plugin.Detail.category, color: .axAccentPurple)
                Divider().frame(height: 32)
            }

            if let limit = plugin.pricing?.serverLimit {
                statCell(icon: "server.rack", value: "\(limit)", label: L10n.Plugin.Detail.servers, color: .axAccentBlue)
            } else if let version = plugin.activeVersion {
                statCell(icon: "tag", value: "v\(version.versionNumber)", label: L10n.Plugin.version, color: .axTextSecondary)
            }
        }
        .padding(.vertical, AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        )
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: AXSpacing.md) {
            if isInstalled {
                installedActions
            } else {
                notInstalledActions
            }
        }
    }

    private var installedActions: some View {
        HStack(spacing: AXSpacing.md) {
            if let update = updateInfo {
                Button(action: {
                    if let sid = serverId {
                        Task { await viewModel.updatePlugin(plugin, on: sid) }
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 13))
                        Text("\(L10n.Plugin.Update.update) v\(update.latestVersion)")
                            .font(AXTypography.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm + 2)
                    .background(
                        LinearGradient(
                            colors: [.axAccentBlue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .shadow(color: .axAccentBlue.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button(action: {
                dismiss()
                // Small delay so the sheet dismisses before opening config
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // onSettings will be called via the parent's callback
                }
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                    Text(L10n.Plugin.configure)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.axTextPrimary)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm + 2)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                if let sid = serverId {
                    Task { await viewModel.uninstallPlugin(plugin, on: sid) }
                    dismiss()
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.axError)
                    .padding(AXSpacing.sm + 2)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help(L10n.Plugin.uninstall)
        }
    }

    @ViewBuilder
    private var notInstalledActions: some View {
        // No client-side pricing gates — backend decides authorization.
        Button(action: {
            if let sid = serverId {
                Task { await viewModel.installPlugin(plugin, on: sid, serverIP: serverIP) }
                dismiss()
            }
        }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 13))
                Text(L10n.Plugin.install)
                    .font(AXTypography.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.sm + 2)
            .background(
                LinearGradient(colors: [.axSuccess, .axSuccess.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(AXCornerRadius.md)
            .shadow(color: .axSuccess.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(PlainButtonStyle())

        Spacer()
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionHeader(L10n.Plugin.Detail.about, icon: "doc.text")

            if plugin.description.isEmpty {
                Text(L10n.Plugin.Detail.noDescription)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            } else {
                markdownDescription
            }
        }
    }

    @ViewBuilder
    private var markdownDescription: some View {
        let lines = plugin.description.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.hasPrefix("## ") {
                    Text(line.dropFirst(3))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.axTextPrimary.opacity(0.85))
                        .padding(.top, AXSpacing.sm)
                } else if line.hasPrefix("- **") {
                    let parsed = parseListItem(String(line.dropFirst(2)))
                    HStack(alignment: .top, spacing: AXSpacing.sm) {
                        Circle()
                            .fill(Color.axAccentBlue)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(parsed)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                    }
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(parseBold(line))
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func parseListItem(_ text: String) -> AttributedString {
        parseBold(text)
    }

    private func parseBold(_ text: String) -> AttributedString {
        var result = AttributedString()
        let pattern = /\*\*(.+?)\*\*/
        var remaining = text[...]
        while let match = remaining.firstMatch(of: pattern) {
            let before = String(remaining[remaining.startIndex..<match.range.lowerBound])
            if !before.isEmpty { result.append(AttributedString(before)) }
            var bold = AttributedString(String(match.1))
            bold.font = .system(size: 13, weight: .semibold)
            bold.foregroundColor = .white.opacity(0.6)
            result.append(bold)
            remaining = remaining[match.range.upperBound...]
        }
        if !remaining.isEmpty { result.append(AttributedString(String(remaining))) }
        return result
    }

    // MARK: - What's New

    private func whatsNewSection(_ changelog: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionHeader(L10n.Plugin.Detail.whatsNew, icon: "sparkles")

            AXCard(padding: AXSpacing.md) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    if let version = plugin.activeVersion {
                        HStack(spacing: AXSpacing.xs) {
                            Text("v\(version.versionNumber)")
                                .font(AXTypography.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.axAccentBlue)

                            BadgePill(text: L10n.Plugin.Detail.latest, color: .axSuccess)
                        }
                    }

                    Text(changelog)
                        .font(AXTypography.callout)
                        .foregroundColor(.axTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Versions

    private var versionsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionHeader(L10n.Plugin.Detail.versions, icon: "clock.arrow.circlepath")

            if let versions = plugin.versions, !versions.isEmpty {
                let displayed = showAllVersions ? versions : Array(versions.prefix(3))

                VStack(spacing: AXSpacing.sm) {
                    ForEach(displayed) { version in
                        versionRow(version)
                    }
                }

                if versions.count > 3 && !showAllVersions {
                    Button(action: { withAnimation(.spring(response: 0.3)) { showAllVersions = true } }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 12))
                            Text(L10n.Plugin.Detail.showAllVersions)
                                .font(AXTypography.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.top, AXSpacing.xs)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                Text(L10n.Plugin.Detail.noVersions)
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextMuted)
                    .italic()
            }
        }
    }

    private func isVersionCurrentlyInstalled(_ version: PluginVersion) -> Bool {
        isInstalled && installedVersionNumber == version.versionNumber
    }

    private func isVersionNewer(_ version: PluginVersion) -> Bool {
        guard let iv = installedVersionNumber else { return false }
        return version.versionNumber.compare(iv, options: .numeric) == .orderedDescending
    }

    private func isVersionOlder(_ version: PluginVersion) -> Bool {
        guard let iv = installedVersionNumber else { return false }
        return version.versionNumber.compare(iv, options: .numeric) == .orderedAscending
    }

    @ViewBuilder
    private func versionRow(_ version: PluginVersion) -> some View {
        let isCurrent = isVersionCurrentlyInstalled(version)
        let isNewer = isVersionNewer(version)
        let isOlder = isVersionOlder(version)

        HStack(spacing: AXSpacing.md) {
            // Version indicator line
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrent ? Color.axAccentGreen : (version.isActive ? Color.axAccentBlue : Color.axBorder))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.axBorder)
                    .frame(width: 1)
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text("v\(version.versionNumber)")
                        .font(AXTypography.body)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    if version.isActive {
                        BadgePill(text: L10n.Plugin.Detail.latest, color: .axSuccess)
                    }

                    if isCurrent {
                        BadgePill(text: L10n.Plugin.Detail.current, color: .axAccentGreen)
                    }
                }

                if let changelog = version.changelog, !changelog.isEmpty {
                    Text(changelog)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Action button
            if let sid = serverId {
                Button(action: {
                    Task { await viewModel.installPlugin(plugin, version: version, on: sid, serverIP: serverIP) }
                    dismiss()
                }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: versionActionIcon(isCurrent: isCurrent, isNewer: isNewer, isOlder: isOlder))
                            .font(.system(size: 11))
                        Text(versionActionLabel(isCurrent: isCurrent, isNewer: isNewer, isOlder: isOlder))
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(versionActionColor(isCurrent: isCurrent, isNewer: isNewer, isOlder: isOlder))
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs + 2)
                    .background(versionActionColor(isCurrent: isCurrent, isNewer: isNewer, isOlder: isOlder).opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(versionActionColor(isCurrent: isCurrent, isNewer: isNewer, isOlder: isOlder).opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isCurrent ? Color.axAccentGreen.opacity(0.04) : Color.axSurface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(isCurrent ? Color.axAccentGreen.opacity(0.2) : Color.axBorder.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private func versionActionLabel(isCurrent: Bool, isNewer: Bool, isOlder: Bool) -> String {
        if isCurrent { return L10n.Plugin.reinstall }
        if isNewer { return L10n.Plugin.Update.update }
        if isOlder { return L10n.Plugin.install }
        return L10n.Plugin.install
    }

    private func versionActionIcon(isCurrent: Bool, isNewer: Bool, isOlder: Bool) -> String {
        if isCurrent { return "arrow.clockwise.circle" }
        if isNewer { return "arrow.up.circle.fill" }
        if isOlder { return "arrow.down.circle" }
        return "arrow.down.circle"
    }

    private func versionActionColor(isCurrent: Bool, isNewer: Bool, isOlder: Bool) -> Color {
        if isCurrent { return .axTextMuted }
        if isNewer { return .axAccentBlue }
        if isOlder { return .axWarning }
        return .axAccentBlue
    }

    // MARK: - Developer

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionHeader(L10n.Plugin.Detail.developer, icon: "person.crop.rectangle")

            AXCard(padding: AXSpacing.md) {
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.axAccentBlue.opacity(0.2), .axAccentGreen.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Text(String((plugin.user?.name ?? "C").prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.axAccentBlue)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        HStack(spacing: AXSpacing.xs) {
                            Text(plugin.user?.name ?? L10n.Plugin.community)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            if plugin.user?.isVerifiedDeveloper == true {
                                HStack(spacing: AXSpacing.xxxs) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.axAccentGreen, .mint],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text(L10n.Plugin.Detail.verifiedDeveloper)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.axAccentGreen)
                                }
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxxs)
                                .background(Color.axAccentGreen.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }

                        if plugin.isOfficial {
                            Text(L10n.Plugin.official)
                                .font(AXTypography.caption)
                                .foregroundColor(.axAccentBlue)
                        }
                    }

                    Spacer()

                    // Links
                    developerLinks
                }
            }
        }
    }

    private var developerLinks: some View {
        HStack(spacing: AXSpacing.sm) {
            if let repoUrl = plugin.activeVersion?.repositoryUrl, let url = URL(string: repoUrl) {
                linkButton(icon: "chevron.left.forwardslash.chevron.right", label: L10n.Plugin.github, url: url)
            }
        }
    }

    private func linkButton(icon: String, label: String, url: URL) -> some View {
        Button(action: {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.axAccentBlue)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axAccentBlue.opacity(0.08))
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axAccentBlue)
            Text(title)
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)
        }
    }

    @ViewBuilder
    private var pricingBadgeLarge: some View {
        if let pricing = plugin.pricing {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: pricingIcon(pricing))
                    .font(.system(size: 11, weight: .bold))
                Text(pricing.displayLabel)
                    .font(.system(size: 11, weight: .black))
                    .textCase(.uppercase)
            }
            .foregroundColor(pricingColor(pricing))
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(pricingColor(pricing).opacity(0.12))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(pricingColor(pricing).opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func pricingIcon(_ pricing: PluginPricing) -> String {
        switch pricing.type {
        case .free: return "gift.fill"
        case .paid: return "dollarsign.circle.fill"
        case .subscribers: return "crown.fill"
        }
    }

    private func pricingColor(_ pricing: PluginPricing) -> Color {
        switch pricing.type {
        case .free: return .axSuccess
        case .paid: return .axAccentBlue
        case .subscribers: return .axWarning
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }

}

// MARK: - Star Rating View

struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .font(.system(size: size))
                    .foregroundColor(.yellow)
            }
        }
    }

    private func starType(for index: Int) -> String {
        let value = Double(index) + 1
        if rating >= value { return "star.fill" }
        if rating >= value - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Badge Pill

private struct BadgePill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.xs + 2)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(AXCornerRadius.xs + 2)
    }
}

// MARK: - SF Symbol Mapper (detail-local)

private func sfSymbolForDetail(_ lucideIcon: String) -> String {
    switch lucideIcon {
    case "shield-check": return "checkmark.shield"
    case "activity": return "waveform.path.ecg"
    case "rocket": return "paperplane.fill"
    case "database": return "cylinder"
    case "code": return "chevron.left.forwardslash.chevron.right"
    case "zap": return "bolt.fill"
    case "monitor": return "desktopcomputer"
    case "gauge": return "speedometer"
    case "wrench": return "wrench"
    case "server": return "server.rack"
    case "lock": return "lock"
    case "globe": return "globe"
    case "terminal": return "terminal"
    case "cpu": return "cpu"
    case "layers": return "square.3.layers.3d"
    case "box": return "shippingbox"
    default: return lucideIcon
    }
}
