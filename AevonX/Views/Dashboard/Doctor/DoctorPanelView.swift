//
//  DoctorPanelView.swift
//  AevonX
//
//  AX Doctor — diagnostic panel with QuickInstall-style step-by-step fix execution.
//  Reuses AXStepInstallerView for live progress, output, and timer.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Doctor Panel View

/// Slide-up panel showing AX Doctor diagnosis for any error.
public struct DoctorPanelView: View {
    let diagnosis: DoctorDiagnosis
    let serverId: String
    @Environment(\.dismiss) private var dismiss

    /// When user taps "Fix All", we switch to installer mode
    @State private var installerVM: AXStepInstallerViewModel?
    @State private var isFixing = false

    public init(diagnosis: DoctorDiagnosis, serverId: String = "") {
        self.diagnosis = diagnosis
        self.serverId = serverId
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().background(Color.white.opacity(0.1))

            if isFixing, let vm = installerVM {
                // Step-by-step fix execution (same as QuickInstall)
                AXStepInstallerView(
                    viewModel: vm,
                    title: "Fixing: \(diagnosis.title)",
                    icon: "stethoscope",
                    accentColor: .orange,
                    onDismiss: { dismiss() }
                )
            } else {
                // Diagnosis view
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        analysisSection
                        rootCauseSection
                        liveChecksSection
                        solutionsSection
                    }
                    .padding(20)
                }

                Divider().background(Color.white.opacity(0.1))
                footerSection
            }
        }
        .background(Color(red: 0.09, green: 0.09, blue: 0.09))
        .frame(minWidth: 540, minHeight: 420)
        .frame(maxWidth: 640, maxHeight: 600)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("AX DOCTOR")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)

                Text(diagnosis.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(diagnosis.severity.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(severityColor.opacity(0.3))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(severityColor.opacity(0.5), lineWidth: 1))

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
    }

    // MARK: - Analysis

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Analysis", systemImage: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))

            Text(diagnosis.analysis)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
        }
    }

    // MARK: - Root Cause

    private var rootCauseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Root Cause", systemImage: "exclamationmark.triangle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.orange.opacity(0.8))

            Text(diagnosis.rootCause)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.orange.opacity(0.9))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Live Checks (from real SSH output)

    @ViewBuilder
    private var liveChecksSection: some View {
        if let checks = diagnosis.checks, !checks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Server Checks (\(checks.count))", systemImage: "server.rack")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))

                ForEach(Array(checks.enumerated()), id: \.offset) { _, check in
                    HStack(spacing: 10) {
                        Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(check.passed ? .green : .red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))

                            if let detail = check.detail, !detail.isEmpty {
                                Text(detail.prefix(120) + (detail.count > 120 ? "..." : ""))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(2)
                            }
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(check.passed ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke((check.passed ? Color.green : Color.red).opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Solutions

    private var solutionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Solutions (\(diagnosis.solutions.count))", systemImage: "wrench.and.screwdriver")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))

            ForEach(Array(diagnosis.solutions.enumerated()), id: \.element.id) { index, solution in
                DoctorSolutionPreviewRow(solution: solution, index: index + 1)
            }
        }
    }

    // MARK: - Footer (Fix All button)

    private var footerSection: some View {
        HStack {
            let autoCount = diagnosis.solutions.filter { $0.isAutomated && $0.command != nil }.count
            Text("\(autoCount) automated fix\(autoCount == 1 ? "" : "es") available")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))

            Spacer()

            Button(action: startFixAll) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Fix All")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
    }

    // MARK: - Fix All (uses AXStepInstallerView)

    private func startFixAll() {
        let automatedSolutions = diagnosis.solutions.filter { $0.isAutomated && $0.command != nil }
        guard !automatedSolutions.isEmpty else { return }

        // Convert Doctor solutions → AXInstallSteps
        let steps = automatedSolutions.map { sol in
            AXInstallStep(
                title: sol.title,
                description: sol.description,
                icon: stepIcon(for: sol.riskLevel)
            )
        }

        let vm = AXStepInstallerViewModel(steps: steps)
        installerVM = vm
        isFixing = true

        // Execute each step via SSH
        Task {
            await vm.run(serverId: serverId) { step, sid in
                // Find matching solution by title
                guard let solution = automatedSolutions.first(where: { $0.title == step.title }),
                      let command = solution.command else {
                    throw NSError(domain: "Doctor", code: 1, userInfo: [NSLocalizedDescriptionKey: "No command for step"])
                }

                print("[AX Doctor] Executing fix: \(command.prefix(100))")

                // Run SSH on a detached task with 120s timeout
                let output: String = try await withThrowingTaskGroup(of: String.self) { group in
                    group.addTask {
                        await withCheckedContinuation { continuation in
                            Task.detached {
                                let result = await SSHBridge.shared.executeAsync(serverID: sid, command: command)
                                continuation.resume(returning: result)
                            }
                        }
                    }
                    group.addTask {
                        try await Task.sleep(nanoseconds: 120_000_000_000) // 120 seconds
                        throw NSError(domain: "Doctor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Command timed out after 120 seconds"])
                    }
                    // First to finish wins
                    let result = try await group.next()!
                    group.cancelAll()
                    return result
                }

                print("[AX Doctor] Fix output (\(output.count) chars): \(output.prefix(200))")

                // Check for errors in output — comprehensive patterns
                let lower = output.lowercased()
                let errorPatterns = [
                    "e: unable to locate",
                    "command not found",
                    "permission denied",
                    "not permitted",
                    "failed to start",
                    "failed to stop",
                    "failed to restart",
                    "no such file",
                    "unable to locate package",
                    "no process manager"
                ]
                let hasError = errorPatterns.contains { lower.contains($0) }

                if hasError {
                    throw NSError(domain: "Doctor", code: 2, userInfo: [NSLocalizedDescriptionKey: output])
                }

                return output.isEmpty ? "ok" : String(output.prefix(300))
            }
        }
    }

    // MARK: - Helpers

    private func stepIcon(for riskLevel: String) -> String {
        switch riskLevel {
        case "safe": return "shield.checkered"
        case "moderate": return "wrench.and.screwdriver"
        case "dangerous": return "exclamationmark.triangle"
        default: return "questionmark.circle"
        }
    }

    private var severityIcon: String {
        switch diagnosis.severity {
        case "critical": return "xmark.octagon.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch diagnosis.severity {
        case "critical": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
}

// MARK: - Solution Preview Row (read-only, no execute button)

struct DoctorSolutionPreviewRow: View {
    let solution: DoctorSolution
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            commandPreview
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(riskColor.opacity(0.5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(solution.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text(solution.riskLevel)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(riskColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(riskColor.opacity(0.15))
                        .clipShape(Capsule())

                    if solution.isAutomated {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange.opacity(0.6))
                    }
                }

                if !solution.description.isEmpty {
                    Text(solution.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(2)
                }
            }
        }
    }

    @ViewBuilder
    private var commandPreview: some View {
        if let command = solution.command, !command.isEmpty {
            Text(command)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)
        }
    }

    private var riskColor: Color {
        switch solution.riskLevel {
        case "safe": return .green
        case "moderate": return .orange
        case "dangerous": return .red
        default: return .gray
        }
    }
}
