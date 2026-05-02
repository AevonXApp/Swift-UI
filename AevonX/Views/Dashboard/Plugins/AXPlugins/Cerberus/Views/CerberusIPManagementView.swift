//
//  CerberusIPManagementView.swift
//  AevonX
//
//  IP Guard tab — blocklist, allowlist, GeoIP country blocking.
//  All add-forms are inline (no sheets).
//

import SwiftUI
import AevonXCoreBridge

struct CerberusIPManagementView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var newBlockIP = ""
    @State private var newAllowIP = ""
    @State private var searchQuery = ""
    @State private var showAddBlockForm = false
    @State private var showAddAllowForm = false
    @State private var showAddCountryForm = false
    @State private var confirmDeleteIP: IPDeleteTarget?
    @State private var bulkBlockMode = false
    @State private var bulkAllowMode = false
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
        AXGlassCard(accentColor: .axAccentBlue) {
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
                        colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 26
                    )
                )
                .frame(width: 48, height: 48)
            Circle()
                .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: "network.badge.shield.half.filled")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axAccentBlue)
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
            heroStat(icon: "globe.badge.chevron.backward", value: "\(viewModel.blockedCountries.count)", label: L10n.Cerberus.IP.statCountries, color: .axAccentBlue)
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

                // Inline add form
                if showAddBlockForm {
                    inlineAddIPForm(isBlock: true)
                }

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
            addToggleBtn(color: .axError, isExpanded: $showAddBlockForm) {
                showAddAllowForm = false
                showAddCountryForm = false
            }
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

                // Inline add form
                if showAddAllowForm {
                    inlineAddIPForm(isBlock: false)
                }

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
            addToggleBtn(color: .axAccentGreen, isExpanded: $showAddAllowForm) {
                showAddBlockForm = false
                showAddCountryForm = false
            }
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

// MARK: - Inline Add IP Form

private extension CerberusIPManagementView {

    func inlineAddIPForm(isBlock: Bool) -> some View {
        let accent: Color = isBlock ? .axError : .axAccentGreen
        let binding: Binding<String> = isBlock ? $newBlockIP : $newAllowIP
        let inputValue = isBlock ? newBlockIP : newAllowIP
        let isBulk = isBlock ? bulkBlockMode : bulkAllowMode
        let bulkBinding: Binding<Bool> = isBlock ? $bulkBlockMode : $bulkAllowMode
        let validation = isBulk
            ? IPValidation.validateBulk(inputValue)
            : (valid: [String](), invalid: [String]())
        let singleValidation = isBulk ? nil : IPValidation.validate(inputValue)

        return VStack(spacing: AXSpacing.md) {
            Divider().background(accent.opacity(0.3))

            // Mode toggle
            Picker("", selection: bulkBinding) {
                Text(L10n.Cerberus.IP.modeSingle).tag(false)
                Text(L10n.Cerberus.IP.modeBulk).tag(true)
            }
            .pickerStyle(.segmented)

            // Input
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(isBulk ? L10n.Cerberus.IP.bulkLabel : L10n.Cerberus.IP.ipLabel)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextSecondary)
                if isBulk {
                    TextEditor(text: binding)
                        .font(AXTypography.monoSm)
                        .frame(height: 80)
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
            inlineValidationFeedback(
                singleValidation: singleValidation,
                bulkValidation: validation,
                accent: accent
            )

            // Actions
            inlineIPActions(
                isBlock: isBlock, accent: accent,
                inputValue: inputValue, isBulk: isBulk,
                singleValidation: singleValidation,
                bulkValidation: validation
            )

            Divider().background(accent.opacity(0.3))
        }
        .padding(.vertical, AXSpacing.xs)
        .animation(.easeInOut(duration: 0.2), value: isBulk)
    }

    @ViewBuilder
    private func inlineValidationFeedback(
        singleValidation: IPValidation.Result?,
        bulkValidation: (valid: [String], invalid: [String]),
        accent: Color
    ) -> some View {
        if let sv = singleValidation {
            switch sv {
            case .empty:
                ipHintRow(accent: accent)
            case .validIP:
                validationBadge(icon: "checkmark.circle.fill", text: L10n.Cerberus.IP.validIP, color: .axAccentGreen)
            case .validCIDR(let count):
                validationBadge(icon: "checkmark.circle.fill", text: L10n.Cerberus.IP.validCIDR(count), color: .axAccentGreen)
            case .invalid:
                validationBadge(icon: "xmark.circle.fill", text: L10n.Cerberus.IP.invalidIP, color: .axError)
            }
        } else {
            if !bulkValidation.valid.isEmpty || !bulkValidation.invalid.isEmpty {
                HStack(spacing: AXSpacing.md) {
                    if !bulkValidation.valid.isEmpty {
                        validationBadge(icon: "checkmark.circle.fill", text: L10n.Cerberus.IP.bulkValid(bulkValidation.valid.count), color: .axAccentGreen)
                    }
                    if !bulkValidation.invalid.isEmpty {
                        validationBadge(icon: "xmark.circle.fill", text: L10n.Cerberus.IP.bulkInvalid(bulkValidation.invalid.count), color: .axError)
                    }
                }
            } else {
                ipHintRow(accent: accent)
            }
        }
    }

    private func inlineIPActions(
        isBlock: Bool, accent: Color,
        inputValue: String, isBulk: Bool,
        singleValidation: IPValidation.Result?,
        bulkValidation: (valid: [String], invalid: [String])
    ) -> some View {
        let isDisabled: Bool = {
            if isBulk { return bulkValidation.valid.isEmpty }
            guard let sv = singleValidation else { return true }
            switch sv {
            case .validIP, .validCIDR: return false
            default: return true
            }
        }()
        let iconName = isBlock ? "hand.raised.fill" : "checkmark.shield.fill"

        return HStack(spacing: AXSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isBlock {
                        newBlockIP = ""
                        bulkBlockMode = false
                        showAddBlockForm = false
                    } else {
                        newAllowIP = ""
                        bulkAllowMode = false
                        showAddAllowForm = false
                    }
                }
            } label: {
                Text(L10n.Button.cancel)
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).strokeBorder(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    if isBulk {
                        if isBlock { await viewModel.bulkBlockIPs(bulkValidation.valid) }
                        else { await viewModel.bulkAllowIPs(bulkValidation.valid) }
                    } else {
                        if isBlock { await viewModel.blockIP(newBlockIP) }
                        else { await viewModel.allowIP(newAllowIP) }
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isBlock { newBlockIP = ""; bulkBlockMode = false; showAddBlockForm = false }
                        else { newAllowIP = ""; bulkAllowMode = false; showAddAllowForm = false }
                    }
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if viewModel.ipOperationInProgress {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 10))
                    }
                    Text(isBulk
                         ? L10n.Cerberus.IP.bulkAction(isBlock, bulkValidation.valid.count)
                         : (isBlock ? L10n.Cerberus.IP.blockIPBtn : L10n.Cerberus.IP.allowIPBtn))
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isDisabled ? Color.axTextMuted : .white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.xs)
                .background(isDisabled ? Color.axSurface : accent)
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled || viewModel.ipOperationInProgress)

            Spacer()
        }
    }
}

// MARK: - IP Row & Shared Components

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
                Text(L10n.Literal.cidr)
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

    func addToggleBtn(color: Color, isExpanded: Binding<Bool>, onExpand: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if !isExpanded.wrappedValue { onExpand() }
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            Image(systemName: isExpanded.wrappedValue ? "xmark.circle.fill" : "plus.circle.fill")
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

    func ipHintRow(accent: Color) -> some View {
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

    func validationBadge(icon: String, text: String, color: Color) -> some View {
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
}

// MARK: - GeoIP Section

private extension CerberusIPManagementView {

    var geoIPSection: some View {
        AXCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                geoIPHeader
                Text(L10n.Cerberus.IP.geoIPDesc)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)

                // Inline add country form
                if showAddCountryForm {
                    inlineAddCountryForm
                }

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
            Image(systemName: "globe.badge.chevron.backward").foregroundStyle(Color.axAccentBlue)
            Text(L10n.Cerberus.IP.countryBlocking).font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(viewModel.blockedCountries.count)", color: .axAccentBlue, style: .soft)
            addToggleBtn(color: .axAccentBlue, isExpanded: $showAddCountryForm) {
                showAddBlockForm = false
                showAddAllowForm = false
            }
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
        let name = Locale.current.localizedString(forRegionCode: code) ?? code
        return HStack(spacing: AXSpacing.xs) {
            Text(countryFlagEmoji( code))
            Text(name)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextPrimary)
                .lineLimit(1)
            Text(code)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextTertiary)
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
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.06)))
    }
}

// MARK: - Inline Add Country Form

private extension CerberusIPManagementView {

    var inlineAddCountryForm: some View {
        let alreadyBlocked = Set(viewModel.blockedCountries.map { $0.uppercased() })
        let filtered = CountryData.all.filter { entry in
            !alreadyBlocked.contains(entry.code) && (
                countrySearch.isEmpty
                || entry.name.localizedCaseInsensitiveContains(countrySearch)
                || entry.code.localizedCaseInsensitiveContains(countrySearch)
            )
        }

        return VStack(spacing: AXSpacing.md) {
            Divider().background(Color.axAccentBlue.opacity(0.3))

            // Search
            AXTextField(
                placeholder: L10n.Cerberus.IP.searchCountry,
                text: $countrySearch,
                icon: "magnifyingglass",
                accentColor: .axAccentBlue
            )

            // Country list — scrollable within the card
            ScrollView {
                LazyVStack(spacing: AXSpacing.xxxs) {
                    ForEach(filtered, id: \.code) { entry in
                        inlineCountryRow(entry)
                    }
                }
            }
            .frame(maxHeight: 260)

            // Done button
            HStack {
                Text(L10n.Cerberus.IP.selectCountriesDesc)
                    .font(AXTypography.caption2)
                    .foregroundStyle(Color.axTextMuted)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        countrySearch = ""
                        showAddCountryForm = false
                    }
                } label: {
                    Text(L10n.Button.done)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axAccentBlue)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.axAccentBlue.opacity(0.3))
        }
        .padding(.vertical, AXSpacing.xs)
    }

    private func inlineCountryRow(_ entry: CountryData) -> some View {
        Button {
            Task { await viewModel.blockCountry(entry.code) }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Text(countryFlagEmoji( entry.code))
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
                    .foregroundStyle(Color.axAccentBlue.opacity(0.5))
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
}

// MARK: - Helpers

private extension CerberusIPManagementView {

    var totalRules: Int {
        viewModel.blockedIPs.count + viewModel.allowedIPs.count + viewModel.blockedCountries.count
    }

    var filteredBlockedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.blockedIPs }
        return viewModel.blockedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    var filteredAllowedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.allowedIPs }
        return viewModel.allowedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
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
            let hostBits = min(maxPrefix - prefix, 63)
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

    /// All ISO 3166-1 countries, names auto-localized via Locale.
    static let all: [CountryData] = {
        let locale = Locale.current
        return Locale.Region.isoRegions
            .filter { $0.subRegions.isEmpty }
            .compactMap { region in
                let code = region.identifier
                guard code.count == 2,
                      let name = locale.localizedString(forRegionCode: code),
                      name != code
                else { return nil }
                return CountryData(code: code, name: name)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }()
}
