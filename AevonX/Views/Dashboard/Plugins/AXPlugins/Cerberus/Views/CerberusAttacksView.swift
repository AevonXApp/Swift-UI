//
//  CerberusAttacksView.swift
//  AevonX
//
//  Attacks tab — threat analytics, block log with filters, attack vectors,
//  top attackers, targeted URIs, origin countries.
//

import SwiftUI
import Charts
import AevonXCoreBridge

struct CerberusAttacksView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @State private var selectedAttacker: AttackerInfo?
    @State private var blockLogFilter = ""
    @State private var selectedSection: AttackSection = .overview
    @State private var barsAppeared = false
    @State private var blockLogPage = 0
    @State private var selectedDomain: String?
    private let blockLogPageSize = 50

    enum AttackSection: String, CaseIterable {
        case overview = "Overview"
        case blockLog = "Block Log"

        var label: String {
            switch self {
            case .overview: return L10n.Cerberus.Attacks.overview
            case .blockLog: return L10n.Cerberus.Attacks.blockLog
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            Divider().background(Color.axDivider)
            ScrollView {
                VStack(spacing: AXSpacing.lg) {
                    if viewModel.attacksLoading && viewModel.attackTypes.isEmpty {
                        attacksSkeletonContent
                    } else if selectedSection == .overview {
                        overviewContent
                    } else {
                        blockLogContent
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .task {
            async let atk:  () = viewModel.loadAttacks()
            async let blog: () = viewModel.loadBlockLog()
            _ = await (atk, blog)
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                barsAppeared = true
            }
        }
        .sheet(item: $selectedAttacker) { attackerDetailSheet($0) }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: AXSpacing.xxs) {
            ForEach(AttackSection.allCases, id: \.self) { section in
                sectionTab(section)
            }
            Spacer()
            if selectedSection == .blockLog && !viewModel.blockLog.isEmpty {
                AXBadge(text: L10n.Cerberus.Badge.entries(filteredBlockLog.count), color: .axError, style: .soft)
            }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func sectionTab(_ section: AttackSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSection = section }
        } label: {
            Text(section.label)
                .font(AXTypography.subheadline)
                .fontWeight(selectedSection == section ? .semibold : .regular)
                .foregroundStyle(selectedSection == section ? Color.axAccentBlue : Color.axTextSecondary)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(selectedSection == section ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                )
                .overlay(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.axAccentBlue)
                            .frame(height: 2)
                            .opacity(selectedSection == section ? 1 : 0)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Skeleton

    private var attacksSkeletonContent: some View {
        VStack(spacing: AXSpacing.lg) {
            AXCard { AXSkeletonBlock(lines: 2) }
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
            AXCard { AXSkeletonBlock(lines: 6) }
        }
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        VStack(spacing: AXSpacing.lg) {
            threatSummaryHero
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                attackVectorsSection
                attackVectorChart
            }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                topAttackersSection
                topURIsSection
            }
            countriesSection
        }
    }

    // MARK: - Threat Summary Hero

    private var threatSummaryHero: some View {
        AXGlassCard(accentColor: attackIntensityColor) {
            HStack(spacing: AXSpacing.xxl) {
                threatHeroLeft
                Spacer()
                threatSummaryStats
            }
        }
    }

    private var threatHeroLeft: some View {
        HStack(spacing: AXSpacing.md) {
            threatHeroIcon
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Cerberus.Attacks.threatAnalytics)
                    .font(AXTypography.title2).fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                threatHeroSubtitle
            }
        }
    }

    private var threatHeroIcon: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [attackIntensityColor.opacity(0.25), attackIntensityColor.opacity(0.05)],
                    center: .center, startRadius: 0, endRadius: 26))
                .frame(width: 48, height: 48)
            Circle()
                .fill(LinearGradient(
                    colors: [attackIntensityColor.opacity(0.15), Color.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
            Circle()
                .stroke(attackIntensityColor.opacity(0.3), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: "bolt.shield.fill")
                .font(AXTypography.title3)
                .foregroundStyle(attackIntensityColor)
                .shadow(color: attackIntensityColor.opacity(0.4), radius: 4, y: 2)
        }
    }

    private var threatHeroSubtitle: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.Cerberus.Attacks.vectorsDetected(viewModel.attackTypes.count))
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
            if totalAttackCount > 0 {
                AXBadge(
                    text: viewModel.formatNumber(totalAttackCount) + " total",
                    color: attackIntensityColor, style: .soft)
            }
        }
    }

    private var threatSummaryStats: some View {
        HStack(spacing: AXSpacing.xxl) {
            threatMiniStat(value: viewModel.formatNumber(totalAttackCount), label: L10n.Cerberus.Attacks.attacks, color: .axError)
            threatMiniStat(value: "\(viewModel.topAttackers.count)", label: L10n.Cerberus.Attacks.sources, color: .axWarning)
            threatMiniStat(value: "\(viewModel.attackTypes.count)", label: L10n.Cerberus.Attacks.vectors, color: .axAccentBlue)
            threatMiniStat(value: "\(viewModel.blockLog.count)", label: L10n.Cerberus.Attacks.blocks, color: .axAccentBlue)
        }
    }

    private func threatMiniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Text(value).font(AXTypography.title3).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Attack Vectors

    private var attackVectorsSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                attackVectorsHeader
                if viewModel.attackTypes.isEmpty {
                    emptyState(icon: "shield.slash", text: L10n.Cerberus.Attacks.noAttackData)
                } else {
                    attackTypeBars
                }
            }
        }
    }

    private var attackVectorsHeader: some View {
        HStack {
            Image(systemName: "waveform.badge.exclamationmark").foregroundStyle(Color.axError)
            Text(L10n.Cerberus.Attacks.attackVectors).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.attackTypes.isEmpty {
                AXBadge(text: L10n.Cerberus.Badge.types(viewModel.attackTypes.count), color: .axError, style: .soft)
            }
        }
    }

    private var attackTypeBars: some View {
        let maxCount = viewModel.attackTypes.map(\.count).max() ?? 1
        return VStack(spacing: AXSpacing.xs) {
            ForEach(Array(viewModel.attackTypes.prefix(10).enumerated()), id: \.element.id) { idx, item in
                attackTypeBarRow(item: item, maxCount: maxCount, rank: idx + 1)
            }
        }
    }

    private func attackTypeBarRow(item: AttackTypeStats, maxCount: Int, rank: Int) -> some View {
        let ratio = maxCount > 0 ? Double(item.count) / Double(maxCount) : 0
        let pct = totalAttackCount > 0 ? Double(item.count) / Double(totalAttackCount) * 100 : 0
        let barColor: Color = rank <= 2 ? .axError : rank <= 4 ? .axWarning : .axAccentBlue
        let isTop3 = rank <= 3
        return HStack(spacing: AXSpacing.sm) {
            rankBadge(rank, color: barColor)
            Text(item.type).font(AXTypography.monoXs).foregroundStyle(Color.axTextSecondary)
                .frame(width: 130, alignment: .leading).lineLimit(1)
            attackBarGeometry(ratio: ratio, barColor: barColor, isTop3: isTop3)
            Text(String(format: "%.1f%%", pct)).font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted).frame(width: 42, alignment: .trailing)
            Text(viewModel.formatNumber(item.count)).font(AXTypography.monoXs)
                .fontWeight(.semibold).foregroundStyle(barColor).frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, AXSpacing.xxs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(barColor.opacity(rank <= 2 ? 0.03 : 0)))
    }

    private func attackBarGeometry(ratio: Double, barColor: Color, isTop3: Bool) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(barColor.opacity(0.08)).frame(height: 8)
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(LinearGradient(
                        colors: [barColor.opacity(0.9), barColor.opacity(0.4)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(geo.size.width * (barsAppeared ? ratio : 0), 4), height: 8)
                    .shadow(color: isTop3 ? barColor.opacity(0.35) : .clear, radius: 4, y: 1)
                    .animation(.easeOut(duration: 0.7), value: barsAppeared)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Attack Vector Chart

    private var attackVectorChart: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "chart.pie.fill").foregroundStyle(Color.axError)
                    Text(L10n.Cerberus.Attacks.distribution).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                    Spacer()
                }
                if viewModel.attackTypes.isEmpty {
                    emptyState(icon: "chart.pie", text: L10n.Cerberus.Attacks.noDistData)
                } else {
                    attackPieChart
                }
            }
        }
    }

    private var attackPieChart: some View {
        let top5 = Array(viewModel.attackTypes.prefix(5))
        let colors: [Color] = [.axError, .axWarning, .axAccentBlue, .axAccentGreen, Color(red: 1.0, green: 0.55, blue: 0.1)]
        return VStack(spacing: AXSpacing.md) {
            Chart(top5) { item in
                SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.5), angularInset: 1.5)
                    .foregroundStyle(colors[min(top5.firstIndex(where: { $0.id == item.id }) ?? 0, colors.count - 1)])
                    .cornerRadius(AXCornerRadius.xs)
            }
            .frame(height: 180)
            chartLegend(top5: top5, colors: colors)
        }
    }

    private func chartLegend(top5: [AttackTypeStats], colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            ForEach(Array(top5.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: AXSpacing.sm) {
                    Circle().fill(colors[min(idx, colors.count - 1)]).frame(width: 8, height: 8)
                    Text(item.type).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary).lineLimit(1)
                    Spacer()
                    Text(viewModel.formatNumber(item.count)).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary)
                }
            }
        }
    }

    // MARK: - Top Attackers

    private var topAttackersSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                topAttackersHeader
                if viewModel.topAttackers.isEmpty {
                    emptyState(icon: "person.slash", text: L10n.Cerberus.Attacks.noAttackers)
                } else {
                    attackersList
                }
            }
        }
    }

    private var topAttackersHeader: some View {
        HStack {
            Image(systemName: "person.fill.xmark").foregroundStyle(Color.axError)
            Text(L10n.Cerberus.Attacks.topAttackers).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.topAttackers.isEmpty {
                AXBadge(text: L10n.Cerberus.Badge.ips(viewModel.topAttackers.count), color: .axError, style: .soft)
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
        let rankColor: Color = rank == 1 ? .axError : rank == 2 ? .axWarning : rank == 3 ? .axWarning : .axTextMuted
        return HStack(spacing: AXSpacing.sm) {
            rankBadge(rank, color: rankColor)
            Text(countryFlagEmoji( attacker.countryCode)).font(AXTypography.body)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(attacker.ip) : attacker.ip).font(AXTypography.monoSm).foregroundStyle(Color.axTextPrimary)
                Text(attacker.country).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }
            Spacer()
            threatLevelIndicator(attacks: attacker.attacks)
            VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
                AXBadge(text: viewModel.formatNumber(attacker.attacks), color: .axError, style: .soft)
                Text(attacker.lastSeen.suffix(8).description).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted)
            }
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(rank % 2 == 0 ? Color.axSurfaceHover.opacity(0.35) : Color.axSurfaceHover.opacity(0.55))
        )
    }

    private func threatLevelIndicator(attacks: Int) -> some View {
        let level = attacks >= 1000 ? 3 : attacks >= 100 ? 2 : 1
        let color: Color = level == 3 ? .axError : level == 2 ? .axWarning : .axAccentBlue
        return HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(bar < level ? color : Color.axTextMuted.opacity(0.2))
                    .frame(width: 3, height: CGFloat(6 + bar * 3))
            }
        }
        .frame(height: 14, alignment: .bottom)
    }

    // MARK: - Top URIs

    private var topURIsSection: some View {
        AXCard(accentColor: .axWarning) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                topURIsHeader
                if viewModel.topURIs.isEmpty {
                    emptyState(icon: "link", text: L10n.Cerberus.Attacks.noURIData)
                } else {
                    urisList
                }
            }
        }
    }

    private var topURIsHeader: some View {
        HStack {
            Image(systemName: "link.badge.plus").foregroundStyle(Color.axWarning)
            Text(L10n.Cerberus.Attacks.targetedURIs).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.topURIs.isEmpty {
                AXBadge(text: L10n.Cerberus.Badge.paths(viewModel.topURIs.count), color: .axWarning, style: .soft)
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
                rankBadge(rank, color: .axWarning)
                Text(uri.uri).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary).lineLimit(1)
                Spacer()
                Text(viewModel.formatNumber(uri.count)).font(AXTypography.monoXs)
                    .fontWeight(.semibold).foregroundStyle(Color.axWarning)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(Color.axWarning.opacity(0.06)).frame(height: 3)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(LinearGradient(
                            colors: [Color.axWarning.opacity(0.8), Color.axWarning.opacity(0.3)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * (maxCount > 0 ? Double(uri.count) / Double(maxCount) : 0), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.4)))
    }

    // MARK: - Countries

    private var countriesSection: some View {
        AXCard(accentColor: .axWarning) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                countriesHeader
                if viewModel.countries.isEmpty {
                    emptyState(icon: "globe", text: L10n.Cerberus.Attacks.noCountryData)
                } else {
                    countriesGrid
                }
            }
        }
    }

    private var countriesHeader: some View {
        HStack {
            Image(systemName: "map.fill").foregroundStyle(Color.axWarning)
            Text(L10n.Cerberus.Attacks.attackOrigins).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !viewModel.countries.isEmpty {
                AXBadge(text: L10n.Cerberus.Badge.countries(viewModel.countries.count), color: .axWarning, style: .soft)
            }
        }
    }

    private var countriesGrid: some View {
        let top12 = Array(viewModel.countries.prefix(12))
        let maxCount = viewModel.countries.first?.count ?? 1
        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            ContinentLegendView(countryCodes: top12.map(\.countryCode))
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: AXSpacing.xs
            ) {
                ForEach(Array(top12.enumerated()), id: \.element.id) { idx, country in
                    countryCell(country: country, maxCount: maxCount, rank: idx + 1)
                }
            }
        }
    }

    private func countryCell(country: CountryStats, maxCount: Int, rank: Int) -> some View {
        let barColor = WAFContinent.from(countryCode: country.countryCode).color
        return HStack(spacing: AXSpacing.sm) {
            Text(countryFlagEmoji( country.countryCode)).font(AXTypography.title3)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(localizedCountryName(country))
                    .font(AXTypography.caption).foregroundStyle(Color.axTextPrimary).lineLimit(1)
                countryCellBar(country: country, maxCount: maxCount, barColor: barColor)
            }
        }
        .padding(AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.4), lineWidth: 0.5)
        )
    }

    private func countryCellBar(country: CountryStats, maxCount: Int, barColor: Color) -> some View {
        HStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(barColor.opacity(0.08)).frame(height: 3)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(barColor.opacity(0.7))
                        .frame(width: geo.size.width * (maxCount > 0 ? Double(country.count) / Double(maxCount) : 0), height: 3)
                }
            }
            .frame(height: 3)
            Text(viewModel.formatNumber(country.count)).font(AXTypography.monoXs).foregroundStyle(barColor)
        }
    }

    // MARK: - Block Log Content

    private var blockLogContent: some View {
        VStack(spacing: AXSpacing.md) {
            blockLogFilterBar
            blockLogStatsRow
            blockLogTable
        }
    }

    private var blockLogFilterBar: some View {
        HStack(spacing: AXSpacing.md) {
            blockLogDomainPicker
            AXTextField(placeholder: L10n.Cerberus.Attacks.filterPlaceholder, text: $blockLogFilter, icon: "magnifyingglass")
            blockLogRefreshButton
        }
        .onChange(of: blockLogFilter) { _ in blockLogPage = 0 }
        .onChange(of: selectedDomain) { _ in blockLogPage = 0 }
    }

    private var blockLogDomainPicker: some View {
        Menu {
            Button {
                selectedDomain = nil
            } label: {
                HStack {
                    Text(L10n.Cerberus.VisitorLog.allDomains)
                    if selectedDomain == nil { Image(systemName: "checkmark") }
                }
            }
            Divider()
            ForEach(blockLogDomains, id: \.self) { domain in
                Button {
                    selectedDomain = domain
                } label: {
                    HStack {
                        Text(domain)
                        if selectedDomain == domain { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: AXSpacing.xxxs) {
                Image(systemName: "globe").font(.system(size: 10))
                Text(selectedDomain ?? L10n.Cerberus.VisitorLog.allDomains)
                    .font(AXTypography.caption)
                    .fontWeight(selectedDomain != nil ? .semibold : .regular)
                    .lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 8))
            }
            .foregroundStyle(selectedDomain != nil ? Color.axAccentBlue : Color.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(selectedDomain != nil ? Color.axAccentBlue.opacity(0.1) : Color.axSurface)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
    }

    private var blockLogDomains: [String] {
        Array(Set(viewModel.blockLog.map(\.host)))
            .filter { !$0.isEmpty }
            .sorted()
    }

    private var blockLogRefreshButton: some View {
        Button {
            Task { await viewModel.loadBlockLog() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axAccentBlue)
                .padding(AXSpacing.sm)
                .background(RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axAccentBlue.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private var blockLogStatsRow: some View {
        let blocks = filteredBlockLog
        let critCount = blocks.filter { $0.severity.lowercased() == "critical" }.count
        let highCount = blocks.filter { $0.severity.lowercased() == "high" }.count
        let uniqueIPs = Set(blocks.map(\.ip)).count
        return HStack(spacing: AXSpacing.md) {
            blockLogStatCard(label: L10n.Cerberus.Attacks.totalBlocks, value: "\(blocks.count)", icon: "hand.raised.fill", color: .axError)
            blockLogStatCard(label: L10n.Cerberus.Attacks.critical, value: "\(critCount)", icon: "exclamationmark.octagon.fill", color: .axError)
            blockLogStatCard(label: L10n.Cerberus.Attacks.high, value: "\(highCount)", icon: "exclamationmark.triangle.fill", color: .axWarning)
            blockLogStatCard(label: L10n.Cerberus.Attacks.uniqueIPs, value: "\(uniqueIPs)", icon: "person.2.fill", color: .axAccentBlue)
        }
    }

    private func blockLogStatCard(label: String, value: String, icon: String, color: Color) -> some View {
        AXCard(accentColor: color) {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(color.opacity(0.12)).frame(width: 30, height: 30)
                    Image(systemName: icon).font(AXTypography.caption).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(value).font(AXTypography.title3).fontWeight(.bold).foregroundStyle(Color.axTextPrimary)
                    Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Block Log Table

    private var blockLogTable: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                blockLogTableHeader
                if filteredBlockLog.isEmpty {
                    emptyState(icon: "shield.checkered", text: L10n.Cerberus.Attacks.noBlockLog)
                } else {
                    blockLogRows
                }
            }
        }
    }

    private var blockLogTableHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.Cerberus.Attacks.colTime).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 70)
            Text(L10n.Cerberus.Attacks.colIP).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 120, alignment: .leading)
            Text(L10n.Cerberus.Attacks.colCountry).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 40)
            Text(L10n.Cerberus.Attacks.colMethod).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 50)
            Text(L10n.Field.path).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Cerberus.Attacks.colRule).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 120, alignment: .leading)
            Text(L10n.Cerberus.Attacks.colSeverity).font(AXTypography.monoXs).foregroundStyle(Color.axTextMuted).frame(width: 65)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface))
    }

    private var blockLogRows: some View {
        VStack(spacing: 0) {
            ForEach(Array(paginatedBlockLog.enumerated()), id: \.element.id) { idx, entry in
                blockLogRowContent(entry: entry, isEven: idx % 2 == 0)
            }
            if blockLogTotalPages > 1 {
                blockLogPaginationBar
            }
        }
    }

    private var paginatedBlockLog: [WAFBlockLogEntry] {
        let start = blockLogPage * blockLogPageSize
        let end = min(start + blockLogPageSize, filteredBlockLog.count)
        guard start < end else { return [] }
        return Array(filteredBlockLog[start..<end])
    }

    private var blockLogTotalPages: Int {
        max(1, (filteredBlockLog.count + blockLogPageSize - 1) / blockLogPageSize)
    }

    private var blockLogPaginationBar: some View {
        HStack(spacing: AXSpacing.md) {
            Text(L10n.Cerberus.Pagination.showing(
                blockLogPage * blockLogPageSize + 1,
                min((blockLogPage + 1) * blockLogPageSize, filteredBlockLog.count),
                filteredBlockLog.count
            ))
            .font(AXTypography.caption)
            .foregroundStyle(Color.axTextMuted)
            Spacer()
            HStack(spacing: AXSpacing.xs) {
                blockLogPageBtn(icon: "chevron.left", action: { blockLogPage -= 1 }, disabled: blockLogPage == 0)
                Text(L10n.Cerberus.Pagination.page(blockLogPage + 1, blockLogTotalPages))
                    .font(AXTypography.monoSm)
                    .foregroundStyle(Color.axTextSecondary)
                blockLogPageBtn(icon: "chevron.right", action: { blockLogPage += 1 }, disabled: blockLogPage >= blockLogTotalPages - 1)
            }
        }
        .padding(.top, AXSpacing.md)
    }

    private func blockLogPageBtn(icon: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(disabled ? Color.axTextMuted.opacity(0.4) : Color.axAccentBlue)
                .frame(width: 26, height: 26)
                .background(disabled ? Color.clear : Color.axAccentBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func blockLogRowContent(entry: WAFBlockLogEntry, isEven: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(formatTime(entry.timestamp)).font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextMuted).frame(width: 70)
            Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(entry.ip) : entry.ip).font(AXTypography.monoXs).foregroundStyle(Color.axTextPrimary)
                .frame(width: 120, alignment: .leading).lineLimit(1)
            Text(countryFlagEmoji( entry.countryCode)).frame(width: 40)
            Text(entry.method).font(AXTypography.monoXs).foregroundStyle(methodColor(entry.method))
                .frame(width: 50)
            Text(entry.path).font(AXTypography.monoXs).foregroundStyle(Color.axTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            Text(entry.rule).font(AXTypography.monoXs).foregroundStyle(Color.axError)
                .frame(width: 120, alignment: .leading).lineLimit(1)
            severityBadge(entry.severity).frame(width: 65)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                .fill(isEven ? Color.axSurfaceHover.opacity(0.3) : Color.clear)
        )
    }

    // MARK: - Attacker Detail Sheet

    private func attackerDetailSheet(_ attacker: AttackerInfo) -> some View {
        VStack(spacing: 0) {
            attackerSheetHero(attacker)
            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
            attackerSheetBody(attacker)
            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
            attackerSheetActions(attacker)
        }
        .frame(minWidth: 420, idealWidth: 500, maxWidth: 600, minHeight: 380, idealHeight: 440, maxHeight: 540)
        .background(Color.axBackground)
    }

    private func attackerSheetHero(_ attacker: AttackerInfo) -> some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.axError.opacity(0.2), Color.axError.opacity(0.04)], center: .center, startRadius: 0, endRadius: 26))
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                    .frame(width: 52, height: 52)
                Text(countryFlagEmoji( attacker.countryCode))
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(attacker.ip) : attacker.ip)
                    .font(AXTypography.monoMd)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    AXBadge(text: attacker.country, color: .axAccentBlue, style: .soft)
                    AXBadge(text: viewModel.formatNumber(attacker.attacks) + " attacks", color: .axError, style: .soft)
                }
            }
            Spacer()
            Button { selectedAttacker = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
        .background(LinearGradient(colors: [Color.axError.opacity(0.04), Color.clear], startPoint: .leading, endPoint: .trailing))
    }

    private func attackerSheetBody(_ attacker: AttackerInfo) -> some View {
        ScrollView {
            VStack(spacing: AXSpacing.xxs) {
                attackerField(label: L10n.Cerberus.Attacks.ipAddress, value: attacker.ip, icon: "network", color: .axAccentBlue)
                attackerField(label: L10n.Cerberus.Attacks.totalAttacks, value: viewModel.formatNumber(attacker.attacks), icon: "exclamationmark.triangle.fill", color: .axError)
                attackerField(label: L10n.Cerberus.Attacks.lastSeen, value: attacker.lastSeen, icon: "clock.fill", color: .axWarning)
                attackerField(label: L10n.Cerberus.Attacks.country, value: "\(countryFlagEmoji( attacker.countryCode)) \(attacker.country)", icon: "globe", color: .axAccentBlue)
                attackerField(label: L10n.Cerberus.Attacks.countryCode, value: attacker.countryCode.uppercased(), icon: "mappin.circle.fill", color: .axAccentBlue)
            }
            .padding(AXSpacing.lg)
        }
    }

    private func attackerField(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color.opacity(0.6))
                .frame(width: 18)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.vertical, AXSpacing.sm)
        .padding(.horizontal, AXSpacing.md)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.3)))
    }

    private func attackerSheetActions(_ attacker: AttackerInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            Button { selectedAttacker = nil } label: {
                Text(L10n.Button.close)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).strokeBorder(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            AXPrimaryButton(
                title: L10n.Cerberus.Attacks.blockIP,
                icon: "hand.raised.fill",
                action: { Task { await viewModel.blockIP(attacker.ip); selectedAttacker = nil } },
                isLoading: viewModel.ipOperationInProgress,
                style: .destructive
            )
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Helpers

    private var totalAttackCount: Int { viewModel.attackTypes.reduce(0) { $0 + $1.count } }

    private var attackIntensityColor: Color {
        if totalAttackCount > 10_000 { return .axError }
        if totalAttackCount > 1_000 { return .axWarning }
        if totalAttackCount > 0 { return .axAccentBlue }
        return .axAccentGreen
    }

    private var filteredBlockLog: [WAFBlockLogEntry] {
        var entries = viewModel.blockLog

        if let domain = selectedDomain {
            entries = entries.filter { $0.host == domain }
        }

        guard !blockLogFilter.isEmpty else { return entries }
        let q = blockLogFilter.lowercased()
        return entries.filter {
            $0.ip.lowercased().contains(q) || $0.rule.lowercased().contains(q) ||
            $0.path.lowercased().contains(q) || $0.country.lowercased().contains(q)
        }
    }

    private func rankBadge(_ rank: Int, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(color.opacity(rank <= 3 ? 0.15 : 0.06))
                .frame(width: 22, height: 22)
            Text("\(rank)").font(AXTypography.monoXs)
                .fontWeight(rank <= 3 ? .bold : .regular).foregroundStyle(color)
        }
    }

    private func severityBadge(_ severity: String) -> some View {
        let color = severityColor(severity)
        return Text(L10n.Cerberus.Alerts.filterLabel(for: severity))
            .font(AXTypography.monoXs)
            .foregroundStyle(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private func severityColor(_ s: String) -> Color {
        switch s.lowercased() {
        case "critical": return .axError
        case "high": return .axWarning
        case "medium": return .axWarning
        default: return .axAccentBlue
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .axAccentGreen
        case "POST": return .axAccentBlue
        case "PUT", "PATCH": return .axWarning
        case "DELETE": return .axError
        default: return .axTextMuted
        }
    }

    private func emptyState(icon: String, text: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon).font(AXTypography.title2).foregroundStyle(Color.axTextMuted)
                Text(text).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }
            .padding(.vertical, AXSpacing.xxl)
            Spacer()
        }
    }


    private func localizedCountryName(_ country: CountryStats) -> String {
        if !country.countryName.isEmpty { return country.countryName }
        return Locale.current.localizedString(forRegionCode: country.countryCode) ?? country.countryCode
    }

    private func formatTime(_ ts: String) -> String {
        guard ts.count >= 19 else { return ts }
        return String(ts.suffix(from: ts.index(ts.startIndex, offsetBy: 11)).prefix(8))
    }
}
