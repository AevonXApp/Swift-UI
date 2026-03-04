//
//  AIAnalysisSheet.swift
//  AevonX
//
//  AI-powered log analysis sheet — health score, stats grid,
//  HTTP status distribution, and insights.
//

import SwiftUI
import AevonXCore

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
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Log Analysis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(viewModel.domain)
                        .font(.system(size: 11, design: .monospaced))
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
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(copied ? .green : .axAccentBlue)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                Text("\(viewModel.logLines.count) log entries")
                    .font(.system(size: 12, design: .monospaced))
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
                    .font(.system(size: 32))
                    .foregroundColor(.axTextMuted.opacity(0.4))
                Text("No analysis data")
                    .font(.system(size: 14))
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
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                    Text("%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Health Score")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text("Based on \(analysis.totalRequests) requests — \(analysis.errorCount) errors, \(analysis.warningCount) warnings")
                    .font(.system(size: 11))
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
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
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
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.sm) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        Text("\(stat.count)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(stat.color)
                        Text(stat.code)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Text(statusLabel(stat.code))
                            .font(.system(size: 9))
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
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.axTextPrimary)

            ForEach(insights) { insight in
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 16))
                        .foregroundColor(insight.level.color)
                        .frame(width: 30, height: 30)
                        .background(insight.level.color.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axTextPrimary)
                        Text(insight.detail)
                            .font(.system(size: 11))
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
