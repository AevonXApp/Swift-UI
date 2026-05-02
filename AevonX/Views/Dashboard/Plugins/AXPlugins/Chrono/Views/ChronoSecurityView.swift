//
//  ChronoSecurityView.swift
//  AevonX
//
//  VaultScan + ThreatRadar + DriftDetector + PermissionMatrix.
//

import SwiftUI

struct ChronoSecurityView: View {
    @ObservedObject var viewModel: ChronoViewModel
    @State private var selectedProject: ChronoProject?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                projectPicker
                if let results = viewModel.securityResults {
                    summaryCards(results)
                    secretsSection(results)
                    vulnsSection(results)
                    driftSection(results)
                } else {
                    noProjectState
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadProjects() }
    }

    // MARK: - Header

    private var header: some View {
        Text(L10n.Chrono.Scanner.title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.axTextPrimary)
    }

    // MARK: - Project Picker

    private var projectPicker: some View {
        HStack(spacing: AXSpacing.md) {
            ForEach(viewModel.projects) { project in
                Button {
                    selectedProject = project
                    Task { await viewModel.loadSecurity(projectId: project.id) }
                } label: {
                    Text(project.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedProject?.id == project.id ? .white : .axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.xs)
                        .background(selectedProject?.id == project.id ? Color.axError : Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Summary Cards

    private func summaryCards(_ results: ChronoSecurityResults) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: 4), spacing: AXSpacing.lg) {
            scanCard(L10n.Chrono.Scanner.vaultScan, value: "\(results.secretsFound)", icon: "lock.shield", color: results.secretsFound > 0 ? .axError : .axSuccess)
            scanCard(L10n.Chrono.Scanner.threatRadar, value: "\(results.vulnsFound)", icon: "shield.checkered", color: results.vulnsFound > 0 ? .axWarning : .axSuccess)
            scanCard(L10n.Chrono.Scanner.driftDetector, value: "\(results.driftFiles)", icon: "arrow.triangle.swap", color: results.driftFiles > 0 ? .axWarning : .axSuccess)
            scanCard(L10n.Chrono.Scanner.permissions, value: "\(results.permissionIssues)", icon: "person.badge.key", color: results.permissionIssues > 0 ? .axError : .axSuccess)
        }
    }

    private func scanCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Secrets

    @ViewBuilder
    private func secretsSection(_ results: ChronoSecurityResults) -> some View {
        sectionHeader(L10n.Chrono.Scanner.vaultScan, icon: "lock.shield", color: .axError)

        if results.secrets.isEmpty {
            noIssuesRow(L10n.Chrono.Scanner.noSecrets)
        } else {
            VStack(spacing: AXSpacing.xs) {
                ForEach(results.secrets) { secret in
                    secretRow(secret)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
        }
    }

    private func secretRow(_ secret: ChronoSecretFinding) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(severityColor(secret.severity))
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(secret.type)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                Text("\(secret.file):\(secret.line)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
            Text(secret.severity.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(severityColor(secret.severity))
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, AXSpacing.xxxs)
                .background(severityColor(secret.severity).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, AXSpacing.xs)
    }

    // MARK: - Vulns

    @ViewBuilder
    private func vulnsSection(_ results: ChronoSecurityResults) -> some View {
        sectionHeader(L10n.Chrono.Scanner.threatRadar, icon: "shield.checkered", color: .axWarning)

        if results.vulns.isEmpty {
            noIssuesRow(L10n.Chrono.Scanner.noVulns)
        } else {
            VStack(spacing: AXSpacing.xs) {
                ForEach(results.vulns) { vuln in
                    vulnRow(vuln)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
        }
    }

    private func vulnRow(_ vuln: ChronoVulnFinding) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 11))
                .foregroundColor(severityColor(vuln.severity))
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(vuln.package)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                    Text(vuln.version)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                }
                Text(vuln.advisory)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(vuln.severity.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(severityColor(vuln.severity))
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, AXSpacing.xxxs)
                .background(severityColor(vuln.severity).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, AXSpacing.xs)
    }

    // MARK: - Drift

    @ViewBuilder
    private func driftSection(_ results: ChronoSecurityResults) -> some View {
        sectionHeader(L10n.Chrono.Scanner.driftDetector, icon: "arrow.triangle.swap", color: .axAccentPurple)

        if results.driftedFiles.isEmpty {
            noIssuesRow(L10n.Chrono.Scanner.noSecrets)
        } else {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                ForEach(results.driftedFiles, id: \.self) { file in
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.system(size: 11))
                            .foregroundColor(.axWarning)
                        Text(file)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.axTextPrimary)
        }
    }

    private func noIssuesRow(_ text: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.axSuccess)
                .font(.system(size: 12))
            Text(text)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical", "high": return .axError
        case "medium": return .axWarning
        case "low": return .axAccentBlue
        default: return .axTextMuted
        }
    }

    private var noProjectState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text(L10n.PluginsUI.selectAProjectToScan)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}
