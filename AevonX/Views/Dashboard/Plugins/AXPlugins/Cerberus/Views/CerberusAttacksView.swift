//
//  CerberusAttacksView.swift
//  AevonX
//
//  Attacks tab — threat analytics command center.
//  Summary · attack vectors · top attackers · targeted URIs · origin countries.
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
                    threatSummaryHero
                    attackVectorsSection
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
            AXCard { AXSkeletonBlock(lines: 2) }
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

    // MARK: - Threat Summary Hero

    private var threatSummaryHero: some View {
        AXGlassCard(accentColor: attackIntensityColor) {
            HStack(spacing: AXSpacing.xxl) {
                threatSummaryLeft
                Spacer()
                threatSummaryStats
            }
        }
    }

    private var threatSummaryLeft: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [attackIntensityColor.opacity(0.25), attackIntensityColor.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 26
                        )
                    )
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(attackIntensityColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: "bolt.shield.fill")
                    .font(AXTypography.title3)
                    .foregroundStyle(attackIntensityColor)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text("Threat Analytics")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text("\(viewModel.attackTypes.count) vectors detected")
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                    if totalAttackCount > 0 {
                        AXBadge(text: viewModel.formatNumber(totalAttackCount) + " total", color: attackIntensityColor, style: .soft)
                    }
                }
            }
        }
    }

    private var threatSummaryStats: some View {
        HStack(spacing: AXSpacing.xxl) {
            threatMiniStat(value: viewModel.formatNumber(totalAttackCount), label: "Attacks", color: .axError)
            threatMiniStat(value: "\(viewModel.topAttackers.count)", label: "Sources", color: .axWarning)
            threatMiniStat(value: "\(viewModel.attackTypes.count)", label: "Vectors", color: .axAccentPurple)
            threatMiniStat(value: viewModel.countries.first.map { flagEmoji(for: $0.countryCode) } ?? "—", label: "Top Origin", color: .axAccentBlue)
        }
    }

    private func threatMiniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Attack Vectors

    private var attackVectorsSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                attackVectorsHeader
                if viewModel.attackTypes.isEmpty {
                    attacksEmptyState(icon: "shield.slash", text: "No attack data available")
                } else {
                    attackTypeBars
                }
            }
        }
    }

    private var attackVectorsHeader: some View {
        HStack {
            Image(systemName: "waveform.badge.exclamationmark")
                .foregroundStyle(Color.axError)
            Text("Attack Vectors")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.attackTypes.isEmpty {
                AXBadge(text: "\(viewModel.attackTypes.count) types", color: .axError, style: .soft)
            }
        }
    }

    private var attackTypeBars: some View {
        let maxCount = viewModel.attackTypes.map(\.count).max() ?? 1
        return VStack(spacing: AXSpacing.xs) {
            ForEach(Array(viewModel.attackTypes.enumerated()), id: \.element.id) { idx, item in
                attackTypeBarRow(item: item, maxCount: maxCount, rank: idx + 1)
            }
        }
    }

    private func attackTypeBarRow(item: AttackTypeStats, maxCount: Int, rank: Int) -> some View {
        let ratio = maxCount > 0 ? Double(item.count) / Double(maxCount) : 0
        let pct = totalAttackCount > 0 ? Double(item.count) / Double(totalAttackCount) * 100 : 0
        let barColor: Color = rank <= 2 ? .axError : rank <= 4 ? .axWarning : .axAccentPurple

        return HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(barColor.opacity(0.12))
                    .frame(width: 24, height: 24)
                Text("\(rank)")
                    .font(AXTypography.monoXs)
                    .foregroundStyle(barColor)
            }

            Text(item.type)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextSecondary)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(barColor.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.9), barColor.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * ratio, 4), height: 8)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f%%", pct))
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 42, alignment: .trailing)

            Text(viewModel.formatNumber(item.count))
                .font(AXTypography.monoXs)
                .fontWeight(.semibold)
                .foregroundStyle(barColor)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, AXSpacing.xxs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(barColor.opacity(rank <= 2 ? 0.03 : 0.0))
        )
    }

    // MARK: - Top Attackers

    private var topAttackersSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                topAttackersHeader
                if viewModel.topAttackers.isEmpty {
                    attacksEmptyState(icon: "person.slash", text: "No attackers detected")
                } else {
                    attackersList
                }
            }
        }
    }

    private var topAttackersHeader: some View {
        HStack {
            Image(systemName: "person.fill.xmark")
                .foregroundStyle(Color.axError)
            Text("Top Attackers")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.topAttackers.isEmpty {
                AXBadge(text: "\(viewModel.topAttackers.count) IPs", color: .axError, style: .soft)
            }
        }
    }

    private var attackersList: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(Array(viewModel.topAttackers.prefix(10).enumerated()), id: \.element.id) { idx, attacker in
                Button { selectedAttacker = attacker } label: {
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
            VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
                AXBadge(text: viewModel.formatNumber(attacker.attacks), color: .axError, style: .soft)
                Text(attacker.lastSeen.suffix(8).description)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextMuted)
            }
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurfaceHover.opacity(0.5))
        )
    }

    private func rankBadge(_ rank: Int) -> some View {
        let color: Color = rank == 1 ? .axError : rank == 2 ? .axWarning : rank == 3 ? .axAccentPurple : .axTextMuted
        return ZStack {
            Circle()
                .fill(color.opacity(rank <= 3 ? 0.2 : 0.08))
                .frame(width: 22, height: 22)
            Text("\(rank)")
                .font(AXTypography.monoXs)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .foregroundStyle(color)
        }
    }

    // MARK: - Top URIs

    private var topURIsSection: some View {
        AXCard(accentColor: .axWarning) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                topURIsHeader
                if viewModel.topURIs.isEmpty {
                    attacksEmptyState(icon: "link", text: "No URI data available")
                } else {
                    urisList
                }
            }
        }
    }

    private var topURIsHeader: some View {
        HStack {
            Image(systemName: "link.badge.plus")
                .foregroundStyle(Color.axWarning)
            Text("Top Targeted URIs")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.topURIs.isEmpty {
                AXBadge(text: "\(viewModel.topURIs.count) paths", color: .axWarning, style: .soft)
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
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axWarning.opacity(0.1))
                        .frame(width: 20, height: 20)
                    Text("\(rank)")
                        .font(AXTypography.monoXs)
                        .foregroundStyle(Color.axWarning)
                }
                Text(uri.uri)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextPrimary)
                    .lineLimit(1)
                Spacer()
                Text(viewModel.formatNumber(uri.count))
                    .font(AXTypography.monoXs)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axWarning)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(Color.axWarning.opacity(0.06))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: [Color.axWarning.opacity(0.8), Color.axWarning.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                countriesHeader
                if viewModel.countries.isEmpty {
                    attacksEmptyState(icon: "globe", text: "No country data available")
                } else {
                    countriesList
                }
            }
        }
    }

    private var countriesHeader: some View {
        HStack {
            Image(systemName: "map.fill")
                .foregroundStyle(Color.axAccentPurple)
            Text("Attack Origins")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.countries.isEmpty {
                AXBadge(text: "\(viewModel.countries.count) countries", color: .axAccentPurple, style: .soft)
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
        let barColor: Color = rank == 1 ? .axError : .axAccentPurple
        return HStack(spacing: AXSpacing.sm) {
            ZStack {
                Circle()
                    .fill(barColor.opacity(rank <= 3 ? 0.15 : 0.06))
                    .frame(width: 20, height: 20)
                Text("\(rank)")
                    .font(AXTypography.monoXs)
                    .foregroundStyle(barColor)
            }
            Text(flagEmoji(for: country.countryCode))
                .font(AXTypography.body)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack {
                    Text(country.countryName.isEmpty ? country.countryCode : country.countryName)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.formatNumber(country.count))
                        .font(AXTypography.monoXs)
                        .fontWeight(.semibold)
                        .foregroundStyle(barColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(barColor.opacity(0.08))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .fill(barColor.opacity(0.7))
                            .frame(
                                width: geo.size.width * (maxCount > 0 ? Double(country.count) / Double(maxCount) : 0),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
            }
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
        .frame(width: 440, height: 340)
        .background(Color.axBackground)
    }

    private func attackerSheetHeader(_ attacker: AttackerInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axError.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(flagEmoji(for: attacker.countryCode))
                    .font(AXTypography.title2)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(attacker.ip)
                    .font(AXTypography.monoMd)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text(attacker.country)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                    AXBadge(text: viewModel.formatNumber(attacker.attacks) + " attacks", color: .axError, style: .soft)
                }
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
            sheetDetailRow(label: "IP Address", value: attacker.ip, color: .axTextPrimary)
            sheetDetailRow(label: "Total Attacks", value: viewModel.formatNumber(attacker.attacks), color: .axError)
            sheetDetailRow(label: "Last Seen", value: attacker.lastSeen, color: .axTextPrimary)
            sheetDetailRow(label: "Country", value: "\(flagEmoji(for: attacker.countryCode)) \(attacker.country)", color: .axAccentBlue)
            sheetDetailRow(label: "Country Code", value: attacker.countryCode.uppercased(), color: .axAccentPurple)
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

    private var totalAttackCount: Int { viewModel.attackTypes.reduce(0) { $0 + $1.count } }

    private var attackIntensityColor: Color {
        if totalAttackCount > 10_000 { return .axError }
        if totalAttackCount > 1_000 { return .axWarning }
        if totalAttackCount > 0 { return .axAccentBlue }
        return .axAccentGreen
    }

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
