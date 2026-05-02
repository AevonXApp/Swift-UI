//
//  LiteSpeedDoctorSection.swift
//  AevonX
//
//  12-point health check & performance score for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedDoctorSection: View {
    let serverId: String

    @State private var report: BridgeDoctorReport?
    @State private var isLoading = false

    private let bridge = ApplicationBridge.shared
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                if let report = report {
                    scoreCard(report)
                }
                doctorToolbar
                checksListView
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Toolbar

    private var doctorToolbar: some View {
        HStack {
            AXSectionTitle(title: "Health Checks", icon: "stethoscope")
            Spacer()
            Button {
                Task { await runDoctor() }
            } label: {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "play.fill").font(AXTypography.caption)
                    }
                    Text(report == nil ? "Run Doctor" : "Re-run")
                        .font(AXTypography.footnote).fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md).padding(.vertical, 5)
                .background(lsGreen)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
        }
    }

    // MARK: - Checks List

    @ViewBuilder
    private var checksListView: some View {
        if let report = report {
            VStack(spacing: AXSpacing.xs) {
                ForEach(report.checks, id: \.name) { check in
                    checkRow(check)
                }
            }
        } else if !isLoading {
            emptyState
        }
    }

    private func checkRow(_ check: BridgeDoctorCheck) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: statusIcon(check.status))
                .font(AXTypography.headline)
                .foregroundColor(statusColor(check.status))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(check.name.capitalized)
                    .font(AXTypography.subheadline).fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                Text(check.message)
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextSecondary)
                if let detail = check.detail, !detail.isEmpty {
                    Text(detail)
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextMuted)
                }
            }
            Spacer()
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(statusColor(check.status).opacity(0.15), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            Image(systemName: "stethoscope").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
            Text(L10n.Label.liteSpeedDoctorHint).font(AXTypography.callout).foregroundColor(.axTextMuted)
            Spacer()
        }.frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
    }

    // MARK: - Score Card

    private func scoreCard(_ report: BridgeDoctorReport) -> some View {
        HStack(spacing: AXSpacing.xl) {
            ZStack {
                Circle()
                    .stroke(Color.axBorder.opacity(0.15), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: CGFloat(report.score) / 100.0)
                    .stroke(scoreColor(report.score), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                Text("\(report.score)")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextPrimary)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(L10n.Apps.healthScore)
                    .font(AXTypography.title3).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text(scoreLabel(report.score))
                    .font(AXTypography.subheadline).fontWeight(.medium)
                    .foregroundColor(scoreColor(report.score))
                Text("\(report.checks.count) checks completed")
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
        .padding(AXSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(scoreColor(report.score).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(scoreColor(report.score).opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func runDoctor() async {
        isLoading = true
        let json = await bridge.runDoctor(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<BridgeDoctorReport>.self, from: data),
           resp.success {
            withAnimation(.easeOut(duration: 0.3)) {
                report = resp.data
            }
        }
        isLoading = false
    }

    // MARK: - Helpers

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "ok": return "checkmark.circle.fill"
        case "warn": return "exclamationmark.triangle.fill"
        case "fail": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "ok": return .axSuccess
        case "warn": return .axWarning
        case "fail": return .axError
        default: return .axTextMuted
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .axSuccess }
        if score >= 60 { return .axWarning }
        return .axError
    }

    private func scoreLabel(_ score: Int) -> String {
        if score >= 90 { return "Excellent" }
        if score >= 80 { return "Good" }
        if score >= 60 { return "Needs Improvement" }
        return "Critical"
    }
}
