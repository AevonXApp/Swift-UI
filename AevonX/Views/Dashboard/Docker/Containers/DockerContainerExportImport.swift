
import SwiftUI
import AevonXCoreBridge

struct DockerContainerExportImport: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var mode: ExportMode = .export
    @State private var containers: [DockerContainer] = []
    @State private var selectedContainerId: String = ""
    @State private var exportPath: String = "/tmp"
    @State private var importPath: String = ""
    @State private var containerName: String = ""
    @State private var isProcessing = false
    @State private var output: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    enum ExportMode: String, CaseIterable {
        case export = "Export"
        case importContainer = "Import"
        case snapshot = "Snapshot"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.axAccentBlue)
                    Text(L10n.Docker.containerExportImport)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            // Mode tabs
            HStack(spacing: 0) {
                ForEach(ExportMode.allCases, id: \.self) { m in
                    Button(action: { mode = m }) {
                        Text(m.rawValue)
                            .font(.system(size: 11, weight: mode == m ? .bold : .regular))
                            .foregroundColor(mode == m ? .axAccentBlue : .axTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(mode == m ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface.opacity(0.5))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    switch mode {
                    case .export:
                        exportView
                    case .importContainer:
                        importView
                    case .snapshot:
                        snapshotView
                    }
                    
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.Docker.output)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.axTextMuted)
                            Text(output)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            // Messages
            if let error = errorMessage {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                    .font(.system(size: 11)).foregroundColor(.axError)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
            }
            if let success = successMessage {
                HStack(spacing: 6) { Image(systemName: "checkmark.circle.fill"); Text(success) }
                    .font(.system(size: 11)).foregroundColor(.axSuccess)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axSuccess.opacity(0.08))
            }
        }
        .frame(width: 550, height: 450)
        .background(Color.axBackground)
        .task {
            do {
                containers = try await DockerService.shared.getContainers(serverId: serverId, all: true)
            } catch {}
        }
    }
    
    // MARK: - Export View
    
    private var exportView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            fieldLabel("Select Container")
            Picker("", selection: $selectedContainerId) {
                Text(L10n.Docker.select).tag("")
                ForEach(containers) { c in
                    Text("\(c.names) (\(c.shortId))").tag(c.id)
                }
            }
            
            fieldLabel("Export Directory")
            TextField("/tmp/container-export.tar", text: $exportPath)
                .textFieldStyle(AXTextFieldStyle())
                .font(.system(size: 12, design: .monospaced))
            
            Button(action: exportContainer) {
                HStack(spacing: 4) {
                    if isProcessing { ProgressView().controlSize(.small) }
                    Image(systemName: "arrow.up.doc.fill").font(.system(size: 10))
                    Text(isProcessing ? "Exporting..." : "Export")
                }
            }
            .buttonStyle(AXPrimaryButtonStyle())
            .disabled(selectedContainerId.isEmpty || isProcessing)
        }
    }
    
    // MARK: - Import View
    
    private var importView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            fieldLabel("Import File Path")
            TextField("/tmp/container-export.tar", text: $importPath)
                .textFieldStyle(AXTextFieldStyle())
                .font(.system(size: 12, design: .monospaced))
            
            fieldLabel("New Image Name")
            TextField("imported-image:latest", text: $containerName)
                .textFieldStyle(AXTextFieldStyle())
            
            Button(action: importContainer) {
                HStack(spacing: 4) {
                    if isProcessing { ProgressView().controlSize(.small) }
                    Image(systemName: "arrow.down.doc.fill").font(.system(size: 10))
                    Text(isProcessing ? "Importing..." : "Import")
                }
            }
            .buttonStyle(AXPrimaryButtonStyle())
            .disabled(importPath.isEmpty || containerName.isEmpty || isProcessing)
        }
    }
    
    // MARK: - Snapshot View
    
    private var snapshotView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(L10n.Docker.createAnImageFromARunningContainersCurrentState)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            
            fieldLabel("Select Container")
            Picker("", selection: $selectedContainerId) {
                Text(L10n.Docker.select).tag("")
                ForEach(containers) { c in
                    Text("\(c.names) (\(c.shortId))").tag(c.id)
                }
            }
            
            fieldLabel("Image Name")
            TextField("my-snapshot", text: $containerName)
                .textFieldStyle(AXTextFieldStyle())
            
            Button(action: snapshotContainer) {
                HStack(spacing: 4) {
                    if isProcessing { ProgressView().controlSize(.small) }
                    Image(systemName: "camera.fill").font(.system(size: 10))
                    Text(isProcessing ? "Creating..." : "Create Snapshot")
                }
            }
            .buttonStyle(AXPrimaryButtonStyle())
            .disabled(selectedContainerId.isEmpty || containerName.isEmpty || isProcessing)
        }
    }
    
    // MARK: - Helpers
    
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.axTextSecondary)
    }
    
    // MARK: - Actions
    
    private func exportContainer() {
        isProcessing = true; errorMessage = nil; successMessage = nil; output = ""
        Task {
            do {
                let containerName = containers.first(where: { $0.id == selectedContainerId })?.names ?? selectedContainerId
                let fileName = "\(exportPath)/\(containerName)-export.tar"
                try await DockerService.shared.exportContainer(id: selectedContainerId, path: fileName, serverId: serverId)
                await MainActor.run {
                    successMessage = "Exported to \(fileName)"
                    isProcessing = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isProcessing = false }
            }
        }
    }
    
    private func importContainer() {
        isProcessing = true; errorMessage = nil; successMessage = nil; output = ""
        Task {
            do {
                try await DockerService.shared.importContainer(path: importPath, imageName: containerName, serverId: serverId)
                await MainActor.run {
                    successMessage = "Imported as \(containerName)"
                    isProcessing = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isProcessing = false }
            }
        }
    }
    
    private func snapshotContainer() {
        isProcessing = true; errorMessage = nil; successMessage = nil; output = ""
        Task {
            do {
                try await DockerService.shared.commitContainer(
                    id: selectedContainerId,
                    imageName: containerName,
                    tag: "latest",
                    serverId: serverId
                )
                await MainActor.run {
                    successMessage = "Snapshot created: \(containerName):latest"
                    isProcessing = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isProcessing = false }
            }
        }
    }
}
