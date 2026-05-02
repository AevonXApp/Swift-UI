
import SwiftUI
import AevonXCoreBridge

struct DockerProfileExportView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var exportedJSON = ""
    @State private var importJSON = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var progressMessage = ""
    @State private var progressValue: Double = 0
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var selectedMode: TabMode = .export
    @State private var isCopied = false
    
    enum TabMode: String, CaseIterable {
        case export = "Export"
        case `import` = "Import"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Profile Export / Import", systemImage: "square.and.arrow.up.on.square")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Divider()
            
            // Mode picker
            Picker("Mode", selection: $selectedMode) {
                ForEach(TabMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    if selectedMode == .export {
                        exportView
                    } else {
                        importView
                    }
                    
                    if let error = errorMessage {
                        Text(error).font(AXTypography.caption).foregroundColor(.axError)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axError.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    if let success = successMessage {
                        Text(success).font(AXTypography.caption).foregroundColor(.axSuccess)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axSuccess.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .background(Color.axBackground)
    }
    
    // MARK: - Export
    
    @ViewBuilder
    private var exportView: some View {
        AXCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Docker.exportAllContainerConfigurationsAsAPortableJsonProfile)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                Button {
                    exportProfile()
                } label: {
                    if isExporting {
                        ProgressView().scaleEffect(0.7).frame(maxWidth: .infinity)
                    } else {
                        Label("Export Profile", systemImage: "square.and.arrow.up")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)
                .padding()
                .background(Color.axAccentBlue)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.md)
                .disabled(isExporting)
            }
        }
        
        if !exportedJSON.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L10n.Docker.exportedProfile)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(exportedJSON, forType: .string)
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                    } label: {
                        Label(isCopied ? "Copied!" : "Copy JSON", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(AXTypography.caption)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isCopied ? Color.axSuccess.opacity(0.15) : Color.axSurface)
                    .foregroundColor(isCopied ? .axSuccess : .axTextSecondary)
                    .cornerRadius(AXCornerRadius.sm)
                }
                
                ScrollView {
                    Text(exportedJSON)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AXSpacing.sm)
                .frame(maxHeight: 250)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
            }
        }
    }
    
    // MARK: - Import
    
    @ViewBuilder
    private var importView: some View {
        AXCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Docker.pasteAnExportedJsonProfileToRecreateContainers)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                TextEditor(text: $importJSON)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(minHeight: 150)
                    .padding(6)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder))
                
                if isImporting {
                    VStack(spacing: 6) {
                        ProgressView(value: progressValue).progressViewStyle(.linear)
                        Text(progressMessage).font(AXTypography.caption).foregroundColor(.axTextSecondary)
                    }
                }
                
                Button {
                    importProfile()
                } label: {
                    if isImporting {
                        ProgressView().scaleEffect(0.7).frame(maxWidth: .infinity)
                    } else {
                        Label("Import Profile", systemImage: "square.and.arrow.down")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)
                .padding()
                .background(importJSON.isEmpty ? Color.axSurface : Color.axWarning)
                .foregroundColor(importJSON.isEmpty ? .axTextMuted : .white)
                .cornerRadius(AXCornerRadius.md)
                .disabled(importJSON.isEmpty || isImporting)
            }
        }
    }
    
    private func exportProfile() {
        isExporting = true
        errorMessage = nil
        Task {
            do {
                let json = try await DockerService.shared.exportContainerProfile(serverId: serverId)
                await MainActor.run {
                    exportedJSON = json
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func importProfile() {
        isImporting = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                try await DockerService.shared.importContainerProfile(
                    json: importJSON,
                    serverId: serverId,
                    progress: { msg, pct in
                        Task { @MainActor in
                            progressMessage = msg
                            progressValue = pct
                        }
                    }
                )
                await MainActor.run {
                    isImporting = false
                    successMessage = "Profile imported successfully ✅"
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
