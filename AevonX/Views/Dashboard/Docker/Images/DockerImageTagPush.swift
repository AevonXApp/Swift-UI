
import SwiftUI
import AevonXCoreBridge

struct DockerImageTagPush: View {
    let image: DockerImage
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTag: String = ""
    @State private var registry: String = ""
    @State private var isPushing = false
    @State private var isTagging = false
    @State private var output: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var fullNewTag: String {
        if registry.isEmpty {
            return newTag.isEmpty ? "\(image.repository):latest" : newTag
        }
        return "\(registry)/\(newTag.isEmpty ? image.repository : newTag)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.purple)
                    Text("Tag & Push Image")
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
                    // Current image info
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "photo.stack.fill")
                            .foregroundColor(.axTextMuted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(image.repository):\(image.tag)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.axTextPrimary)
                            Text(image.shortId)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                        }
                    }
                    .padding(AXSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    
                    Divider()
                    
                    // Tag section
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Tag Image")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.axTextPrimary)
                        
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Registry (optional)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            TextField("e.g. docker.io/myuser or ghcr.io/myorg", text: $registry)
                                .textFieldStyle(AXTextFieldStyle())
                                .font(.system(size: 12, design: .monospaced))
                        }
                        
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("New Tag")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            TextField("e.g. myimage:v2.0", text: $newTag)
                                .textFieldStyle(AXTextFieldStyle())
                                .font(.system(size: 12, design: .monospaced))
                        }
                        
                        Text("Full tag: \(fullNewTag)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                        
                        HStack(spacing: AXSpacing.sm) {
                            Button(action: tagImage) {
                                HStack(spacing: 4) {
                                    if isTagging { ProgressView().controlSize(.small) }
                                    Image(systemName: "tag").font(.system(size: 10))
                                    Text(isTagging ? "Tagging..." : "Tag")
                                }
                            }
                            .buttonStyle(AXPrimaryButtonStyle())
                            .disabled(newTag.isEmpty || isTagging)
                            
                            Button(action: pushImage) {
                                HStack(spacing: 4) {
                                    if isPushing { ProgressView().controlSize(.small) }
                                    Image(systemName: "icloud.and.arrow.up").font(.system(size: 10))
                                    Text(isPushing ? "Pushing..." : "Tag & Push")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isPushing ? Color.gray : Color.purple)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                            .disabled(newTag.isEmpty || isPushing)
                        }
                    }
                    
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Output")
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
                    
                    if let error = errorMessage {
                        HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                            .font(.system(size: 11)).foregroundColor(.axError)
                            .padding(AXSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axError.opacity(0.08)).cornerRadius(6)
                    }
                    if let success = successMessage {
                        HStack(spacing: 6) { Image(systemName: "checkmark.circle.fill"); Text(success) }
                            .font(.system(size: 11)).foregroundColor(.axSuccess)
                            .padding(AXSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axSuccess.opacity(0.08)).cornerRadius(6)
                    }
                }
                .padding(AXSpacing.lg)
            }
        }
        .frame(width: 500, height: 480)
        .background(Color.axBackground)
    }
    
    private func tagImage() {
        isTagging = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                try await DockerService.shared.tagImage(id: image.id, newTag: fullNewTag, serverId: serverId)
                await MainActor.run { successMessage = "Tagged as \(fullNewTag)"; isTagging = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isTagging = false }
            }
        }
    }
    
    private func pushImage() {
        isPushing = true; errorMessage = nil; successMessage = nil; output = ""
        Task {
            do {
                // Tag first
                try await DockerService.shared.tagImage(id: image.id, newTag: fullNewTag, serverId: serverId)
                
                // Push
                let result = try await DockerService.shared.pushImage(tag: fullNewTag, serverId: serverId)
                await MainActor.run {
                    output = result
                    successMessage = "Pushed \(fullNewTag) successfully"
                    isPushing = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isPushing = false }
            }
        }
    }
}
