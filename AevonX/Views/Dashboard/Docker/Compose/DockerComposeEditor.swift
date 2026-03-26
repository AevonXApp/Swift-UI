
import SwiftUI
import AevonXCoreBridge

struct DockerComposeEditor: View {
    let project: DockerComposeProject
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var isApplying = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var hasChanges: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.plaintext.fill")
                            .foregroundColor(.axAccentBlue)
                        Text("Edit: \(project.name)")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Text(project.workingDir)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                }
                
                Spacer()
                
                if hasChanges {
                    Text("Unsaved Changes")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Loading compose file...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Editor
                TextEditor(text: $content)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(AXSpacing.sm)
                    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                    .foregroundColor(.white)
                    .onChange(of: content) { _, newVal in
                        hasChanges = newVal != originalContent
                    }
            }
            
            // Messages
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.system(size: 11))
                .foregroundColor(.axError)
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axError.opacity(0.08))
            }
            
            if let success = successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(success)
                }
                .font(.system(size: 11))
                .foregroundColor(.axSuccess)
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axSuccess.opacity(0.08))
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Revert") {
                    content = originalContent
                    hasChanges = false
                }
                .buttonStyle(AXSecondaryButtonStyle())
                .disabled(!hasChanges)
                
                Spacer()
                
                Button(action: save) {
                    HStack(spacing: 4) {
                        if isSaving { ProgressView().controlSize(.small) }
                        Text(L10n.Button.save)
                    }
                }
                .buttonStyle(AXSecondaryButtonStyle())
                .disabled(isSaving || !hasChanges)
                
                Button(action: applyChanges) {
                    HStack(spacing: 4) {
                        if isApplying { ProgressView().controlSize(.small) }
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("Save & Apply")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(isApplying || !hasChanges)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 700, height: 550)
        .background(Color.axBackground)
        .task { await loadFile() }
    }
    
    // MARK: - Actions
    
    private func loadFile() async {
        isLoading = true
        do {
            content = try await DockerService.shared.readComposeFile(workingDir: project.workingDir, serverId: serverId)
            originalContent = content
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func save() {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await DockerService.shared.writeComposeFile(content: content, workingDir: project.workingDir, serverId: serverId)
                await MainActor.run {
                    originalContent = content
                    hasChanges = false
                    successMessage = "File saved successfully"
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
    
    private func applyChanges() {
        isApplying = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await DockerService.shared.writeComposeFile(content: content, workingDir: project.workingDir, serverId: serverId)
                try await DockerService.shared.composeDown(workingDir: project.workingDir, serverId: serverId)
                try await DockerService.shared.composeUp(workingDir: project.workingDir, serverId: serverId)
                
                await MainActor.run {
                    originalContent = content
                    hasChanges = false
                    successMessage = "Changes applied — containers recreated"
                    isApplying = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isApplying = false
                }
            }
        }
    }
}
