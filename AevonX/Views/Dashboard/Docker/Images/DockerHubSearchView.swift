
import SwiftUI
import AevonXCore

struct DockerHubSearchView: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery: String = ""
    @State private var results: [HubSearchResult] = []
    @State private var isSearching = false
    @State private var isPulling: String? = nil
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    struct HubSearchResult: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let stars: Int
        let isOfficial: Bool
        let isAutomated: Bool
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.axAccentBlue)
                Text("Docker Hub")
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
            
            // Search bar
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.axTextMuted)
                    .font(.system(size: 12))
                TextField("Search Docker Hub...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { search() }
                
                if isSearching {
                    ProgressView().controlSize(.small)
                }
                
                Button(action: search) {
                    Text("Search")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.axAccentBlue)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(searchQuery.isEmpty || isSearching)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))
            
            Divider()
            
            // Results
            if results.isEmpty && !isSearching {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.axTextMuted)
                    Text("Search for Docker images")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                    Text("e.g. nginx, redis, postgres, node")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(results) { result in
                            HubResultRow(
                                result: result,
                                isPulling: isPulling == result.name,
                                onPull: { pullImage(result.name) }
                            )
                        }
                    }
                    .padding(AXSpacing.md)
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
                .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity)
                .background(Color.axSuccess.opacity(0.08))
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
    }
    
    // MARK: - Actions
    
    private func search() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                let hubResults = try await DockerManager.shared.searchHub(query: searchQuery, serverId: serverId)
                let mapped = hubResults.map {
                    HubSearchResult(name: $0.name, description: $0.description, stars: $0.stars, isOfficial: $0.isOfficial, isAutomated: $0.isAutomated)
                }
                await MainActor.run { results = mapped; isSearching = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isSearching = false }
            }
        }
    }
    
    private func pullImage(_ name: String) {
        isPulling = name
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await DockerManager.shared.pullImage(name, serverId: serverId)
                await MainActor.run {
                    successMessage = "Pulled \(name) successfully"
                    isPulling = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Pull failed: \(error.localizedDescription)"
                    isPulling = nil
                }
            }
        }
    }
}

// MARK: - Hub Result Row

private struct HubResultRow: View {
    let result: DockerHubSearchView.HubSearchResult
    let isPulling: Bool
    let onPull: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Image icon
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 18))
                .foregroundColor(.axAccentBlue)
                .frame(width: 36, height: 36)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(result.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    
                    if result.isOfficial {
                        Text("Official")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(result.description)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Stars
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
                Text("\(result.stars)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextSecondary)
            }
            
            // Pull button
            Button(action: onPull) {
                HStack(spacing: 4) {
                    if isPulling {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                    }
                    Text(isPulling ? "Pulling..." : "Pull")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isPulling ? Color.gray : Color.axAccentBlue)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(isPulling)
        }
        .padding(AXSpacing.sm)
        .background(isHovered ? Color.axSurfaceHover : Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        .onHover { isHovered = $0 }
    }
}
