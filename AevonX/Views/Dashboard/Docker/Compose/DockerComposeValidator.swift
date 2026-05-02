
import SwiftUI
import AevonXCoreBridge

struct DockerComposeValidator: View {
    let serverId: String
    let workingDir: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var isValidating = false
    @State private var validOutput: String?
    @State private var errorOutput: String?
    @State private var isValid: Bool?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.axSuccess)
                    Text(L10n.Docker.composeValidation)
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
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Working dir
                    HStack(spacing: 6) {
                        Image(systemName: "folder").foregroundColor(.axTextMuted)
                        Text(workingDir)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    // Status
                    if isValidating {
                        HStack(spacing: AXSpacing.sm) {
                            ProgressView().controlSize(.small)
                            Text(L10n.Docker.validatingDockerComposeYml)
                                .font(.system(size: 12))
                                .foregroundColor(.axTextSecondary)
                        }
                    } else if let valid = isValid {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(valid ? .axSuccess : .axError)
                                .font(.system(size: 20))
                            VStack(alignment: .leading) {
                                Text(valid ? "Valid Configuration" : "Invalid Configuration")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(valid ? .axSuccess : .axError)
                                Text(valid ? "docker-compose.yml syntax is correct" : "There are errors in your configuration")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextSecondary)
                            }
                        }
                        .padding(AXSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((valid ? Color.axSuccess : Color.axError).opacity(0.08))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    
                    // Resolved config output
                    if let output = validOutput, !output.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(L10n.Docker.resolvedConfiguration)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.axTextMuted)
                                Spacer()
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(output, forType: .string)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc").font(.system(size: 9))
                                        Text(L10n.Button.copy).font(.system(size: 9))
                                    }
                                    .foregroundColor(.axAccentBlue)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            ScrollView {
                                Text(output)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(AXSpacing.sm)
                            .frame(maxHeight: 250)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                            .cornerRadius(6)
                        }
                    }
                    
                    // Error output
                    if let error = errorOutput, !error.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.Docker.errors)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.axError)
                            Text(error)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AXSpacing.sm)
                                .background(Color.axError.opacity(0.05))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: validate) {
                    HStack(spacing: 4) {
                        if isValidating { ProgressView().controlSize(.small) }
                        Image(systemName: "checkmark.shield").font(.system(size: 10))
                        Text(isValidating ? "Validating..." : "Validate")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(isValidating)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 550, height: 480)
        .background(Color.axBackground)
        .task { validate() }
    }
    
    private func validate() {
        isValidating = true; validOutput = nil; errorOutput = nil; isValid = nil
        Task {
            do {
                let result = try await DockerService.shared.composeValidate(workingDir: workingDir, serverId: serverId)
                await MainActor.run {
                    isValid = result.isValid
                    validOutput = result.resolvedConfig
                    errorOutput = result.errorOutput
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    isValid = false
                    errorOutput = error.localizedDescription
                    isValidating = false
                }
            }
        }
    }
}
