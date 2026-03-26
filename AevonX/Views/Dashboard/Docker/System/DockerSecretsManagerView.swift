
import SwiftUI
import AevonXCoreBridge

struct DockerSecretsManagerView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var secrets: [DockerSecret] = []
    @State private var isLoading = true
    @State private var showAddSecret = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var isAdding = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(L10n.Docker.secretsManager, systemImage: "key.fill")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button { showAddSecret.toggle() } label: {
                    Label("New Secret", systemImage: "plus")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.axAccentBlue)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
                
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
            
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    if showAddSecret {
                        AXCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Create Secret")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                TextField("Secret name", text: $newSecretName)
                                    .textFieldStyle(.roundedBorder)
                                
                                SecureField("Secret value", text: $newSecretValue)
                                    .textFieldStyle(.roundedBorder)
                                
                                HStack {
                                    Spacer()
                                    Button(L10n.Button.cancel) { showAddSecret = false }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.axTextSecondary)

                                    Button {
                                        addSecret()
                                    } label: {
                                        if isAdding { ProgressView().scaleEffect(0.6) }
                                        else { Text(L10n.Button.create) }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(newSecretName.isEmpty ? Color.axSurface : Color.axAccentBlue)
                                    .foregroundColor(newSecretName.isEmpty ? .axTextMuted : .white)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .disabled(newSecretName.isEmpty || isAdding)
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error).font(AXTypography.caption).foregroundColor(.axError).padding()
                    }
                    
                    if isLoading {
                        ProgressView("Loading secrets...").padding(30)
                    } else if secrets.isEmpty {
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "key.slash")
                                .font(.system(size: 32))
                                .foregroundColor(.axTextMuted)
                            Text("No Docker secrets found")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                            Text("Secrets require Docker Swarm mode")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                        .padding(30)
                    } else {
                        ForEach(secrets) { secret in
                            AXCard {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.axWarning)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(secret.name)
                                            .font(AXTypography.body)
                                            .foregroundColor(.axTextPrimary)
                                        Text("Created: \(secret.createdAt)")
                                            .font(AXTypography.caption2)
                                            .foregroundColor(.axTextMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        deleteSecret(secret)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                            .foregroundColor(.axError)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 350)
        .background(Color.axBackground)
        .onAppear { loadSecrets() }
    }
    
    private func loadSecrets() {
        Task {
            do {
                let s = try await DockerService.shared.listSecrets(serverId: serverId)
                await MainActor.run { secrets = s; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func addSecret() {
        isAdding = true
        Task {
            do {
                try await DockerService.shared.createSecret(name: newSecretName, value: newSecretValue, serverId: serverId)
                await MainActor.run {
                    isAdding = false; showAddSecret = false
                    newSecretName = ""; newSecretValue = ""
                    loadSecrets()
                }
            } catch {
                await MainActor.run { isAdding = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func deleteSecret(_ secret: DockerSecret) {
        Task {
            try? await DockerService.shared.deleteSecret(name: secret.name, serverId: serverId)
            await MainActor.run { secrets.removeAll { $0.id == secret.id } }
        }
    }
}
