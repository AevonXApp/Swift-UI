//
//  CerberusIPManagementView.swift
//  AevonX
//
//  IP Guard tab — blocklist, allowlist, GeoIP country blocking.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusIPManagementView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var newBlockIP = ""
    @State private var newAllowIP = ""
    @State private var newBlockCountry = ""
    @State private var searchQuery = ""
    @State private var showAddBlockSheet = false
    @State private var showAddAllowSheet = false
    @State private var showAddCountrySheet = false
    @State private var confirmDeleteIP: IPDeleteTarget?
    @State private var bulkMode = false
    @State private var countrySearch = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.ipLoading && viewModel.blockedIPs.isEmpty && viewModel.allowedIPs.isEmpty {
                    ipSkeletonContent
                } else {
                    ipHeroSection
                    searchBar
                    HStack(alignment: .top, spacing: AXSpacing.lg) {
                        blocklistSection
                        allowlistSection
                    }
                    geoIPSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .task {
            async let ips: () = viewModel.loadIPLists()
            async let geo: () = viewModel.loadGeoIP()
            _ = await (ips, geo)
        }
        .sheet(isPresented: $showAddBlockSheet) { addIPSheet(isBlock: true) }
        .sheet(isPresented: $showAddAllowSheet) { addIPSheet(isBlock: false) }
        .sheet(isPresented: $showAddCountrySheet) { addCountrySheet }
        .alert(
            L10n.Cerberus.IP.confirmDeleteTitle,
            isPresented: Binding(
                get: { confirmDeleteIP != nil },
                set: { if !$0 { confirmDeleteIP = nil } }
            ),
            presenting: confirmDeleteIP
        ) { target in
            Button(L10n.Button.cancel, role: .cancel) {}
            Button(L10n.Cerberus.IP.confirmDeleteAction, role: .destructive) {
                Task {
                    if target.isBlock { await viewModel.unblockIP(target.ip) }
                    else { await viewModel.removeAllowedIP(target.ip) }
                }
            }
        } message: { target in
            Text(L10n.Cerberus.IP.confirmDeleteMessage(target.ip))
        }
    }
}

// MARK: - Skeleton

private extension CerberusIPManagementView {

    var ipSkeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            AXCard { AXSkeletonBlock(lines: 2) }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                AXCard { AXSkeletonBlock(lines: 5) }
                AXCard { AXSkeletonBlock(lines: 5) }
            }
        }
    }
}

// MARK: - Hero Section

private extension CerberusIPManagementView {

    var ipHeroSection: some View {
        AXGlassCard(accentColor: .axAccentPurple) {
            HStack(spacing: AXSpacing.xxl) {
                ipHeroIcon
                ipHeroTitle
                Spacer()
                ipHeroStats
            }
        }
    }

    var ipHeroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentPurple.opacity(0.2), Color.axAccentPurple.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 26
                    )
                )
                .frame(width: 48, height: 48)
            Circle()
                .stroke(Color.axAccentPurple.opacity(0.25), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: "network.badge.shield.half.filled")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axAccentPurple)
        }
    }

    var ipHeroTitle: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(L10n.Cerberus.IP.title)
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(L10n.Cerberus.IP.subtitle)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var ipHeroStats: some View {
        HStack(spacing: AXSpacing.xxl) {
            heroStat(icon: "hand.raised.fill", value: "\(viewModel.blockedIPs.count)", label: L10n.Cerberus.IP.statBlocked, color: .axError)
            Divider().frame(height: 36)
            heroStat(icon: "checkmark.shield.fill", value: "\(viewModel.allowedIPs.count)", label: L10n.Cerberus.IP.statAllowed, color: .axAccentGreen)
            Divider().frame(height: 36)
            heroStat(icon: "globe.badge.chevron.backward", value: "\(viewModel.blockedCountries.count)", label: L10n.Cerberus.IP.statCountries, color: .axAccentPurple)
            Divider().frame(height: 36)
            heroStat(icon: "shield.checkered", value: "\(totalRules)", label: L10n.Cerberus.IP.totalRules, color: .axAccentBlue)
        }
    }

    func heroStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(AXTypography.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }
}

// MARK: - Search

private extension CerberusIPManagementView {

    var searchBar: some View {
        AXTextField(placeholder: L10n.Cerberus.IP.searchPlaceholder, text: $searchQuery, icon: "magnifyingglass")
    }
}

// MARK: - Blocklist

private extension CerberusIPManagementView {

    var blocklistSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                blocklistHeader
                if filteredBlockedIPs.isEmpty {
                    ipEmptyState(text: L10n.Cerberus.IP.noBlockedIPs, icon: "hand.raised.slash")
                } else {
                    blocklistContent
                }
            }
        }
    }

    var blocklistHeader: some View {
        HStack {
            Image(systemName: "hand.raised.fill").foregroundStyle(Color.axError)
            Text(L10n.Cerberus.IP.blockedIPs).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(filteredBlockedIPs.count)", color: .axError, style: .soft)
            copyBtn(ips: viewModel.blockedIPs)
            addBtn(color: .axError) { showAddBlockSheet = true }
        }
    }

    var blocklistContent: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(filteredBlockedIPs, id: \.self) { ip in
                ipRow(ip: ip, isBlock: true)
            }
        }
    }
}

// MARK: - Allowlist

private extension CerberusIPManagementView {

    var allowlistSection: some View {
        AXCard(accentColor: .axAccentGreen) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                allowlistHeader
                if filteredAllowedIPs.isEmpty {
                    ipEmptyState(text: L10n.Cerberus.IP.noAllowedIPs, icon: "checkmark.shield")
                } else {
                    allowlistContent
                }
            }
        }
    }

    var allowlistHeader: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(Color.axAccentGreen)
            Text(L10n.Cerberus.IP.allowedIPs).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(filteredAllowedIPs.count)", color: .axAccentGreen, style: .soft)
            copyBtn(ips: viewModel.allowedIPs)
            addBtn(color: .axAccentGreen) { showAddAllowSheet = true }
        }
    }

    var allowlistContent: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(filteredAllowedIPs, id: \.self) { ip in
                ipRow(ip: ip, isBlock: false)
            }
        }
    }
}

// MARK: - IP Row

private extension CerberusIPManagementView {

    func ipRow(ip: String, isBlock: Bool) -> some View {
        let accent: Color = isBlock ? .axError : .axAccentGreen
        let isCIDR = ip.contains("/")
        return HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(accent.opacity(0.4))
                .frame(width: 6, height: 6)
            Text(ip)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
            if isCIDR {
                Text("CIDR")
                    .font(AXTypography.caption2)
                    .foregroundStyle(accent)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
            }
            Spacer()
            Button {
                confirmDeleteIP = IPDeleteTarget(ip: ip, isBlock: isBlock)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.axTextTertiary)
                    .frame(width: 24, height: 24)
                    .background(Color.axError.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.ipOperationInProgress)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.5)))
    }

    func copyBtn(ips: [String]) -> some View {
        Button {
            let text = ips.joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.IP.copiedToClipboard(ips.count))
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 11))
                .foregroundStyle(Color.axTextTertiary)
        }
        .buttonStyle(.plain)
        .disabled(ips.isEmpty)
        .help(L10n.Cerberus.IP.copyTooltip)
    }

    func addBtn(color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    func ipEmptyState(text: String, icon: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(AXTypography.title3)
                    .foregroundStyle(Color.axTextMuted)
                Text(text)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
            .padding(.vertical, AXSpacing.xl)
            Spacer()
        }
    }
}

// MARK: - GeoIP Section

private extension CerberusIPManagementView {

    var geoIPSection: some View {
        AXCard(accentColor: .axAccentPurple) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                geoIPHeader
                Text(L10n.Cerberus.IP.geoIPDesc)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                if viewModel.blockedCountries.isEmpty {
                    ipEmptyState(text: L10n.Cerberus.IP.noCountriesBlocked, icon: "globe")
                } else {
                    countryGrid
                }
            }
        }
    }

    var geoIPHeader: some View {
        HStack {
            Image(systemName: "globe.badge.chevron.backward").foregroundStyle(Color.axAccentPurple)
            Text(L10n.Cerberus.IP.countryBlocking).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(viewModel.blockedCountries.count)", color: .axAccentPurple, style: .soft)
            addBtn(color: .axAccentPurple) { showAddCountrySheet = true }
        }
    }

    var countryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AXSpacing.xs) {
            ForEach(viewModel.blockedCountries, id: \.self) { code in
                countryChip(code)
            }
        }
    }

    func countryChip(_ code: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Text(flagEmoji(for: code))
            Text(code)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            Button {
                Task { await viewModel.unblockCountry(code) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.geoIPOperationInProgress)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentPurple.opacity(0.06)))
    }
}

// MARK: - Add IP Sheet

private extension CerberusIPManagementView {

    func addIPSheet(isBlock: Bool) -> some View {
        let accent: Color = isBlock ? .axError : .axAccentGreen
        let iconName = isBlock ? "hand.raised.fill" : "checkmark.shield.fill"
        let binding: Binding<String> = isBlock ? $newBlockIP : $newAllowIP
        let inputValue = isBlock ? newBlockIP : newAllowIP
        let validation = bulkMode
            ? IPValidation.validateBulk(inputValue)
            : (valid: [String](), invalid: [String]())
        let singleValidation = bulkMode ? nil : IPValidation.validate(inputValue)

        return VStack(spacing: 0) {
            addIPSheetHeader(accent: accent, iconName: iconName, isBlock: isBlock)

            // Mode toggle
            Picker("", selection: $bulkMode) {
                Text(L10n.Cerberus.IP.modeSingle).tag(false)
                Text(L10n.Cerberus.IP.modeBulk).tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.bottom, AXSpacing.md)

            // Input section
            VStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text(bulkMode ? L10n.Cerberus.IP.bulkLabel : L10n.Cerberus.IP.ipLabel)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextSecondary)
                    if bulkMode {
                        TextEditor(text: binding)
                            .font(AXTypography.monoSm)
                            .frame(height: 100)
                            .padding(AXSpacing.xs)
                            .background(Color.axSurfaceHover.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    } else {
                        AXTextField(
                            placeholder: L10n.Cerberus.IP.ipPlaceholder,
                            text: binding,
                            icon: "network",
                            accentColor: accent,
                            validation: { _ in
                                if case .invalid = IPValidation.validate(inputValue) { return false }
                                return true
                            }
                        )
                    }
                }

                // Validation feedback
                addIPValidationFeedback(
                    singleValidation: singleValidation,
                    bulkValidation: validation,
                    accent: accent
                )
            }
            .padding(.horizontal, AXSpacing.xxl)

            Spacer()

            addIPSheetActions(
                isBlock: isBlock, accent: accent, iconName: iconName,
                inputValue: inputValue, singleValidation: singleValidation,
                bulkValidation: validation
            )
        }
        .frame(width: 480, height: bulkMode ? 480 : 420)
        .background(Color.axBackground)
    }

    private func addIPSheetHeader(accent: Color, iconName: String, isBlock: Bool) -> some View {
        VStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.2), accent.opacity(0.04)],
                            center: .center, startRadius: 0, endRadius: 28
                        )
                    )
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(accent.opacity(0.2), lineWidth: 1)
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text(isBlock ? L10n.Cerberus.IP.blockIPTitle : L10n.Cerberus.IP.allowIPTitle)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(isBlock ? L10n.Cerberus.IP.blockIPDesc : L10n.Cerberus.IP.allowIPDesc)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
        .padding(.top, AXSpacing.xxl)
        .padding(.bottom, AXSpacing.lg)
    }

    @ViewBuilder
    private func addIPValidationFeedback(
        singleValidation: IPValidation.Result?,
        bulkValidation: (valid: [String], invalid: [String]),
        accent: Color
    ) -> some View {
        if let sv = singleValidation {
            switch sv {
            case .empty:
                ipHintRow(accent: accent)
            case .validIP:
                validationBadge(
                    icon: "checkmark.circle.fill",
                    text: L10n.Cerberus.IP.validIP,
                    color: .axAccentGreen
                )
            case .validCIDR(let count):
                validationBadge(
                    icon: "checkmark.circle.fill",
                    text: L10n.Cerberus.IP.validCIDR(count),
                    color: .axAccentGreen
                )
            case .invalid:
                validationBadge(
                    icon: "xmark.circle.fill",
                    text: L10n.Cerberus.IP.invalidIP,
                    color: .axError
                )
            }
        } else {
            // Bulk mode
            if !bulkValidation.valid.isEmpty || !bulkValidation.invalid.isEmpty {
                HStack(spacing: AXSpacing.md) {
                    if !bulkValidation.valid.isEmpty {
                        validationBadge(
                            icon: "checkmark.circle.fill",
                            text: L10n.Cerberus.IP.bulkValid(bulkValidation.valid.count),
                            color: .axAccentGreen
                        )
                    }
                    if !bulkValidation.invalid.isEmpty {
                        validationBadge(
                            icon: "xmark.circle.fill",
                            text: L10n.Cerberus.IP.bulkInvalid(bulkValidation.invalid.count),
                            color: .axError
                        )
                    }
                }
            } else {
                ipHintRow(accent: accent)
            }
        }
    }

    private func ipHintRow(accent: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(accent.opacity(0.6))
            Text(L10n.Cerberus.IP.ipHint)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
        }
        .padding(AXSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
    }

    private func validationBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(text)
                .font(AXTypography.caption)
                .foregroundStyle(color)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
    }

    private func addIPSheetActions(
        isBlock: Bool, accent: Color, iconName: String,
        inputValue: String, singleValidation: IPValidation.Result?,
        bulkValidation: (valid: [String], invalid: [String])
    ) -> some View {
        let isDisabled: Bool = {
            if bulkMode {
                return bulkValidation.valid.isEmpty
            }
            guard let sv = singleValidation else { return true }
            switch sv {
            case .validIP, .validCIDR: return false
            default: return true
            }
        }()

        return HStack(spacing: AXSpacing.md) {
            Button {
                bulkMode = false
                if isBlock { newBlockIP = ""; showAddBlockSheet = false }
                else { newAllowIP = ""; showAddAllowSheet = false }
            } label: {
                Text(L10n.Button.cancel)
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
                title: bulkMode
                    ? L10n.Cerberus.IP.bulkAction(isBlock, bulkValidation.valid.count)
                    : (isBlock ? L10n.Cerberus.IP.blockIPBtn : L10n.Cerberus.IP.allowIPBtn),
                icon: iconName,
                action: {
                    Task {
                        if bulkMode {
                            for ip in bulkValidation.valid {
                                if isBlock { await viewModel.blockIP(ip) }
                                else { await viewModel.allowIP(ip) }
                            }
                        } else {
                            if isBlock { await viewModel.blockIP(newBlockIP) }
                            else { await viewModel.allowIP(newAllowIP) }
                        }
                        bulkMode = false
                        if isBlock { newBlockIP = ""; showAddBlockSheet = false }
                        else { newAllowIP = ""; showAddAllowSheet = false }
                    }
                },
                isLoading: viewModel.ipOperationInProgress,
                isDisabled: isDisabled,
                style: isBlock ? .destructive : .primary,
                accentColor: accent
            )
        }
        .padding(AXSpacing.xxl)
    }
}

// MARK: - Add Country Sheet

private extension CerberusIPManagementView {

    var addCountrySheet: some View {
        let alreadyBlocked = Set(viewModel.blockedCountries.map { $0.uppercased() })
        let filtered = CountryData.all.filter { entry in
            !alreadyBlocked.contains(entry.code) && (
                countrySearch.isEmpty
                || entry.name.localizedCaseInsensitiveContains(countrySearch)
                || entry.code.localizedCaseInsensitiveContains(countrySearch)
            )
        }

        return VStack(spacing: 0) {
            countrySheetHeader
            countrySearchBar
            countryList(filtered)
            countrySheetActions
        }
        .frame(width: 480, height: 500)
        .background(Color.axBackground)
    }

    private var countrySheetHeader: some View {
        VStack(spacing: AXSpacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.axAccentPurple.opacity(0.2), Color.axAccentPurple.opacity(0.04)],
                            center: .center, startRadius: 0, endRadius: 28
                        )
                    )
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(Color.axAccentPurple.opacity(0.2), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: "globe.badge.chevron.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.axAccentPurple)
            }
            Text(L10n.Cerberus.IP.selectCountries)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(L10n.Cerberus.IP.selectCountriesDesc)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.md)
    }

    private var countrySearchBar: some View {
        AXTextField(
            placeholder: L10n.Cerberus.IP.searchCountry,
            text: $countrySearch,
            icon: "magnifyingglass",
            accentColor: .axAccentPurple
        )
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.bottom, AXSpacing.sm)
    }

    private func countryList(_ filtered: [CountryData]) -> some View {
        ScrollView {
            LazyVStack(spacing: AXSpacing.xxxs) {
                ForEach(filtered, id: \.code) { entry in
                    countryRow(entry)
                }
            }
            .padding(.horizontal, AXSpacing.xxl)
        }
    }

    private func countryRow(_ entry: CountryData) -> some View {
        Button {
            Task {
                await viewModel.blockCountry(entry.code)
            }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Text(flagEmoji(for: entry.code))
                    .font(.system(size: 18))
                Text(entry.name)
                    .font(AXTypography.subheadline)
                    .foregroundStyle(Color.axTextPrimary)
                Spacer()
                Text(entry.code)
                    .font(AXTypography.monoSm)
                    .foregroundStyle(Color.axTextTertiary)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.axAccentPurple.opacity(0.5))
            }
            .padding(.vertical, AXSpacing.sm)
            .padding(.horizontal, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurfaceHover.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.geoIPOperationInProgress)
    }

    private var countrySheetActions: some View {
        HStack {
            Spacer()
            Button {
                countrySearch = ""
                showAddCountrySheet = false
            } label: {
                Text(L10n.Button.done)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axAccentPurple)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentPurple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xxl)
    }
}

// MARK: - Helpers

private extension CerberusIPManagementView {

    var totalRules: Int {
        viewModel.blockedIPs.count + viewModel.blockedCountries.count
    }

    var filteredBlockedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.blockedIPs }
        return viewModel.blockedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    var filteredAllowedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.allowedIPs }
        return viewModel.allowedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { flag.append(String(s)) }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}

// MARK: - IP Validation

private enum IPValidation {
    enum Result {
        case empty
        case validIP
        case validCIDR(addressCount: Int)
        case invalid
    }

    static func validate(_ input: String) -> Result {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .empty }

        if trimmed.contains("/") {
            return validateCIDR(trimmed)
        } else {
            return isValidIP(trimmed) ? .validIP : .invalid
        }
    }

    static func validateBulk(_ input: String) -> (valid: [String], invalid: [String]) {
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var valid: [String] = []
        var invalid: [String] = []
        for line in lines {
            let result = validate(line)
            switch result {
            case .validIP, .validCIDR:
                valid.append(line)
            case .invalid:
                invalid.append(line)
            case .empty:
                break
            }
        }
        return (valid, invalid)
    }

    private static func isValidIP(_ ip: String) -> Bool {
        var addr = in_addr()
        var addr6 = in6_addr()
        return inet_pton(AF_INET, ip, &addr) == 1
            || inet_pton(AF_INET6, ip, &addr6) == 1
    }

    private static func validateCIDR(_ cidr: String) -> Result {
        let parts = cidr.split(separator: "/", maxSplits: 1)
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              isValidIP(String(parts[0])) else {
            return .invalid
        }

        let isV6 = cidr.contains(":")
        let maxPrefix = isV6 ? 128 : 32
        guard prefix >= 0, prefix <= maxPrefix else { return .invalid }

        let addressCount: Int
        if isV6 {
            let hostBits = min(maxPrefix - prefix, 63) // cap to avoid overflow
            addressCount = 1 << hostBits
        } else {
            addressCount = 1 << (32 - prefix)
        }
        return .validCIDR(addressCount: addressCount)
    }
}

// MARK: - Delete Target

private struct IPDeleteTarget: Identifiable {
    let id = UUID()
    let ip: String
    let isBlock: Bool
}

// MARK: - Country Data

struct CountryData {
    let code: String
    let name: String

    static let all: [CountryData] = [
        .init(code: "AF", name: "Afghanistan"), .init(code: "AL", name: "Albania"),
        .init(code: "DZ", name: "Algeria"), .init(code: "AR", name: "Argentina"),
        .init(code: "AU", name: "Australia"), .init(code: "AT", name: "Austria"),
        .init(code: "BD", name: "Bangladesh"), .init(code: "BY", name: "Belarus"),
        .init(code: "BE", name: "Belgium"), .init(code: "BR", name: "Brazil"),
        .init(code: "BG", name: "Bulgaria"), .init(code: "CA", name: "Canada"),
        .init(code: "CL", name: "Chile"), .init(code: "CN", name: "China"),
        .init(code: "CO", name: "Colombia"), .init(code: "HR", name: "Croatia"),
        .init(code: "CZ", name: "Czech Republic"), .init(code: "DK", name: "Denmark"),
        .init(code: "EG", name: "Egypt"), .init(code: "EE", name: "Estonia"),
        .init(code: "FI", name: "Finland"), .init(code: "FR", name: "France"),
        .init(code: "DE", name: "Germany"), .init(code: "GR", name: "Greece"),
        .init(code: "HK", name: "Hong Kong"), .init(code: "HU", name: "Hungary"),
        .init(code: "IN", name: "India"), .init(code: "ID", name: "Indonesia"),
        .init(code: "IR", name: "Iran"), .init(code: "IQ", name: "Iraq"),
        .init(code: "IE", name: "Ireland"), .init(code: "IL", name: "Israel"),
        .init(code: "IT", name: "Italy"), .init(code: "JP", name: "Japan"),
        .init(code: "KZ", name: "Kazakhstan"), .init(code: "KE", name: "Kenya"),
        .init(code: "KP", name: "North Korea"), .init(code: "KR", name: "South Korea"),
        .init(code: "LV", name: "Latvia"), .init(code: "LT", name: "Lithuania"),
        .init(code: "MY", name: "Malaysia"), .init(code: "MX", name: "Mexico"),
        .init(code: "MA", name: "Morocco"), .init(code: "NL", name: "Netherlands"),
        .init(code: "NZ", name: "New Zealand"), .init(code: "NG", name: "Nigeria"),
        .init(code: "NO", name: "Norway"), .init(code: "PK", name: "Pakistan"),
        .init(code: "PE", name: "Peru"), .init(code: "PH", name: "Philippines"),
        .init(code: "PL", name: "Poland"), .init(code: "PT", name: "Portugal"),
        .init(code: "RO", name: "Romania"), .init(code: "RU", name: "Russia"),
        .init(code: "SA", name: "Saudi Arabia"), .init(code: "RS", name: "Serbia"),
        .init(code: "SG", name: "Singapore"), .init(code: "SK", name: "Slovakia"),
        .init(code: "ZA", name: "South Africa"), .init(code: "ES", name: "Spain"),
        .init(code: "SE", name: "Sweden"), .init(code: "CH", name: "Switzerland"),
        .init(code: "SY", name: "Syria"), .init(code: "TW", name: "Taiwan"),
        .init(code: "TH", name: "Thailand"), .init(code: "TR", name: "Turkey"),
        .init(code: "UA", name: "Ukraine"), .init(code: "AE", name: "United Arab Emirates"),
        .init(code: "GB", name: "United Kingdom"), .init(code: "US", name: "United States"),
        .init(code: "VN", name: "Vietnam"), .init(code: "VE", name: "Venezuela"),
    ]
}
