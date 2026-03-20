//
//  MySQLDoctorSection.swift
//  AevonX
//
//  MySQL health check dashboard — 12 automated checks with score.
//

import SwiftUI
import AevonXCoreBridge

struct MySQLDoctorSection: View {
    let serverId: String

    @State private var checks: [DoctorCheckItem] = []
    @State private var score = 0
    @State private var isLoading = true
    @State private var isRunning = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    struct DoctorCheckItem: Identifiable {
        let id = UUID()
        let name: String
        let status: String
        let message: String
        let detail: String
    }

    var body: some View {
        VStack(spacing: 0) {
            // Score Header
            VStack(spacing: AXSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(Color.axBorder.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: score)
                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        Text("/ 100")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                }
                Text(scoreLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(scoreColor)
            }
            .padding(.vertical, AXSpacing.xl)

            // Run button
            Button {
                Task { await runDoctor() }
            } label: {
                HStack(spacing: AXSpacing.sm) {
                    if isRunning {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "stethoscope")
                    }
                    Text(isRunning ? "Running checks..." : "Run Health Check")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, 10)
                .background(LinearGradient(colors: [.axAccentBlue, Color(red: 0, green: 0.45, blue: 0.9)], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(AXCornerRadius.md)
                .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isRunning)
            .padding(.bottom, AXSpacing.xl)

            // Checks list
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(checks) { check in
                            checkRow(check)
                        }
                    }
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.bottom, AXSpacing.xl)
                }
            }
        }
        .task { await runDoctor() }
    }

    private func checkRow(_ check: DoctorCheckItem) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: statusIcon(check.status))
                .foregroundColor(statusColor(check.status))
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(check.name.capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(check.message)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                if !check.detail.isEmpty && check.status != "ok" {
                    Text(check.detail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(check.status.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(statusColor(check.status))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor(check.status).opacity(0.15))
                .cornerRadius(4)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, 10)
        .background(Color.axSurface)
    }

    private func statusIcon(_ s: String) -> String {
        switch s {
        case "ok":   return "checkmark.circle.fill"
        case "warn": return "exclamationmark.triangle.fill"
        case "fail": return "xmark.circle.fill"
        default:     return "minus.circle"
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "ok":   return .green
        case "warn": return .orange
        case "fail": return .red
        default:     return .axTextMuted
        }
    }

    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        if score >= 40 { return "Needs Attention" }
        return "Critical Issues"
    }

    private func runDoctor() async {
        isRunning = true
        isLoading = checks.isEmpty

        let json = await bridge.runDoctor(serverID: serverId, appID: "mysql")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let report = resp["data"] as? [String: Any] {

            score = (report["score"] as? Int) ?? 0
            if let rawChecks = report["checks"] as? [[String: Any]] {
                checks = rawChecks.map { c in
                    DoctorCheckItem(
                        name: c["name"] as? String ?? "",
                        status: c["status"] as? String ?? "skipped",
                        message: c["message"] as? String ?? "",
                        detail: c["detail"] as? String ?? ""
                    )
                }
            }
        }

        isLoading = false
        isRunning = false
    }
}
