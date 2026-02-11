
import SwiftUI
import AevonXCore

struct DockerImagesTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    
    @State private var images: [DockerImage] = []
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var errorMessage: String?
    @State private var actionInProgress: String? // ID of image being acted upon
    @State private var showPullSheet: Bool = false
    
    // Filtered images
    var filteredImages: [DockerImage] {
        if searchText.isEmpty {
            return images
        }
        return images.filter {
            $0.repository.localizedCaseInsensitiveContains(searchText) ||
            $0.tag.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Toolbar
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextSecondary)
                    TextField("Search images...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.axTextPrimary)
                }
                .padding(8)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Pull Image Button
                Button(action: { showPullSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                        Text("Pull Image")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                // Refresh Button
                Button(action: refreshData) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.bottom, AXSpacing.sm)
            
            if let error = errorMessage {
                AXCard {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axError)
                        Text(error)
                            .foregroundColor(.axError)
                        Spacer()
                        Button(action: { errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }
            
            // Images List
            if isLoading && images.isEmpty {
                ProgressView("Loading images...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredImages.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextMuted)
                    Text("No images found")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axSurface.opacity(0.3))
                .cornerRadius(AXCornerRadius.md)
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(filteredImages) { image in
                            ImageRow(
                                image: image,
                                isActionInProgress: actionInProgress == image.id,
                                onRemove: {
                                    handleRemoveImage(id: image.id)
                                }
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshData()
        }
        .sheet(isPresented: $showPullSheet) {
            PullImageSheet(isOpen: $showPullSheet) { imageName in
                handlePullImage(imageName)
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                images = try await DockerManager.shared.getImages(serverId: serverId)
            } catch {
                errorMessage = "Failed to fetch images: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleRemoveImage(id: String) {
        guard actionInProgress == nil else { return }
        actionInProgress = id
        
        Task {
            do {
                try await DockerManager.shared.removeImage(id: id, force: false, serverId: serverId)
                
                // Refresh
                try await Task.sleep(nanoseconds: 500_000_000)
                refreshData() // Removed await
                
            } catch {
                errorMessage = "Failed to remove image: \(error.localizedDescription)"
            }
            actionInProgress = nil
        }
    }
    
    private func handlePullImage(_ imageName: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerManager.shared.pullImage(imageName, serverId: serverId)
                refreshData() // Removed await
            } catch {
                errorMessage = "Failed to pull image: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Subviews

private struct ImageRow: View {
    let image: DockerImage
    let isActionInProgress: Bool
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Icon
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(image.repository)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(image.tag)
                            .font(AXTypography.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .foregroundColor(.axAccentBlue)
                            .cornerRadius(4)
                    }
                    
                    Text(image.shortId)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .monospaced()
                }
                
                Spacer()
                
                // Details
                VStack(alignment: .trailing, spacing: 4) {
                    Text(image.size)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(image.created)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                
                // Actions
                if isActionInProgress {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 32)
                } else {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(isHovered ? .axError : .axTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.axSurface.opacity(0.5))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    .onHover { hover in isHovered = hover }
                    .help("Remove Image")
                }
            }
        }
    }
}

private struct PullImageSheet: View {
    @Binding var isOpen: Bool
    let onPull: (String) -> Void
    
    @State private var imageName: String = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("Pull Image")
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                TextField("e.g. nginx:latest or redis:alpine", text: $imageName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit {
                        if !imageName.isEmpty {
                            onPull(imageName)
                            isOpen = false
                        }
                    }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") {
                    isOpen = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.axSurface)
                .foregroundColor(.axTextPrimary)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                
                Button("Pull") {
                    if !imageName.isEmpty {
                        onPull(imageName)
                        isOpen = false
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(!imageName.isEmpty ? Color.axAccentBlue : Color.axSurface)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
                .disabled(imageName.isEmpty)
                .opacity(imageName.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400)
        .background(Color.axBackground)
    }
}
