
import SwiftUI
import AevonXCore

@MainActor
public struct NginxVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String
    
    @State private var availableVersions: [String] = []
    @State private var isLoadingVersions = false
    @State private var currentOperation: VersionOperation?
    @State private var operationProgress: Double = 0.0
    @State private var operationMessage: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    enum VersionOperation: Equatable {
        case installing(String)
        case switching(String)
        
        var version: String {
            switch self {
            case .installing(let v), .switching(let v): return v
            }
        }
    }

    public init(application: ApplicationInstance, serverId: String) {
        self.application = application
        self.serverId = serverId
    }

    public var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Current Version Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Version")
                                .font(AXTypography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.axTextTertiary)
                            
                            Text(application.version ?? "Unknown")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: AXSpacing.xs) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(application.isRunning ? Color.axSuccess : Color.axError)
                                    .frame(width: 6, height: 6)
                                Text(application.isRunning ? "Running" : "Stopped")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextSecondary)
                            }
                            
                            if application.isRunning {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.axSuccess)
                            }
                        }
                    }
                }
            }

            // Available Versions Section
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: AXSpacing.md) {
                    Text("AVAILABLE VERSIONS (\(availableVersions.count))")
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                    
                    Button(action: { Task { await loadVersions() } }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text("Refresh")
                                .font(AXTypography.caption)
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingVersions)
                }
                .padding(.bottom, AXSpacing.md)

                // Versions List
                if isLoadingVersions {
                    AXCard {
                        VStack(spacing: AXSpacing.md) {
                            ProgressView()
                            Text("Loading versions...")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.xl)
                    }
                } else if availableVersions.isEmpty {
                    AXCard {
                        VStack(spacing: AXSpacing.md) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.axWarning.opacity(0.5))
                            Text("No versions available")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextSecondary)
                            Text("Try refreshing to fetch available versions")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.xl)
                    }
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(availableVersions, id: \.self) { version in
                            VersionRow(
                                version: version,
                                isCurrent: version == application.version,
                                operation: currentOperation?.version == version ? currentOperation : nil,
                                progress: operationProgress,
                                progressMessage: operationMessage,
                                onInstall: { await installVersion(version) },
                                onSwitch: { await switchToVersion(version) }
                            )
                        }
                    }
                }
            }
        }
        .task {
            await loadVersions()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func loadVersions() async {
        isLoadingVersions = true
        do {
            let versions = try await ApplicationManager.shared.getAvailableVersions(type: .nginx, serverId: serverId)
            await MainActor.run {
                self.availableVersions = versions
                self.isLoadingVersions = false
            }
        } catch {
            await MainActor.run {
                self.availableVersions = []
                self.isLoadingVersions = false
                self.alertTitle = "Error"
                self.alertMessage = "Failed to load versions: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    private func installVersion(_ version: String) async {
        currentOperation = .installing(version)
        operationProgress = 0.0
        operationMessage = "Starting installation..."
        
        do {
            try await ApplicationManager.shared.installVersion(version, type: .nginx, serverId: serverId) { message, progress in
                Task { @MainActor in
                    self.operationProgress = progress
                    self.operationMessage = message
                }
            }
            
            await MainActor.run {
                self.currentOperation = nil
                self.alertTitle = "Success"
                self.alertMessage = "Nginx version \(version) installed successfully!"
                self.showAlert = true
            }
        } catch {
            await MainActor.run {
                self.currentOperation = nil
                self.alertTitle = "Installation Failed"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
    
    private func switchToVersion(_ version: String) async {
        currentOperation = .switching(version)
        operationProgress = 0.0
        operationMessage = "Starting switch..."
        
        do {
            try await ApplicationManager.shared.switchVersion(version, type: .nginx, serverId: serverId) { message, progress in
                Task { @MainActor in
                    self.operationProgress = progress
                    self.operationMessage = message
                }
            }
            
            await MainActor.run {
                self.currentOperation = nil
                self.alertTitle = "Success"
                self.alertMessage = "Switched to Nginx version \(version) successfully!"
                self.showAlert = true
            }
        } catch {
            await MainActor.run {
                self.currentOperation = nil
                self.alertTitle = "Switch Failed"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
}

// MARK: - Version Row Component

private struct VersionRow: View {
    let version: String
    let isCurrent: Bool
    let operation: NginxVersionsTab.VersionOperation?
    let progress: Double
    let progressMessage: String
    let onInstall: () async -> Void
    let onSwitch: () async -> Void
    
    var isOperating: Bool {
        operation != nil
    }
    
    var body: some View {
        AXCard(padding: AXSpacing.md) {
            VStack(spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.md) {
                    // Version Number
                    Text(version)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                    
                    Spacer()
                    
                    // Status/Actions
                    if isCurrent {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Current")
                                .font(AXTypography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.axSuccess)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.axSuccess.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    } else if isOperating {
                        HStack(spacing: AXSpacing.xs) {
                            ProgressView()
                                .controlSize(.small)
                            Text("\(Int(progress * 100))%")
                                .font(AXTypography.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.axTextSecondary)
                        }
                    } else {
                        HStack(spacing: AXSpacing.sm) {
                            Button(action: { Task { await onInstall() } }) {
                                Text("Install")
                                    .font(AXTypography.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axAccentBlue)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, 6)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { Task { await onSwitch() } }) {
                                Text("Switch")
                                    .font(AXTypography.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axTextSecondary)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, 6)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Progress Bar
                if isOperating {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: progress)
                            .tint(.axAccentBlue)
                        
                        Text(progressMessage)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextTertiary)
                    }
                }
            }
        }
    }
}
