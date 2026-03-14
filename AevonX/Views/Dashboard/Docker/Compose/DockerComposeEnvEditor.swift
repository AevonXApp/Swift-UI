
import SwiftUI
import AevonXCoreBridge

struct DockerComposeEnvEditor: View {
    let project: DockerComposeProject
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var envVars: [(key: String, value: String, isSecret: Bool)] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var hasChanges = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        Text("Environment: \(project.name)")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Text("\(project.workingDir)/.env")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                }
                
                Spacer()
                
                if hasChanges {
                    Text("Unsaved")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
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
                VStack { ProgressView(); Text("Loading .env file...").font(AXTypography.caption).foregroundColor(.axTextMuted) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Env var list
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(envVars.indices, id: \.self) { i in
                            HStack(spacing: AXSpacing.sm) {
                                TextField("KEY", text: Binding(
                                    get: { envVars[i].key },
                                    set: { envVars[i].key = $0; hasChanges = true }
                                ))
                                .textFieldStyle(AXTextFieldStyle())
                                .font(.system(size: 12, design: .monospaced))
                                .frame(maxWidth: 200)
                                
                                Text("=")
                                    .foregroundColor(.axTextMuted)
                                
                                Group {
                                    if envVars[i].isSecret {
                                        SecureField("value", text: Binding(
                                            get: { envVars[i].value },
                                            set: { envVars[i].value = $0; hasChanges = true }
                                        ))
                                    } else {
                                        TextField("value", text: Binding(
                                            get: { envVars[i].value },
                                            set: { envVars[i].value = $0; hasChanges = true }
                                        ))
                                    }
                                }
                                .textFieldStyle(AXTextFieldStyle())
                                .font(.system(size: 12, design: .monospaced))
                                
                                Button(action: { envVars[i].isSecret.toggle() }) {
                                    Image(systemName: envVars[i].isSecret ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axTextMuted)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { envVars.remove(at: i); hasChanges = true }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.axError)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button(action: { envVars.append((key: "", value: "", isSecret: false)); hasChanges = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill").font(.system(size: 12))
                                Text("Add Variable").font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.axAccentBlue)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, AXSpacing.sm)
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
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button(action: save) {
                    HStack(spacing: 4) {
                        if isSaving { ProgressView().controlSize(.small) }
                        Text("Save")
                    }
                }
                .buttonStyle(AXSecondaryButtonStyle())
                .disabled(isSaving || !hasChanges)
                
                Button(action: saveAndApply) {
                    HStack(spacing: 4) {
                        if isSaving { ProgressView().controlSize(.small) }
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("Save & Recreate")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(isSaving || !hasChanges)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 600, height: 450)
        .background(Color.axBackground)
        .task { await loadEnvFile() }
    }
    
    // MARK: - Actions
    
    private func loadEnvFile() async {
        isLoading = true
        do {
            let entries = try await DockerService.shared.readEnvFile(workingDir: project.workingDir, serverId: serverId)
            let mapped = entries.map { (key: $0.key, value: $0.value, isSecret: $0.isSecret) }
            await MainActor.run { envVars = mapped; isLoading = false }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
    
    private func buildEnvContent() -> String {
        envVars.filter { !$0.key.isEmpty }.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
    }
    
    private func save() {
        isSaving = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                try await DockerService.shared.writeEnvFile(workingDir: project.workingDir, content: buildEnvContent(), serverId: serverId)
                await MainActor.run { hasChanges = false; successMessage = "Saved"; isSaving = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isSaving = false }
            }
        }
    }
    
    private func saveAndApply() {
        isSaving = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                try await DockerService.shared.writeEnvFile(workingDir: project.workingDir, content: buildEnvContent(), serverId: serverId)
                try await DockerService.shared.composeDown(workingDir: project.workingDir, serverId: serverId)
                try await DockerService.shared.composeUp(workingDir: project.workingDir, serverId: serverId)
                await MainActor.run { hasChanges = false; successMessage = "Saved & containers recreated"; isSaving = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isSaving = false }
            }
        }
    }
}
