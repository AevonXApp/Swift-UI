//
//  SystemHardeningSubTab.swift
//  AevonX
//
//  System hardening checks — real kernel/SSH settings from server
//

import SwiftUI
import AevonXCore

// MARK: - Data Model

struct HardeningCheck: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let description: String
    let icon: String
    let category: Category
    let severity: Severity
    var currentValue: String
    var isSecure: Bool

    enum Category: String, CaseIterable {
        case kernel = "Kernel & Memory"
        case network = "Network"
        case ssh = "SSH Security"
        case services = "Services"
    }

    enum Severity {
        case critical, recommended, optional

        var color: Color {
            switch self {
            case .critical: return .axError
            case .recommended: return .axWarning
            case .optional: return .axInfo
            }
        }

        var label: String {
            switch self {
            case .critical: return "Critical"
            case .recommended: return "Recommended"
            case .optional: return "Optional"
            }
        }
    }
}

// MARK: - View

struct SystemHardeningSubTab: View {
    let serverId: String

    @State private var checks: [HardeningCheck] = []
    @State private var isLoading = true
    @State private var selectedCategory: HardeningCheck.Category? = nil
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    private var filteredChecks: [HardeningCheck] {
        var result = checks
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.label.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.currentValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var complianceScore: Int {
        guard !checks.isEmpty else { return 0 }
        let secure = checks.filter(\.isSecure).count
        return Int(Double(secure) / Double(checks.count) * 100)
    }

    private var criticalPending: Int {
        checks.filter { !$0.isSecure && $0.severity == .critical }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                complianceCard
                categoryFilter

                // Search
                AXSearchBar(text: $searchText, placeholder: "Search hardening checks…")

                if isLoading {
                    loadingView
                } else {
                    ForEach(groupedCategories, id: \.key) { category, items in
                        categorySection(category: category, items: items)
                    }
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadData() }
    }

    private var groupedCategories: [(key: HardeningCheck.Category, value: [HardeningCheck])] {
        let grouped = Dictionary(grouping: filteredChecks) { $0.category }
        return HardeningCheck.Category.allCases.compactMap { cat in
            if let items = grouped[cat] {
                return (key: cat, value: items)
            }
            return nil
        }
    }

    // MARK: - Load Data

    private func loadData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        // From Core: typed SecurityScore with raw hardening data
        let score = await securityManager.hardeningCheck(serverId: serverId)
        await MainActor.run {
            checks = parseHardeningResults(score.rawData)
        }
    }

    private func parseHardeningResults(_ raw: String) -> [HardeningCheck] {
        var values: [String: String] = [:]
        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }
            values[parts[0]] = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        }

        return [
            // Kernel
            HardeningCheck(
                key: "ASLR", label: "Address Space Layout Randomization (ASLR)",
                description: "Randomizes memory addresses to prevent exploitation",
                icon: "memorychip", category: .kernel, severity: .critical,
                currentValue: aslrLabel(values["ASLR"] ?? "N/A"),
                isSecure: values["ASLR"] == "2"
            ),
            HardeningCheck(
                key: "CORE_DUMP", label: "Restrict Core Dumps",
                description: "Prevents sensitive data leakage via core dumps",
                icon: "cpu.fill", category: .kernel, severity: .recommended,
                currentValue: values["CORE_DUMP"] == "0" ? "Restricted" : "Allowed",
                isSecure: values["CORE_DUMP"] == "0"
            ),

            // Network
            HardeningCheck(
                key: "SYN_COOKIES", label: "SYN Flood Protection",
                description: "Protects against TCP SYN flood denial-of-service attacks",
                icon: "shield.fill", category: .network, severity: .critical,
                currentValue: values["SYN_COOKIES"] == "1" ? "Enabled" : "Disabled",
                isSecure: values["SYN_COOKIES"] == "1"
            ),
            HardeningCheck(
                key: "SOURCE_ROUTE", label: "IP Source Routing Disabled",
                description: "Prevents IP source routing spoofing attacks",
                icon: "arrow.triangle.branch", category: .network, severity: .recommended,
                currentValue: values["SOURCE_ROUTE"] == "0" ? "Disabled" : "Enabled",
                isSecure: values["SOURCE_ROUTE"] == "0"
            ),
            HardeningCheck(
                key: "IPV6", label: "IPv6",
                description: "Disable IPv6 if not in use to reduce attack surface",
                icon: "network.slash", category: .network, severity: .optional,
                currentValue: values["IPV6"] == "1" ? "Disabled" : "Enabled",
                isSecure: true // IPv6 isn't a vulnerability itself
            ),

            // SSH
            HardeningCheck(
                key: "ROOT_LOGIN", label: "Root SSH Login",
                description: "Restricting root login improves server security",
                icon: "person.badge.shield.checkmark", category: .ssh, severity: .critical,
                currentValue: rootLoginLabel(values["ROOT_LOGIN"] ?? "N/A"),
                isSecure: values["ROOT_LOGIN"] == "no" || values["ROOT_LOGIN"] == "without-password"
            ),
            HardeningCheck(
                key: "SSH_PORT", label: "SSH Port",
                description: "Non-default SSH port reduces automated scanning",
                icon: "number", category: .ssh, severity: .recommended,
                currentValue: "Port \(values["SSH_PORT"] ?? "22")",
                isSecure: values["SSH_PORT"] != "22"
            ),
            HardeningCheck(
                key: "PASSWORD_AUTH", label: "SSH Password Authentication",
                description: "Key-only authentication is more secure",
                icon: "key.fill", category: .ssh, severity: .recommended,
                currentValue: values["PASSWORD_AUTH"] == "no" ? "Disabled (Key-only)" : "Enabled",
                isSecure: values["PASSWORD_AUTH"] == "no"
            ),

            // Services
            HardeningCheck(
                key: "FAIL2BAN", label: "fail2ban Service",
                description: "Brute force protection and intrusion prevention",
                icon: "hand.raised.fill", category: .services, severity: .critical,
                currentValue: values["FAIL2BAN"] == "active" ? "Active" : "Inactive",
                isSecure: values["FAIL2BAN"] == "active"
            ),
        ]
    }

    private func aslrLabel(_ value: String) -> String {
        switch value {
        case "0": return "Disabled"
        case "1": return "Partial"
        case "2": return "Full"
        default: return value
        }
    }

    private func rootLoginLabel(_ value: String) -> String {
        switch value {
        case "yes": return "Allowed (Insecure)"
        case "without-password": return "Keys Only"
        case "no": return "Disabled"
        default: return value
        }
    }

    // MARK: - Compliance Card

    private var complianceCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.xxxl) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color.axBorder, lineWidth: 6)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: isLoading ? 0 : CGFloat(complianceScore) / 100.0)
                        .stroke(
                            complianceScore >= 80 ? Color.axSuccess :
                            complianceScore >= 50 ? Color.axWarning : Color.axError,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: complianceScore)

                    VStack(spacing: 0) {
                        if isLoading {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Text("\(complianceScore)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.axTextPrimary)
                            Text("%")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Security Compliance")
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)

                    Text("Based on kernel parameters, SSH config, and security services")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)

                    if !isLoading {
                        HStack(spacing: AXSpacing.lg) {
                            miniStat(label: "Secure", value: "\(checks.filter(\.isSecure).count)", color: .axSuccess)
                            miniStat(label: "Needs Attention", value: "\(checks.filter { !$0.isSecure }.count)", color: .axWarning)
                            miniStat(label: "Critical", value: "\(criticalPending)", color: .axError)
                        }
                    }
                }

                Spacer()

                Button(action: {
                    Task { await loadData() }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("Re-scan")
                            .font(AXTypography.headline)
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(value) \(label)")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        HStack(spacing: AXSpacing.sm) {
            filterButton(label: "All", isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }
            ForEach(HardeningCheck.Category.allCases, id: \.self) { cat in
                filterButton(label: cat.rawValue, isSelected: selectedCategory == cat) {
                    selectedCategory = cat
                }
            }
            Spacer()
        }
    }

    private func filterButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        }) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(isSelected ? .axTextPrimary : .axTextMuted)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(isSelected ? Color.axAccentBlue.opacity(0.3) : Color.axBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
            Text("Scanning system security…")
                .font(AXTypography.body)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }

    // MARK: - Category Section

    private func categorySection(category: HardeningCheck.Category, items: [HardeningCheck]) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: categoryIcon(category))
                        .font(.system(size: 16))
                        .foregroundColor(.axAccentBlue)
                    Text(category.rawValue)
                        .font(AXTypography.title3)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    let secure = items.filter(\.isSecure).count
                    Text("\(secure)/\(items.count) secure")
                        .font(AXTypography.caption)
                        .foregroundColor(secure == items.count ? .axSuccess : .axTextMuted)
                }

                Divider().background(Color.axBorder)

                ForEach(items) { item in
                    hardeningRow(item: item)
                }
            }
        }
    }

    private func hardeningRow(item: HardeningCheck) -> some View {
        HStack(spacing: AXSpacing.md) {
            // Status
            Image(systemName: item.isSecure ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(item.isSecure ? .axSuccess : item.severity.color)

            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundColor(item.isSecure ? .axAccentBlue : .axTextMuted)
                .frame(width: 24)

            // Info
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(item.label)
                        .font(AXTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)

                    Text(item.severity.label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                                .fill(item.severity.color)
                        )
                }

                Text(item.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Current value
            Text(item.currentValue)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(item.isSecure ? .axAccentGreen : .axWarning)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxxs)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(item.isSecure ? Color.axAccentGreen.opacity(0.1) : Color.axWarning.opacity(0.1))
                )
        }
        .padding(.vertical, AXSpacing.xxs)
    }

    // MARK: - Helpers

    private func categoryIcon(_ category: HardeningCheck.Category) -> String {
        switch category {
        case .kernel: return "cpu"
        case .network: return "network"
        case .ssh: return "terminal.fill"
        case .services: return "gearshape.2.fill"
        }
    }
}
