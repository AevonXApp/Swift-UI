//
//  NodeJSConfigTab.swift
//  AevonX
//
//  Node.js runtime configuration tab for website detail view.
//  Version management, entry file, port, npm scripts, and dependencies.
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - ViewModel

@MainActor
final class NodeJSConfigViewModel: ObservableObject {
    @Published var currentVersion: String?
    @Published var npmVersion: String?
    @Published var installedVersions: [String] = []
    @Published var availableVersions: [String] = []
    @Published var packageInfo: PackageJSON?
    @Published var entryFile: String = "index.js"
    @Published var appPort: Int = 3000
    @Published var isLoading = true
    @Published var isInstallingVersion = false
    @Published var npmScriptOutput: String?
    @Published var isRunningScript = false
    @Published var hasNvm = false
    
    let serverId: String?
    let appPath: String
    
    private let versionService = NodeJSVersionService()
    private let configService = NodeJSConfigService()
    
    // Step installer for version actions
    @Published var installerVM = AXStepInstallerViewModel(steps: [])
    @Published var showInstaller = false
    @Published var installerTitle = ""
    
    init(serverId: String?, appPath: String) {
        self.serverId = serverId
        self.appPath = appPath
    }
    
    func loadAll() async {
        guard let serverId = serverId else { return }
        isLoading = true
        
        do {
            async let version = versionService.detectCurrentVersion(serverId: serverId)
            async let npm = versionService.detectNPMVersion(serverId: serverId)
            async let installed = versionService.getInstalledVersions(serverId: serverId)
            async let nvm = versionService.isNvmInstalled(serverId: serverId)
            async let pkg = configService.readPackageJSON(appPath: appPath, serverId: serverId)
            async let entry = configService.detectEntryFile(appPath: appPath, serverId: serverId)
            
            currentVersion = try await version
            npmVersion = try await npm
            installedVersions = try await installed
            hasNvm = try await nvm
            packageInfo = try await pkg
            entryFile = try await entry
        } catch {
            CoreLogger.shared.error("Failed to load Node.js config: \(error)", module: "NodeJSConfigTab")
        }
        
        isLoading = false
    }
    
    func installVersion(_ version: String) async {
        guard let serverId = serverId else { return }
        
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Check nvm", description: "Verifying nvm is installed", icon: "magnifyingglass"),
            AXInstallStep(title: "Install Node.js \(version)", description: "Downloading and installing via nvm", icon: "shippingbox"),
            AXInstallStep(title: "Verify Installation", description: "Confirming Node.js \(version) is ready", icon: "checkmark.shield"),
        ]
        
        installerVM.steps = steps
        installerTitle = "Installing Node.js \(version)"
        showInstaller = true
        
        await installerVM.run(serverId: serverId) { [versionService] step, sid in
            switch step.title {
            case "Check nvm":
                let hasNvm = try await versionService.isNvmInstalled(serverId: sid)
                if !hasNvm {
                    try await versionService.installNvm(serverId: sid)
                    return "nvm installed"
                }
                return "nvm ready"
            case let t where t.starts(with: "Install Node"):
                try await versionService.installVersion(version, serverId: sid)
                return "Installed"
            case "Verify Installation":
                let current = try await versionService.detectCurrentVersion(serverId: sid)
                return current ?? "Installed"
            default: return nil
            }
        }
    }
    
    func switchVersion(_ version: String) async {
        guard let serverId = serverId else { return }
        
        do {
            try await versionService.switchVersion(version, serverId: serverId)
            currentVersion = version
            GlobalToastManager.shared.showSuccess("Switched to Node.js \(version)")
        } catch {
            GlobalToastManager.shared.showError("Switch failed: \(error.localizedDescription)")
        }
    }
    
    func runNpmScript(_ script: String) async {
        guard let serverId = serverId else { return }
        isRunningScript = true
        npmScriptOutput = nil
        
        do {
            let output = try await configService.npmRun(script: script, appPath: appPath, serverId: serverId)
            npmScriptOutput = output
        } catch {
            npmScriptOutput = "Error: \(error.localizedDescription)"
        }
        
        isRunningScript = false
    }
}

// MARK: - View

struct NodeJSConfigTab: View {
    @StateObject var viewModel: NodeJSConfigViewModel
    
    init(serverId: String?, appPath: String) {
        _viewModel = StateObject(wrappedValue: NodeJSConfigViewModel(serverId: serverId, appPath: appPath))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Detecting Node.js configuration...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else if viewModel.showInstaller {
                AXStepInstallerView(
                    viewModel: viewModel.installerVM,
                    title: viewModel.installerTitle,
                    icon: "terminal.fill",
                    accentColor: .axSuccess,
                    onDismiss: {
                        viewModel.showInstaller = false
                        Task { await viewModel.loadAll() }
                    }
                )
                .padding(AXSpacing.xl)
            } else {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Version Info
                    versionCard
                    
                    // Package.json Info
                    if let pkg = viewModel.packageInfo {
                        packageInfoCard(pkg)
                    }
                    
                    // NPM Scripts
                    if let scripts = viewModel.packageInfo?.scripts, !scripts.isEmpty {
                        npmScriptsCard(scripts)
                    }
                    
                    // Installed Versions
                    if !viewModel.installedVersions.isEmpty {
                        installedVersionsCard
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }
    
    // MARK: - Version Card
    
    private var versionCard: some View {
        AXConfigCard(
            icon: "terminal",
            title: "Node.js Runtime",
            subtitle: "Current Node.js and NPM versions"
        ) {
            HStack(spacing: AXSpacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Node.js")
                        .font(AXTypography.footnote).fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                    Text(viewModel.currentVersion ?? "Not detected")
                        .font(AXTypography.title2).fontWeight(.bold)
                        .foregroundColor(viewModel.currentVersion != nil ? .axSuccess : .axWarning)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("NPM")
                        .font(AXTypography.footnote).fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                    Text(viewModel.npmVersion ?? "N/A")
                        .font(AXTypography.title2).fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("nvm")
                        .font(AXTypography.footnote).fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.hasNvm ? Color.axSuccess : Color.axError)
                            .frame(width: 8, height: 8)
                        Text(viewModel.hasNvm ? "Installed" : "Not found")
                            .font(AXTypography.callout).fontWeight(.medium)
                            .foregroundColor(viewModel.hasNvm ? .axSuccess : .axError)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Package Info Card
    
    private func packageInfoCard(_ pkg: PackageJSON) -> some View {
        AXConfigCard(
            icon: "doc.text.fill",
            title: "package.json",
            subtitle: pkg.name ?? "Application info"
        ) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.xl) {
                    infoItem("Name", value: pkg.name ?? "—")
                    infoItem("Version", value: pkg.version ?? "—")
                    infoItem("Entry", value: viewModel.entryFile)
                    infoItem("Dependencies", value: "\(pkg.dependencyCount)")
                }
                
                if let desc = pkg.description {
                    Text(desc)
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextTertiary)
                }
                
                if let engine = pkg.engines?.node {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(AXTypography.caption)
                        Text("Requires Node.js \(engine)")
                            .font(AXTypography.footnote).fontWeight(.medium)
                    }
                    .foregroundColor(.axWarning)
                }
            }
        }
    }
    
    private func infoItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            Text(value)
                .font(AXTypography.monoMd).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
        }
    }
    
    // MARK: - NPM Scripts Card
    
    private func npmScriptsCard(_ scripts: [String: String]) -> some View {
        AXConfigCard(
            icon: "play.circle.fill",
            title: "NPM Scripts",
            subtitle: "Available npm run commands"
        ) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(scripts.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text("npm run \(key)")
                            .font(AXTypography.monoMd).fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("→ \(value)")
                            .font(AXTypography.monoSm)
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button(action: { Task { await viewModel.runNpmScript(key) } }) {
                            Image(systemName: "play.fill")
                                .font(AXTypography.caption)
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Color.axSuccess)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isRunningScript)
                    }
                    .padding(.vertical, 4)
                }
                
                // Script output
                if let output = viewModel.npmScriptOutput {
                    Divider().padding(.vertical, AXSpacing.xs)
                    Text(output)
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AXSpacing.sm)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                        .lineLimit(10)
                }
            }
        }
    }
    
    // MARK: - Installed Versions Card
    
    private var installedVersionsCard: some View {
        AXConfigCard(
            icon: "list.bullet",
            title: "Installed Versions",
            subtitle: "Node.js versions available via nvm"
        ) {
            VStack(spacing: AXSpacing.xs) {
                ForEach(viewModel.installedVersions, id: \.self) { version in
                    HStack {
                        Image(systemName: "terminal")
                            .font(AXTypography.caption)
                            .foregroundColor(.axAccentBlue)
                        
                        Text("v\(version)")
                            .font(AXTypography.monoMd)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        if version == viewModel.currentVersion || viewModel.currentVersion?.hasPrefix(version) == true {
                            Text(L10n.Status.active)
                                .font(AXTypography.caption).fontWeight(.semibold)
                                .foregroundColor(.axSuccess)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.axSuccess.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        } else {
                            Button(action: { Task { await viewModel.switchVersion(version) } }) {
                                Text("Use")
                                    .font(AXTypography.caption).fontWeight(.semibold)
                                    .foregroundColor(.axAccentBlue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axBackground.opacity(0.5))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
        }
    }
}
