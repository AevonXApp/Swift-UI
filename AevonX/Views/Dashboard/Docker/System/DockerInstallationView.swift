
import SwiftUI
import AevonXCore

struct DockerInstallationView: View {
    let serverId: String
    var onInstallationComplete: () -> Void
    
    @State private var isInstalling = false
    @State private var progress: Double = 0
    @State private var statusMessage: String = "Docker is not installed on this server."
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            
            AXCard {
                VStack(spacing: AXSpacing.lg) {
                    // Icon & Title
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.axAccentBlue)
                        
                        Text("Docker Engine Required")
                            .font(AXTypography.title3)
                            .foregroundColor(.axTextPrimary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("To manage containers, images, and stacks, Docker Engine must be installed on your server. We can install it for you automatically using the official Docker setup script.")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AXSpacing.md)
                    
                    if isInstalling {
                        VStack(spacing: AXSpacing.md) {
                            ProgressView(value: progress)
                                .tint(.axAccentBlue)
                            
                            Text(statusMessage)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                        .padding(.top, AXSpacing.md)
                    } else if let error = errorMessage {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .padding()
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    
                    // Action Button
                    Button(action: installDocker) {
                        HStack {
                            if isInstalling {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 8)
                            }
                            Text(isInstalling ? "Installing Docker..." : "Install Docker Now")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isInstalling ? Color.axAccentBlue.opacity(0.5) : Color.axAccentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(isInstalling)
                }
                .padding(AXSpacing.xl)
            }
            .frame(maxWidth: 500)
            
            Spacer()
        }
        .padding(AXSpacing.xl)
    }
    
    private func installDocker() {
        isInstalling = true
        errorMessage = nil
        progress = 0
        
        Task {
            do {
                try await DockerManager.shared.installDocker(serverId: serverId) { message, currentProgress in
                    Task { @MainActor in
                        self.statusMessage = message
                        self.progress = currentProgress
                    }
                }
                
                await MainActor.run {
                    isInstalling = false
                    onInstallationComplete()
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    errorMessage = "Installation failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
