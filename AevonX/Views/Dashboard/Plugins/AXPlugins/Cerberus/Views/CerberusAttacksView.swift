//
//  CerberusAttacksView.swift
//  AevonX
//
//  Attacks tab — threat analytics command center.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusAttacksView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var selectedAttacker: AttackerInfo?

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.isLoading && viewModel.attackTypes.isEmpty {
                    attacksSkeletonContent
                } else {
                    attackSummaryHeader
                    attackTypesSection
                    HStack(alignment: .top, spacing: AXSpacing.lg) {
                        topAttackersSection
                        topURIsSection
                    }
                    countriesSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadAttacks() }
        .sheet(item: $selectedAttacker) { attackerDetailSheet($0) }
    }

    // MARK: - Skeleton

    private var attacksSkeletonContent: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
            AXCard { AXSkeletonBlock(lines: 6) }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                AXCard { AXSkeletonBlock(lines: 5) }
                AXCard { AXSkeletonBlock(lines: 5) }
            }
        }
    }

    // MARK: - Summary Header

    private var totalAttackCount: Int { viewModel.attackTypes.reduce(0) { $0 + $1.count } }

    private var attackSummaryHeader: some View {
        HStack(spacing: AXSpacing.md) {
            summaryStatCard(
                icon: "bolt.shield.fill",
                value: viewModel.formatNumber(totalAttackCount),
                label: "Total Attacks",
                color: .axError
            )
            summaryStatCard(
                icon: "person.2.slash",
                value: "\(viewModel.topAttackers.count)",
                label: "Unique Sources",
                color: .axWarning
            )
            summaryStatCard(
                icon: "square.grid.3x3",
                value: "\(viewModel.attackTypes.count)",
                label: "Attack Vectors",
                color: .axAccentPurple
            )
            summaryStatCard(
                icon: "globe",
                value: viewModel.countries.first.map { flagEmoji(for: $0.countryCode) } ?? "—",
                label: "Top Origin",
                color: .axAccentBlue
            )
        }
    }

    private func summaryStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(color.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(AXTypography.caption)
                            .foregroundStyle(color)
                    }
                    Spacer()
                }
                Text(value)
                    .font(AXTypography.title2)
                    .foregroundStyle(Color.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
    }

    // MARK: - Attack Types

    private var attackTypesSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "waveform.badge.exclamationmark")
                        .foregroundStyle(Color.axError)
                    Text("Attack Vectors")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if !viewModel.attackTypes.isEmpty {
                        AXBadge(
                            text: "\(viewModel.attackTypes.count) types",
                            color: .axError,
                            style: .soft
                        )
                    }
                }

                if viewModel.attackTypes.isEmpty {
                    attacksEmptyState(icon: "shield.slash", text: "No attack data available")
                } else {
                    attackTypeBars
                }
            }
        }
    }

    private var attackTypeBars: some View {
        let maxCount = viewModel.attackTypes.map(\.count).max() ?? 1
        return GeometryReader { geo in
            VStack(spacing: AXSpacing.sm) {
                ForEach(Array(viewModel.attackTypes.enumerated()), id: \.element.id) { idx, item in
                    attackTypeBar(item: item, maxCount: maxCount, availableWidth: geo.size.width, rank: idx)
                }
            }
        }
        .frame(height: CGFloat(viewModel.attackTypes.count) * 44)
    }

    private func attackTypeBar(item: AttackTypeStats, maxCount: Int, availableWidth: CGFloat, rank: Int) -> some View {
        let ratio = maxCount > 0 ? Double(item.count) / Double(maxCount) : 0
        let barWidth = max((availableWidth - 180) * ratio, 4)
        let pct = totalAttackCount > 0 ? Double(item.count) / Double(totalAttackCount) * 100 : 0

        return HStack(spacing: AXSpacing.sm) {
            Text(item.type)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextSecondary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(Color.axError.opacity(0.08))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(
                        LinearGradient(
                            colors: [Color.axError.opacity(0.9), Color.axError.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: barWidth, height: 8)
            }
            .frame(maxWidth: .infinity)

            Text(String(format: "%.1f%%", pct))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 40, alignment: .trailing)

            Text(viewModel.formatNumber(item.count))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axError)
                .frame(width: 56, alignment: .trailing)
        }
    }

    // MARK: - Top Attackers

    private var topAttackersSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "person.fill.xmark")
                        .foregroundStyle(Color.axError)
                    Text("Top Attackers")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if !viewModel.topAttackers.isEmpty {
                        AXBadge(text: "\(viewModel.topAttackers.count)", color: .axError, style: .soft)
                    }
                }

                if viewModel.topAttackers.isEmpty {
                    attacksEmptyState(icon: "person.slash", text: "No attackers detected")
                } else {
                    attackersList
                }
            }
        }
    }

    private var attackersList: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(Array(viewModel.topAttackers.prefix(10).enumerated()), id: \.element.id) { idx, attacker in
                Button {
                    selectedAttacker = attacker
                } label: {
                    attackerRow(attacker, rank: idx + 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func attackerRow(_ attacker: AttackerInfo, rank: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            rankBadge(rank)

            Text(flagEmoji(for: attacker.countryCode))
                .font(AXTypography.body)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(attacker.ip)
                    .font(AXTypography.monoSm)
                    .foregroundStyle(Color.axTextPrimary)
                Text(attacker.country)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }

            Spacer()

            AXBadge(
                text: viewModel.formatNumber(attacker.attacks),
                color: .axError,
                style: .soft
            )
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurfaceHover.opacity(0.5))
        )
    }

    private func rankBadge(_ rank: Int) -> some View {
        let color: Color = rank == 1 ? .axWarning : rank == 2 ? .axTextSecondary : rank == 3 ? .axWarning : .axTextMuted
        return ZStack {
            Circle()
                .fill(color.opacity(rank <= 3 ? 0.2 : 0.08))
                .frame(width: 22, height: 22)
            Text("\(rank)")
                .font(AXTypography.monoXs)
                .foregroundStyle(color)
        }
    }

    // MARK: - Top URIs

    private var topURIsSection: some View {
        AXCard(accentColor: .axWarning) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "link.badge.plus")
                        .foregroundStyle(Color.axWarning)
                    Text("Top Targeted URIs")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if !viewModel.topURIs.isEmpty {
                        AXBadge(text: "\(viewModel.topURIs.count)", color: .axWarning, style: .soft)
                    }
                }

                if viewModel.topURIs.isEmpty {
                    attacksEmptyState(icon: "link", text: "No URI data available")
                } else {
                    urisList
                }
            }
        }
    }

    private var urisList: some View {
        let maxCount = viewModel.topURIs.map(\.count).max() ?? 1
        return VStack(spacing: AXSpacing.xxs) {
            ForEach(Array(viewModel.topURIs.prefix(10).enumerated()), id: \.element.id) { idx, uri in
                uriRow(uri: uri, maxCount: maxCount, rank: idx + 1)
            }
        }
    }

    private func uriRow(uri: URIStats, maxCount: Int, rank: Int) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            HStack(spacing: AXSpacing.sm) {
                Text("\(rank)")
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextMuted)
                    .frame(width: 16, alignment: .trailing)
                Text(uri.uri)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextPrimary)
                    .lineLimit(1)
                Spacer()
                Text(viewModel.formatNumber(uri.count))
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axWarning)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(Color.axWarning.opacity(0.08))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(Color.axWarning.opacity(0.7))
                        .frame(
                            width: geo.size.width * (maxCount > 0 ? Double(uri.count) / Double(maxCount) : 0),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurfaceHover.opacity(0.4))
        )
    }

    // MARK: - Countries

    private var countriesSection: some View {
        AXCard(accentColor: .axAccentPurple) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "map")
                        .foregroundStyle(Color.axAccentPurple)
                    Text("Top Attack Origins")
                        .font(AXTypography.headline)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    if !viewModel.countries.isEmpty {
                        AXBadge(
                            text: "\(viewModel.countries.count) countries",
                            color: .axAccentPurple,
                            style: .soft
                        )
                    }
                }

                if viewModel.countries.isEmpty {
                    attacksEmptyState(icon: "globe", text: "No country data available")
                } else {
                    countriesList
                }
            }
        }
    }

    private var countriesList: some View {
        let maxCount = viewModel.countries.first?.count ?? 1
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.xs) {
            ForEach(Array(viewModel.countries.prefix(12).enumerated()), id: \.element.id) { idx, country in
                countryRow(country: country, maxCount: maxCount, rank: idx + 1)
            }
        }
    }

    private func countryRow(country: CountryStats, maxCount: Int, rank: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text("\(rank)")
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 16, alignment: .trailing)

            Text(flagEmoji(for: country.countryCode))
                .font(AXTypography.body)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(country.countryName.isEmpty ? country.countryCode : country.countryName)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextPrimary)
                    .lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(Color.axAccentPurple.opacity(0.1))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(rank == 1 ? Color.axError : Color.axAccentPurple.opacity(0.7))
                            .frame(
                                width: geo.size.width * (maxCount > 0 ? Double(country.count) / Double(maxCount) : 0),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
            }

            Text(viewModel.formatNumber(country.count))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axError)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurfaceHover.opacity(0.4))
        )
    }

    // MARK: - Attacker Detail Sheet

    private func attackerDetailSheet(_ attacker: AttackerInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            attackerSheetHeader(attacker)
            attackerSheetDetails(attacker)
            attackerSheetActions(attacker)
            Spacer()
        }
        .padding(AXSpacing.xl)
        .frame(width: 420, height: 320)
        .background(Color.axBackground)
    }

    private func attackerSheetHeader(_ attacker: AttackerInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axError.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(flagEmoji(for: attacker.countryCode))
                    .font(AXTypography.title2)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(attacker.ip)
                    .font(AXTypography.monoMd)
                    .foregroundStyle(Color.axTextPrimary)
                Text(attacker.country)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            Spacer()
            Button { selectedAttacker = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private func attackerSheetDetails(_ attacker: AttackerInfo) -> some View {
        VStack(spacing: AXSpacing.xs) {
            sheetDetailRow(label: "Total Attacks", value: viewModel.formatNumber(attacker.attacks), color: .axError)
            sheetDetailRow(label: "Last Seen", value: attacker.lastSeen, color: .axTextPrimary)
            sheetDetailRow(label: "Country Code", value: attacker.countryCode.uppercased(), color: .axAccentBlue)
        }
    }

    private func sheetDetailRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurface.opacity(0.5))
        )
    }

    private func attackerSheetActions(_ attacker: AttackerInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            AXPrimaryButton(
                title: "Block IP",
                icon: "hand.raised.fill",
                action: {
                    Task {
                        await viewModel.blockIP(attacker.ip)
                        selectedAttacker = nil
                    }
                },
                isLoading: viewModel.ipOperationInProgress,
                style: .destructive
            )
            Spacer()
        }
    }

    // MARK: - Helpers

    private func attacksEmptyState(icon: String, text: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(AXTypography.title2)
                    .foregroundStyle(Color.axTextMuted)
                Text(text)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
            .padding(.vertical, AXSpacing.xxl)
            Spacer()
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) {
                flag.append(String(s))
            }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}
