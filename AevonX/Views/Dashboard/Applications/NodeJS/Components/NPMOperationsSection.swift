//
//  NPMOperationsSection.swift
//  AevonX
//
//  NPM/Yarn/PNPM/Bun package management operations.
//  Install, update, audit, outdated, cache, global packages.
//

import SwiftUI
import AevonXCoreBridge

struct NPMOperationsSection: View {
    let serverId: String
    let appPath: String?

    @State private var packageManager: String = "npm"
    @State private var globalPackages: [String] = []
    @State private var outdatedPackages: [OutdatedPackage] = []
    @State private var isLoading = true
    @State private var operationOutput: String = ""
    @State private var showOutput = false
    @State private var runningOp: String?

    private let deployService = NodeJSDeployService()

    struct OutdatedPackage: Identifiable {
        let id = UUID()
        let name: String
        let current: String
        let wanted: String
        let latest: String
    }

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Package Manager Info
            AXCard {
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "#CB3837").opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#CB3837"))
                        }
                        Text("Package Manager")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 10))
                        Text(packageManager)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }

            // Operations Grid
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "#339933").opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#339933"))
                        }
                        Text("Operations")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AXSpacing.sm) {
                        npmButton(title: "Install", icon: "arrow.down.circle", color: Color(hex: "#339933")) {
                            await runNPMCommand("install")
                        }
                        npmButton(title: "Update", icon: "arrow.up.circle", color: .axAccentBlue) {
                            await runNPMCommand("update")
                        }
                        npmButton(title: "Audit", icon: "shield.checkered", color: .axWarning) {
                            await runNPMCommand("audit")
                        }
                        npmButton(title: "Outdated", icon: "exclamationmark.triangle", color: Color(hex: "#E07C24")) {
                            await checkOutdated()
                        }
                        npmButton(title: "Clean Cache", icon: "trash", color: .axError) {
                            await runNPMCommand("cache clean --force")
                        }
                        npmButton(title: "Audit Fix", icon: "wrench.and.screwdriver", color: .axSuccess) {
                            await runNPMCommand("audit fix")
                        }
                        npmButton(title: "Prune", icon: "scissors", color: .axTextSecondary) {
                            await runNPMCommand("prune")
                        }
                        npmButton(title: "Dedupe", icon: "arrow.triangle.merge", color: Color(hex: "#8B5CF6")) {
                            await runNPMCommand("dedupe")
                        }
                    }
                }
            }

            // Outdated Packages
            if !outdatedPackages.isEmpty {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack {
                            HStack(spacing: AXSpacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.axWarning.opacity(0.12))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.axWarning)
                            }
                            Text("Outdated Packages")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                        }
                            Spacer()
                            Text("\(outdatedPackages.count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.axWarning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.axWarning.opacity(0.1))
                                .cornerRadius(4)
                        }

                        // Header
                        HStack {
                            Text("Package")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Current")
                                .frame(width: 70)
                            Text("Wanted")
                                .frame(width: 70)
                            Text("Latest")
                                .frame(width: 70)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.axTextMuted)

                        ForEach(outdatedPackages) { pkg in
                            HStack {
                                Text(pkg.name)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(pkg.current)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axError)
                                    .frame(width: 70)
                                Text(pkg.wanted)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axWarning)
                                    .frame(width: 70)
                                Text(pkg.latest)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axSuccess)
                                    .frame(width: 70)
                            }
                        }
                    }
                }
            }

            // Global Packages
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        HStack(spacing: AXSpacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#8B5CF6").opacity(0.12))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "globe")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#8B5CF6"))
                            }
                            Text("Global Packages")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                        }
                        Spacer()
                        Button {
                            Task { await loadGlobalPackages() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(.plain)
                    }

                    if globalPackages.isEmpty {
                        Text("No global packages detected or loading…")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AXSpacing.sm) {
                                ForEach(globalPackages, id: \.self) { pkg in
                                    Text(pkg)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axTextSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.axSurface)
                                        .cornerRadius(AXCornerRadius.sm)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
            }

            // Output
            if showOutput && !operationOutput.isEmpty {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack {
                            HStack(spacing: AXSpacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.axTextSecondary.opacity(0.12))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.axTextSecondary)
                            }
                            Text("Output")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                        }
                        Spacer()
                        Button { showOutput = false; operationOutput = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(.plain)
                    }

                    ScrollView {
                        Text(operationOutput)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#4EC9B0"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 250)
                    .padding(AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
                    }
                }
            }
        }
        .task { await loadData() }
    }

    private func npmButton(title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: runningOp == title ? "hourglass" : icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(color.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(runningOp != nil)
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        if let path = appPath {
            packageManager = ((try? await deployService.detectPackageManager(path: path, serverId: serverId)) ?? .npm).rawValue
        }
        await loadGlobalPackages()
        isLoading = false
    }

    private func loadGlobalPackages() async {
        let ssh = SSHService.shared
        let result = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; npm list -g --depth=0 2>/dev/null | tail -n +2 | sed 's/[├─└│ ]//g' | grep -v '^$'",
            serverId: serverId
        )
        globalPackages = result?.stdout
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
    }

    private func runNPMCommand(_ command: String) async {
        runningOp = command
        showOutput = true
        let ssh = SSHService.shared
        let fullCmd: String
        if let path = appPath {
            fullCmd = "source ~/.nvm/nvm.sh 2>/dev/null; cd \"\(path)\" && npm \(command) 2>&1"
        } else {
            fullCmd = "source ~/.nvm/nvm.sh 2>/dev/null; npm \(command) 2>&1"
        }
        let result = try? await ssh.execute(fullCmd, serverId: serverId)
        operationOutput = result?.stdout ?? "No output"
        runningOp = nil

        if command == "install" || command == "update" {
            GlobalToastManager.shared.showSuccess("NPM \(command) complete")
        }
    }

    private func checkOutdated() async {
        runningOp = "Outdated"
        let ssh = SSHService.shared
        guard let path = appPath else { runningOp = nil; return }
        let result = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; cd \"\(path)\" && npm outdated --parseable 2>/dev/null || true",
            serverId: serverId
        )

        outdatedPackages = (result?.stdout ?? "")
            .split(separator: "\n")
            .compactMap { line -> OutdatedPackage? in
                let parts = String(line).split(separator: ":").map { String($0) }
                guard parts.count >= 4 else { return nil }
                let name = parts[3].split(separator: "@").first.map(String.init) ?? parts[3]
                return OutdatedPackage(
                    name: name,
                    current: parts.count > 1 ? String(parts[1].split(separator: "@").last ?? "") : "?",
                    wanted: parts.count > 2 ? String(parts[2].split(separator: "@").last ?? "") : "?",
                    latest: parts.count > 3 ? String(parts[3].split(separator: "@").last ?? "") : "?"
                )
            }
        runningOp = nil
    }
}
