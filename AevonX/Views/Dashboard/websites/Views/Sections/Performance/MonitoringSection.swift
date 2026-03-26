//
//  MonitoringSection.swift
//  AevonX
//
//  Per-site monitoring and analytics section
//

import SwiftUI
import AevonXCoreBridge

struct MonitoringSection: View {
    @ObservedObject var viewModel: MonitoringViewModel
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack {
                    AXSectionTitle(title: "Monitoring", icon: "chart.xyaxis.line")
                    Spacer()
                    Button(action: { Task { await viewModel.loadAll() } }) {
                        HStack(spacing: 4) {
                            if viewModel.isLoading {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(L10n.Button.refresh)
                        }
                        .font(AXTypography.subheadline).fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Tab selector
                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(MonitoringTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch viewModel.selectedTab {
                case .health: healthView
                case .traffic: trafficView
                case .errors: errorsView
                case .bandwidth: bandwidthView
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadAll() } }
    }

    // MARK: - Health

    private var healthView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            if let check = viewModel.healthCheck {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    AXStatCard(icon: "circle.fill", label: "Status", value: check.isUp ? L10n.Status.online : L10n.Status.offline, color: check.isUp ? .axSuccess : .axError)
                    AXStatCard(icon: "clock", label: "Response Time", value: check.formattedResponseTime, color: (check.responseTime ?? 0) < 1.0 ? .axSuccess : .axWarning)
                    AXStatCard(icon: "number", label: "HTTP Code", value: check.httpStatus.map { "\($0)" } ?? "N/A", color: (check.httpStatus ?? 0) < 400 ? .axSuccess : .axError)
                    AXStatCard(icon: "lock.shield", label: "SSL Expires", value: check.sslDaysRemaining.map { "\($0)d" } ?? "N/A", color: (check.sslDaysRemaining ?? 999) > 30 ? .axSuccess : .axWarning)
                }

                HStack(spacing: AXSpacing.md) {
                    infoChip(icon: "network", label: "DNS", value: check.dnsResolved ? "Resolved" : "Failed", color: check.dnsResolved ? .axSuccess : .axError)
                    infoChip(icon: "clock", label: "Checked", value: check.timestamp.formatted(date: .omitted, time: .shortened), color: .axAccentBlue)
                    Spacer()
                    Button("Run Check") { Task { await viewModel.runHealthCheck() } }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            } else {
                EmptyStateCard(icon: "heart", title: "Health Check", message: "Click Refresh to run a health check")
            }
        }
    }

    // MARK: - Traffic

    private var trafficView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            if !viewModel.topURLs.isEmpty {
                AXConfigCard(icon: "link", title: "Top URLs", subtitle: "Most requested URLs from access log") {
                    VStack(spacing: AXSpacing.xs) {
                        ForEach(viewModel.topURLs.prefix(15)) { entry in
                            HStack {
                                Text(entry.url)
                                    .font(AXTypography.monoMd)
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(entry.count)")
                                    .font(AXTypography.subheadline).fontWeight(.bold)
                                    .foregroundColor(.axAccentBlue)
                                Text(String(format: "%.1f%%", entry.percentage))
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                                    .frame(width: 45, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            if !viewModel.topIPs.isEmpty {
                AXConfigCard(icon: "person.2", title: "Top IPs", subtitle: "Most active client IPs") {
                    VStack(spacing: AXSpacing.xs) {
                        ForEach(viewModel.topIPs.prefix(10)) { entry in
                            HStack {
                                Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(entry.ip) : entry.ip)
                                    .font(AXTypography.monoMd)
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                                Text("\(entry.count) requests")
                                    .font(AXTypography.footnote)
                                    .foregroundColor(.axTextSecondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            if !viewModel.botTraffic.isEmpty {
                AXConfigCard(icon: "ant", title: "Bot Traffic", subtitle: "Detected bot user agents") {
                    VStack(spacing: AXSpacing.xs) {
                        ForEach(viewModel.botTraffic) { bot in
                            HStack {
                                Circle().fill(bot.color).frame(width: 6, height: 6)
                                Text(bot.botName)
                                    .font(AXTypography.footnote)
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(bot.requestCount)")
                                    .font(AXTypography.footnote).fontWeight(.bold)
                                    .foregroundColor(.axTextSecondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            if viewModel.topURLs.isEmpty && viewModel.topIPs.isEmpty {
                EmptyStateCard(icon: "chart.bar", title: "No Traffic Data", message: "Access log may be empty or not found")
            }
        }
    }

    // MARK: - Errors

    private var errorsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            if !viewModel.statusCodes.isEmpty {
                AXConfigCard(icon: "number", title: "Status Code Distribution", subtitle: "HTTP response codes from access log") {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.statusCodes) { entry in
                            HStack {
                                Text("\(entry.code)")
                                    .font(AXTypography.monoLg).fontWeight(.bold)
                                    .foregroundColor(entry.color)
                                    .frame(width: 40)
                                Text(entry.category)
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(entry.color.opacity(0.3))
                                        .frame(width: geo.size.width * CGFloat(entry.percentage / 100), height: 16)
                                        .animation(.easeOut, value: entry.percentage)
                                }
                                .frame(width: 120, height: 16)
                                Text("\(entry.count)")
                                    .font(AXTypography.subheadline).fontWeight(.semibold)
                                    .foregroundColor(.axTextPrimary)
                                    .frame(width: 60, alignment: .trailing)
                                Text(String(format: "%.1f%%", entry.percentage))
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                                    .frame(width: 45, alignment: .trailing)
                            }
                        }
                    }
                }
            } else {
                EmptyStateCard(icon: "exclamationmark.triangle", title: "No Status Data", message: "Run a refresh to analyze the access log")
            }
        }
    }

    // MARK: - Bandwidth

    private var bandwidthView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            if let bw = viewModel.bandwidth {
                AXStatCard(icon: "arrow.up.arrow.down", label: "Total Bandwidth (\(bw.period))", value: bw.formatted, color: .axAccentBlue)
            } else {
                EmptyStateCard(icon: "arrow.up.arrow.down", title: "No Bandwidth Data", message: "Run a refresh to calculate bandwidth usage")
            }
        }
    }

    // MARK: - Chip

    private func infoChip(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(AXTypography.caption).foregroundColor(color)
            Text(label).font(AXTypography.caption).foregroundColor(.axTextTertiary)
            Text(value).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
}
