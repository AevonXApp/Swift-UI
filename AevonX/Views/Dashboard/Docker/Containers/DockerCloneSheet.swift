
import SwiftUI
import AevonXCoreBridge

struct DockerCloneSheet: View {
    let container: DockerContainer
    let serverId: String
    var onComplete: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @State private var isCloning = false
    @State private var progressMessage = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clone Container")
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)
                    Text("Clone \(container.names) with all its settings")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
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
            
            VStack(spacing: AXSpacing.md) {
                // Source container info
                AXCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Source Container", systemImage: "shippingbox")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        HStack {
                            Text("Name:")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            Text(container.names)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextPrimary)
                        }
                        
                        HStack {
                            Text("Image:")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            Text(container.image)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
                
                // New name input
                AXCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("New Container Name", systemImage: "pencil")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        TextField("Enter name for the clone", text: $newName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                if !progressMessage.isEmpty {
                    HStack {
                        ProgressView().scaleEffect(0.7)
                        Text(progressMessage)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                
                Spacer()
                
                // Clone Button
                Button {
                    cloneContainer()
                } label: {
                    if isCloning {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Clone Container", systemImage: "doc.on.doc")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)
                .padding()
                .background(newName.isEmpty || isCloning ? Color.axSurface : Color.axAccentBlue)
                .foregroundColor(newName.isEmpty || isCloning ? .axTextMuted : .white)
                .cornerRadius(AXCornerRadius.md)
                .disabled(newName.isEmpty || isCloning)
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 350)
        .background(Color.axBackground)
        .onAppear {
            newName = "\(container.names)-clone"
        }
    }
    
    private func cloneContainer() {
        isCloning = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerService.shared.cloneContainer(
                    containerId: container.id,
                    newName: newName,
                    serverId: serverId,
                    progress: { msg in
                        Task { @MainActor in progressMessage = msg }
                    }
                )
                await MainActor.run {
                    isCloning = false
                    onComplete?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCloning = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
