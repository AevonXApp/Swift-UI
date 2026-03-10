//
//  ProcessManagerTab.swift
//  AevonX
//
//  PM2 process management tab for website detail view.
//  List processes, start/stop/restart, view logs.
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - ViewModel

@MainActor
final class ProcessManagerViewModel: ObservableObject {
    @Published var processes: [PM2Process] = []
    @Published var isPM2Installed = false
    @Published var isLoading = true
    @Published var isInstallingPM2 = false
    @Published var selectedProcess: PM2Process?
    @Published var processLogs: String?
    @Published var isLoadingLogs = false
    @Published var isPerformingAction = false
    
    let serverId: String?
    let appName: String
    let appPath: String
    
    private let processService = NodeJSProcessService()
    
    init(serverId: String?, appName: String, appPath: String) {
        self.serverId = serverId
        self.appName = appName
        self.appPath = appPath
    }
    
    func loadAll() async {
        guard let serverId = serverId else { return }
        isLoading = true
        
        do {
            isPM2Installed = try await processService.isPM2Installed(serverId: serverId)
            if isPM2Installed {
                processes = try await processService.listProcesses(serverId: serverId)
            }
        } catch {
            CoreLogger.shared.error("Failed to load PM2 processes: \(error)", module: "ProcessManagerTab")
        }
        
        isLoading = false
    }
    
    func installPM2() async {
        guard let serverId = serverId else { return }
        isInstallingPM2 = true
        
        do {
            try await processService.installPM2(serverId: serverId)
            isPM2Installed = true
            GlobalToastManager.shared.showSuccess("PM2 installed successfully")
        } catch {
            GlobalToastManager.shared.showError("Failed to install PM2: \(error.localizedDescription)")
        }
        
        isInstallingPM2 = false
    }
    
    func startProcess() async {
        guard let serverId = serverId else { return }
        isPerformingAction = true
        
        do {
            let configService = NodeJSConfigService()
            let entryFile = try await configService.detectEntryFile(appPath: appPath, serverId: serverId)
            _ = try await processService.startProcess(name: appName, entryFile: entryFile, cwd: appPath, serverId: serverId)
            await loadAll()
            GlobalToastManager.shared.showSuccess("Process started")
        } catch {
            GlobalToastManager.shared.showError("Start failed: \(error.localizedDescription)")
        }
        
        isPerformingAction = false
    }
    
    func stopProcess(_ name: String) async {
        guard let serverId = serverId else { return }
        isPerformingAction = true
        
        do {
            try await processService.stopProcess(name: name, serverId: serverId)
            await loadAll()
            GlobalToastManager.shared.showSuccess("Process stopped")
        } catch {
            GlobalToastManager.shared.showError("Stop failed: \(error.localizedDescription)")
        }
        
        isPerformingAction = false
    }
    
    func restartProcess(_ name: String) async {
        guard let serverId = serverId else { return }
        isPerformingAction = true
        
        do {
            try await processService.restartProcess(name: name, serverId: serverId)
            await loadAll()
            GlobalToastManager.shared.showSuccess("Process restarted")
        } catch {
            GlobalToastManager.shared.showError("Restart failed: \(error.localizedDescription)")
        }
        
        isPerformingAction = false
    }
    
    func deleteProcess(_ name: String) async {
        guard let serverId = serverId else { return }
        isPerformingAction = true
        
        do {
            try await processService.deleteProcess(name: name, serverId: serverId)
            await loadAll()
            GlobalToastManager.shared.showSuccess("Process deleted")
        } catch {
            GlobalToastManager.shared.showError("Delete failed: \(error.localizedDescription)")
        }
        
        isPerformingAction = false
    }
    
    func loadLogs(_ name: String) async {
        guard let serverId = serverId else { return }
        isLoadingLogs = true
        
        do {
            processLogs = try await processService.getProcessLogs(name: name, lines: 100, serverId: serverId)
        } catch {
            processLogs = "Failed to load logs: \(error.localizedDescription)"
        }
        
        isLoadingLogs = false
    }
    
    func savePM2List() async {
        guard let serverId = serverId else { return }
        
        do {
            try await processService.saveProcessList(serverId: serverId)
            GlobalToastManager.shared.showSuccess("PM2 list saved for auto-startup")
        } catch {
            GlobalToastManager.shared.showError("Save failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - View

struct ProcessManagerTab: View {
    @StateObject var viewModel: ProcessManagerViewModel
    
    init(serverId: String?, appName: String, appPath: String) {
        _viewModel = StateObject(wrappedValue: ProcessManagerViewModel(serverId: serverId, appName: appName, appPath: appPath))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Checking PM2 status...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else if !viewModel.isPM2Installed {
                pm2NotInstalledView
            } else {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Header Actions
                    headerActions
                    
                    // Process List
                    if viewModel.processes.isEmpty {
                        noProcessesView
                    } else {
                        processListView
                    }
                    
                    // Process Logs
                    if let logs = viewModel.processLogs {
                        logsView(logs)
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }
    
    // MARK: - PM2 Not Installed
    
    private var pm2NotInstalledView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("PM2 Not Installed")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            Text("PM2 is a process manager for Node.js applications.\nIt keeps your app running and auto-restarts on crashes.")
                .font(.system(size: 13))
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: { Task { await viewModel.installPM2() } }) {
                HStack(spacing: AXSpacing.sm) {
                    if viewModel.isInstallingPM2 {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text("Install PM2")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isInstallingPM2)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(AXSpacing.xl)
    }
    
    // MARK: - Header Actions
    
    private var headerActions: some View {
        HStack(spacing: AXSpacing.sm) {
            Button(action: { Task { await viewModel.startProcess() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                    Text("Start App")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSuccess)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPerformingAction)
            
            Spacer()
            
            Button(action: { Task { await viewModel.savePM2List() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 11))
                    Text("Save & Auto-Start")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
            
            Button(action: { Task { await viewModel.loadAll() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - No Processes
    
    private var noProcessesView: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 32))
                .foregroundColor(.axTextMuted)
            Text("No Running Processes")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            Text("Start your application using the 'Start App' button above.")
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
    
    // MARK: - Process List
    
    private var processListView: some View {
        VStack(spacing: AXSpacing.sm) {
            ForEach(viewModel.processes) { process in
                processRow(process)
            }
        }
    }
    
    private func processRow(_ process: PM2Process) -> some View {
        HStack(spacing: AXSpacing.md) {
            // Status indicator
            Circle()
                .fill(processStatusColor(process.status))
                .frame(width: 8, height: 8)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                
                HStack(spacing: AXSpacing.md) {
                    Text("PID: \(process.pid ?? 0)")
                        .font(.system(size: 10, design: .monospaced))
                    Text("CPU: \(process.cpuFormatted)")
                        .font(.system(size: 10, design: .monospaced))
                    Text("Mem: \(process.memoryFormatted)")
                        .font(.system(size: 10, design: .monospaced))
                    if let uptime = process.uptimeFormatted {
                        Text("Up: \(uptime)")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    Text("↻ \(process.restarts)")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: AXSpacing.xs) {
                Button(action: { Task { await viewModel.loadLogs(process.name) } }) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 26, height: 26)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                Button(action: { Task { await viewModel.restartProcess(process.name) } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axWarning)
                        .frame(width: 26, height: 26)
                        .background(Color.axWarning.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                if process.status == .online {
                    Button(action: { Task { await viewModel.stopProcess(process.name) } }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.axError)
                            .frame(width: 26, height: 26)
                            .background(Color.axError.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { Task { await viewModel.restartProcess(process.name) } }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.axSuccess)
                            .frame(width: 26, height: 26)
                            .background(Color.axSuccess.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: { Task { await viewModel.deleteProcess(process.name) } }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.axError)
                        .frame(width: 26, height: 26)
                        .background(Color.axError.opacity(0.05))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(processStatusColor(process.status).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func processStatusColor(_ status: PM2Process.PM2Status) -> Color {
        switch status {
        case .online: return .axSuccess
        case .stopped: return .axTextMuted
        case .errored: return .axError
        case .launching: return .axWarning
        case .unknown: return .axTextTertiary
        }
    }
    
    // MARK: - Logs View
    
    private func logsView(_ logs: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text("Process Logs")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { viewModel.processLogs = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                Text(logs)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .padding(AXSpacing.md)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.md)
        }
    }
}
