//
//  PHPDoctorSection.swift
//  AevonX
//
//  12-point PHP health check.
//

import SwiftUI
import AevonXCoreBridge

struct PHPDoctorSection: View {
    let serverId: String
    @State private var report: BridgeDoctorReport?
    @State private var isLoading = true

    private let bridge = ApplicationBridge.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "PHP Doctor", icon: "stethoscope")

                if isLoading {
                    VStack(spacing: AXSpacing.md) {
                        AXSkeletonStatCard()
                        ForEach(0..<4, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                } else if let r = report {
                    HStack {
                        ZStack {
                            Circle().stroke(Color.axSurface, lineWidth: 8).frame(width: 80, height: 80)
                            Circle().trim(from: 0, to: Double(r.score) / 100.0)
                                .stroke(scoreColor(r.score), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80).rotationEffect(.degrees(-90))
                            Text("\(r.score)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(scoreColor(r.score))
                        }
                        VStack(alignment: .leading) {
                            Text(L10n.Apps.healthScore).font(.system(size: 16, weight: .bold)).foregroundColor(.axTextPrimary)
                            Text(r.score >= 80 ? "PHP is well configured" :
                                 r.score >= 50 ? "Some improvements needed" : "Critical issues found")
                                .font(AXTypography.caption).foregroundColor(.axTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.4))
                    .cornerRadius(AXCornerRadius.lg)

                    ForEach(r.checks, id: \.name) { check in
                        HStack(spacing: AXSpacing.md) {
                            Image(systemName: statusIcon(check.status))
                                .font(.system(size: 14))
                                .foregroundColor(statusColor(check.status))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(check.name).font(.system(size: 13, weight: .medium)).foregroundColor(.axTextPrimary)
                                Text(check.message).font(.system(size: 11)).foregroundColor(.axTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(AXSpacing.md)
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await runDoctor() }
    }

    private func runDoctor() async {
        let json = await bridge.runDoctor(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<BridgeDoctorReport>.self, from: data),
           r.success { report = r.data }
        isLoading = false
    }

    private func scoreColor(_ s: Int) -> Color {
        s >= 80 ? .axSuccess : (s >= 50 ? .orange : .axError)
    }

    private func statusIcon(_ s: String) -> String {
        switch s {
        case "ok": return "checkmark.circle.fill"
        case "warn": return "exclamationmark.triangle.fill"
        case "fail": return "xmark.circle.fill"
        default: return "minus.circle.fill"
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "ok": return .axSuccess
        case "warn": return .orange
        case "fail": return .axError
        default: return .axTextMuted
        }
    }
}
