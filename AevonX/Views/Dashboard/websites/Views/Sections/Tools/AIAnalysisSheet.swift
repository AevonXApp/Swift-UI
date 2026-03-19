//
//  AIAnalysisSheet.swift
//  AevonX
//
//  AI-powered log analysis sheet — health score, stats grid,
//  HTTP status distribution, and insights.
//

import SwiftUI
import AevonXCoreBridge

struct AIAnalysisSheet: View {
    @ObservedObject var viewModel: EnhancedLogsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider().background(Color.axBorder.opacity(0.3))
            sheetContent
        }
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "brain")
                    .font(AXTypography.title2)
                    .foregroundColor(.axAccentBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Log Analysis")
                        .font(AXTypography.title3).fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    Text(viewModel.domain)
                        .font(AXTypography.monoSm)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            if viewModel.aiAnalysis != nil {
                Button(action: copyReport) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy Report")
                    }
                    .font(AXTypography.footnote).fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(copied ? .green : .axAccentBlue)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.4))
    }

    // MARK: - Content

    @ViewBuilder
    private var sheetContent: some View {
        if viewModel.isAnalyzing {
            Spacer()
            VStack(spacing: AXSpacing.lg) {
                ProgressView().scaleEffect(1.5)
                Text("Analyzing log patterns...")
                    .font(AXTypography.body).fontWeight(.medium)
                    .foregroundColor(.axTextSecondary)
                Text("\(viewModel.logLines.count) log entries")
                    .font(AXTypography.monoMd)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        } else if let analysis = viewModel.aiAnalysis {
            ScrollView {
                VStack(spacing: AXSpacing.lg) {
                    healthCard(analysis)
                    statsGrid(analysis)

                    if !analysis.statusDistribution.isEmpty {
                        statusSection(analysis.statusDistribution)
                    }
                    if !analysis.insights.isEmpty {
                        insightsSection(analysis.insights)
                    }
                }
                .padding(AXSpacing.lg)
            }
        } else {
            Spacer()
            VStack(spacing: AXSpacing.md) {
                Image(systemName: "waveform.path.ecg")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextMuted.opacity(0.4))
                Text("No analysis data")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextMuted)
                Button("Run Analysis") {
                    Task { await viewModel.runSmartAnalysis() }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
    }

    // MARK: - Health Card

    private func healthCard(_ analysis: LogAIAnalysis) -> some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(Color.axBorder.opacity(0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: Double(analysis.healthScore) / 100)
                    .stroke(
                        analysis.healthScore >= 80 ? Color.green :
                        analysis.healthScore >= 50 ? Color.orange : Color.red,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(analysis.healthScore)")
                        .font(AXTypography.title).fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    Text("%")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Health Score")
                    .font(AXTypography.headline).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text("Based on \(analysis.totalRequests) requests — \(analysis.errorCount) errors, \(analysis.warningCount) warnings")
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Stats Grid

    private func statsGrid(_ analysis: LogAIAnalysis) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: AXSpacing.md) {
            statCard(icon: "doc.text.fill", value: "\(analysis.totalRequests)", label: "Requests", color: .axAccentBlue)
            statCard(icon: "person.2.fill", value: "\(analysis.uniqueIPs)", label: "Unique IPs", color: .purple)
            statCard(icon: "xmark.circle.fill", value: "\(analysis.errorCount)", label: "Errors", color: .red)
            statCard(icon: "exclamationmark.triangle.fill", value: "\(analysis.warningCount)", label: "Warnings", color: .orange)
            statCard(icon: "ant.fill", value: "\(analysis.botCount)", label: "Bots", color: .axTextMuted)
            statCard(icon: "checkmark.shield.fill", value: "\(analysis.healthScore)%", label: "Health", color: analysis.healthScore >= 80 ? .green : .orange)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(AXTypography.title3)
                .foregroundColor(color)
            Text(value)
                .font(AXTypography.title2).fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.md)
        .background(color.opacity(0.05))
        .cornerRadius(AXCornerRadius.sm)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(color.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Status Distribution

    private func statusSection(_ stats: [LogStatusStat]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("HTTP Status Distribution")
                .font(AXTypography.callout).fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.sm) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        Text("\(stat.count)")
                            .font(AXTypography.title2).fontWeight(.bold)
                            .foregroundColor(stat.color)
                        Text(stat.code)
                            .font(AXTypography.monoSm).fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        Text(statusLabel(stat.code))
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(stat.color.opacity(0.06))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.2))
        .cornerRadius(AXCornerRadius.md)
    }

    private func statusLabel(_ code: String) -> String {
        switch code {
        case "200": return "OK"
        case "301": return "Redirect"
        case "302": return "Found"
        case "304": return "Not Modified"
        case "400": return "Bad Request"
        case "401": return "Unauthorized"
        case "403": return "Forbidden"
        case "404": return "Not Found"
        case "500": return "Server Error"
        case "502": return "Bad Gateway"
        case "503": return "Unavailable"
        default: return ""
        }
    }

    // MARK: - Insights

    private func insightsSection(_ insights: [LogInsight]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Insights")
                .font(AXTypography.callout).fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            ForEach(insights) { insight in
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: insight.icon)
                        .font(AXTypography.title3)
                        .foregroundColor(insight.level.color)
                        .frame(width: 30, height: 30)
                        .background(insight.level.color.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(AXTypography.subheadline).fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        Text(insight.detail)
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextTertiary)
                    }

                    Spacer()
                }
                .padding(AXSpacing.sm)
                .background(insight.level.color.opacity(0.03))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(insight.level.color.opacity(0.1), lineWidth: 1))
            }
        }
    }

    // MARK: - Copy

    private func copyReport() {
        let report = viewModel.generateReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }
}
