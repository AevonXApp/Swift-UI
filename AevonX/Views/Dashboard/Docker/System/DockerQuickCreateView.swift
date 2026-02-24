
import SwiftUI
import AevonXCore

struct DockerQuickCreateView: View {
    let serverId: String
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var image: String = ""
    @State private var ports: String = ""
    
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Quick Create Container")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXLabel("Container Name")
                        TextField("e.g. my-web-app", text: $name)
                            .textFieldStyle(AXTextFieldStyle())
                        
                        AXLabel("Image")
                        TextField("e.g. nginx:latest", text: $image)
                            .textFieldStyle(AXTextFieldStyle())
                        
                        AXLabel("Ports")
                        TextField("e.g. 8080:80, 443:443", text: $ports)
                            .textFieldStyle(AXTextFieldStyle())
                        
                        Text("Format: host_port:container_port. Separate multiple with commas.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .padding(AXSpacing.xl)
                    
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .padding()
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                        .padding(.horizontal, AXSpacing.xl)
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(AXSecondaryButtonStyle())
                
                Spacer()
                
                Button(action: createContainer) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 8)
                        }
                        Text(isCreating ? "Creating..." : "Run Container")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(isCreating || name.isEmpty || image.isEmpty)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }
    
    private func createContainer() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerManager.shared.runContainer(
                    name: name,
                    image: image,
                    ports: ports.isEmpty ? nil : ports,
                    serverId: serverId
                )
                
                await MainActor.run {
                    isCreating = false
                    onComplete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Reuse some styles if available or define placeholders
private struct AXLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(AXTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.axTextSecondary)
    }
}
