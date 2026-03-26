
import SwiftUI
import AevonXCoreBridge

struct DockerImagesTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    @State private var images: [DockerImage] = []
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var errorMessage: String?
    @State private var actionInProgress: String? // ID of image being acted upon
    @State private var showPullSheet: Bool = false
    @State private var showHubSearch: Bool = false
    @State private var selectedImageForLayers: DockerImage?
    @State private var selectedImageForTagPush: DockerImage?
    
    // Confirmation handling
    @State private var imageToRemove: String?

    // Conflict handling
    @State private var showConflictAlert: Bool = false
    @State private var conflictingImageId: String?
    
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
                AXSearchBar(text: $searchText, placeholder: "Search images...")
                    .frame(maxWidth: 300)
                
                Spacer()
                
                // Pull Image Button
                Button(action: { showPullSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                        Text(L10n.Docker.pullImage)
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                // Docker Hub Search
                Button(action: { showHubSearch = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        Text("Search Hub")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                // Refresh Button
                AXRefreshIconButton(isLoading: isLoading) {
                    refreshData()
                }
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
                AXLoadingState(message: "Loading images...")
            } else if filteredImages.isEmpty {
                AXPlaceholder(
                    icon: "photo.stack",
                    title: "No images found"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(filteredImages) { image in
                            ImageRow(
                                image: image,
                                isActionInProgress: actionInProgress == image.id,
                                onRemove: {
                                    if settings.shouldConfirm(for: SettingsKey.confirmDeleteDockerImage) {
                                        imageToRemove = image.id
                                    } else {
                                        handleRemoveImage(id: image.id)
                                    }
                                },
                                onLayers: {
                                    selectedImageForLayers = image
                                },
                                onTagPush: {
                                    selectedImageForTagPush = image
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
        .sheet(isPresented: $showHubSearch) {
            DockerHubSearchView(serverId: serverId)
        }
        .sheet(item: $selectedImageForLayers) { image in
            DockerImageLayerInspector(image: image, serverId: serverId)
        }
        .sheet(item: $selectedImageForTagPush) { image in
            DockerImageTagPush(image: image, serverId: serverId)
        }
        .overlay {
            if let id = imageToRemove {
                AXDeleteConfirmation(
                    title: L10n.Docker.removeImage,
                    itemName: id,
                    icon: "photo",
                    warning: "This will permanently remove the Docker image.",
                    confirmLabel: L10n.Button.remove,
                    onConfirm: {
                        imageToRemove = nil
                        handleRemoveImage(id: id)
                    },
                    onCancel: { imageToRemove = nil }
                )
            }
            if showConflictAlert, let id = conflictingImageId {
                AXDeleteConfirmation(
                    title: "Image Conflict",
                    itemName: id,
                    warning: "This image is being used by one or more containers. Force remove it?",
                    confirmLabel: "Force Remove",
                    onConfirm: {
                        showConflictAlert = false
                        handleRemoveImage(id: id, force: true)
                    },
                    onCancel: {
                        showConflictAlert = false
                        conflictingImageId = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                images = try await DockerService.shared.getImages(serverId: serverId)
            } catch {
                errorMessage = "Failed to fetch images: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleRemoveImage(id: String, force: Bool = false) {
        guard actionInProgress == nil else { return }
        actionInProgress = id
        
        Task {
            do {
                try await DockerService.shared.removeImage(id: id, force: force, serverId: serverId)
                
                // Refresh
                try await Task.sleep(nanoseconds: 500_000_000)
                refreshData()
                
            } catch {
                let errorDesc = error.localizedDescription
                if errorDesc.lowercased().contains("conflict") || errorDesc.lowercased().contains("must be forced") {
                    conflictingImageId = id
                    showConflictAlert = true
                } else {
                    errorMessage = "Failed to remove image: \(errorDesc)"
                }
            }
            actionInProgress = nil
        }
    }
    
    private func handlePullImage(_ imageName: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerService.shared.pullImage(imageName, serverId: serverId)
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
    let onLayers: () -> Void
    let onTagPush: () -> Void
    
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
                    HStack(spacing: AXSpacing.sm) {
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
                    HStack(spacing: 6) {
                        Button(action: onLayers) {
                            Image(systemName: "square.stack.3d.down.right")
                                .font(.system(size: 14))
                                .foregroundColor(.axAccentBlue)
                                .frame(width: 32, height: 32)
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.Docker.viewLayers)

                        Button(action: onTagPush) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.purple)
                                .frame(width: 32, height: 32)
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.Docker.tagPush)

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
                        .help(L10n.Docker.removeImage)
                    }
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
            Text(L10n.Docker.pullImage)
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
                Button(L10n.Button.cancel) {
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
