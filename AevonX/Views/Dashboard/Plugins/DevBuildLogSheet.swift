//
//  DevBuildLogSheet.swift
//  AevonX
//
//  Terminal-style modal for developer build installation.
//  Shows drag & drop zone, streaming build steps with animations,
//  and color-coded status indicators.
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore
import UniformTypeIdentifiers

struct DevBuildLogSheet: View {
    
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    // Build state
    @State private var steps: [AevonXCore.DevBuildStep] = []
    @State private var isInstalling: Bool = false
    @State private var isComplete: Bool = false
    @State private var hasFailed: Bool = false
    @State private var selectedZipURL: URL? = nil
    @State private var isDragOver: Bool = false
    @State private var installedSlug: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            titleBar
            
            Divider().opacity(0.3)
            
            // Content
            if steps.isEmpty && !isInstalling {
                dropZone
            } else {
                terminalOutput
            }
            
            Divider().opacity(0.3)
            
            // Footer
            footerBar
        }
        .frame(width: 560, height: isInstalling || !steps.isEmpty ? 500 : 340)
        .background(Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: isInstalling)
        .animation(.easeInOut(duration: 0.3), value: steps.count)
    }
    
    // MARK: - Title Bar
    
    private var titleBar: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.axAccentBlue)
            
            Text("Dev Build Installer")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            if isInstalling {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                    .scaleEffect(0.6)
            }
            
            if isComplete && !hasFailed {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("SUCCESS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.green)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)))
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            
            VStack(spacing: AXSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isDragOver ? Color.axAccentBlue : Color.white.opacity(0.15),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDragOver ? Color.axAccentBlue.opacity(0.08) : Color.white.opacity(0.02))
                        )
                    
                    VStack(spacing: AXSpacing.lg) {
                        Image(systemName: isDragOver ? "arrow.down.doc.fill" : "shippingbox.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(isDragOver ? .axAccentBlue : .white.opacity(0.4))
                            .scaleEffect(isDragOver ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3), value: isDragOver)
                        
                        VStack(spacing: 4) {
                            Text(isDragOver ? "Drop to install" : "Drop plugin .zip here")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isDragOver ? .axAccentBlue : .white.opacity(0.7))
                            
                            Text("or click to select a file")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
                    .padding(AXSpacing.xxl)
                }
                .frame(height: 180)
                .padding(.horizontal, AXSpacing.xxl)
                .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .onTapGesture {
                    selectFile()
                }
                .contentShape(Rectangle())
                
                // Requirements note
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("ZIP must contain: setup.sh, uninstall.sh, config.avx")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.25))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Terminal Output
    
    private var terminalOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    // Header
                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundColor(.green)
                        Text("aevonx install --dev")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.bottom, 4)
                    
                    // Steps
                    ForEach(steps) { step in
                        stepRow(step)
                            .id(step.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(AXSpacing.lg)
            }
            .onChange(of: steps.count) {
                if let lastStep = steps.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastStep.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func stepRow(_ step: AevonXCore.DevBuildStep) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Status icon
            Group {
                switch step.status {
                case .running:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                case .success:
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                case .failed:
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 14, height: 14)
                case .skipped:
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                        .frame(width: 14, height: 14)
                case .pending:
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .frame(width: 14, height: 14)
                }
            }
            .frame(width: 14)
            
            // Label
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.label)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(stepLabelColor(step))
                    
                    if let duration = step.duration {
                        Text(String(format: "%.1fs", duration))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(statusText(step.status))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor(step.status))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor(step.status).opacity(0.12))
                        )
                }
                
                if let detail = step.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(step.status == .failed ? .red.opacity(0.8) : .white.opacity(0.35))
                        .lineLimit(step.status == .failed ? 5 : 1)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.vertical, 3)
    }
    
    // MARK: - Footer
    
    private var footerBar: some View {
        HStack {
            if isComplete && !hasFailed {
                Button(action: {
                    // Reload plugins
                    Task {
                        await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)
                    }
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Done")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
            } else if hasFailed {
                Button("Retry") {
                    steps = []
                    hasFailed = false
                    isComplete = false
                    if let url = selectedZipURL {
                        startInstallation(url: url)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.axAccentBlue)
                .font(.system(size: 12, weight: .semibold))
            }
            
            Spacer()
            
            if !isInstalling {
                Button(isComplete ? "Close" : "Cancel") {
                    if isComplete && !hasFailed {
                        Task {
                            await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)
                        }
                    }
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 12, weight: .medium))
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)))
    }
    
    // MARK: - Actions
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Select AevonXCore.Plugin Build ZIP"
        panel.message = "Choose a .zip file containing setup.sh, uninstall.sh, and config.avx"
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        selectedZipURL = url
        startInstallation(url: url)
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "zip" else { return }
            
            DispatchQueue.main.async {
                selectedZipURL = url
                startInstallation(url: url)
            }
        }
    }
    
    private func startInstallation(url: URL) {
        steps = []
        isInstalling = true
        isComplete = false
        hasFailed = false
        
        Task {
            do {
                let slug = try await AevonXCore.PluginManager.shared.installDevBuild(
                    zipURL: url,
                    on: serverId
                ) { step in
                    Task { @MainActor in
                        updateStep(step)
                    }
                }
                
                await MainActor.run {
                    installedSlug = slug
                    isInstalling = false
                    isComplete = true
                }
                
                // Auto-reload plugins
                await AevonXCoreBridge.HookLoader.shared.load(serverId: serverId, force: true)
                
            } catch {
                await MainActor.run {
                    isInstalling = false
                    isComplete = true
                    hasFailed = true
                    
                    // Add error step if not already shown
                    if steps.last?.status != .failed {
                        var errorStep = AevonXCore.DevBuildStep(index: (steps.last?.index ?? 0) + 1, label: "Installation failed", status: .failed)
                        errorStep.detail = error.localizedDescription
                        steps.append(errorStep)
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateStep(_ step: AevonXCore.DevBuildStep) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if let existingIndex = steps.firstIndex(where: { $0.index == step.index }) {
                steps[existingIndex] = step
            } else {
                steps.append(step)
            }
        }
    }
    
    // MARK: - Styling Helpers
    
    private func stepLabelColor(_ step: AevonXCore.DevBuildStep) -> Color {
        switch step.status {
        case .running: return .white
        case .success: return .white.opacity(0.7)
        case .failed:  return .red
        case .skipped: return .yellow.opacity(0.7)
        case .pending: return .white.opacity(0.3)
        }
    }
    
    private func statusText(_ status: AevonXCore.DevBuildStep.StepStatus) -> String {
        switch status {
        case .pending: return "WAIT"
        case .running: return "RUN"
        case .success: return "OK"
        case .failed:  return "FAIL"
        case .skipped: return "SKIP"
        }
    }
    
    private func statusColor(_ status: AevonXCore.DevBuildStep.StepStatus) -> Color {
        switch status {
        case .pending: return .white.opacity(0.3)
        case .running: return .axAccentBlue
        case .success: return .green
        case .failed:  return .red
        case .skipped: return .yellow
        }
    }
}
