
import SwiftUI
import AevonXCore

struct PHPExtensionsTab: View {
    let application: ApplicationInstance
    @Binding var phpConfig: PHPConfigData
    let serverId: String
    
    @State private var searchText = ""
    @State private var selectedFilter: ExtensionFilter = .all
    @State private var isInstalling: Set<String> = []
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    enum ExtensionFilter: String, CaseIterable {
        case all = "All"
        case cache = "Cache"
        case database = "Database"
        case graphics = "Graphics"
        case debug = "Debug"
        
        var extensionType: PHPExtension.ExtensionType? {
            switch self {
            case .all: return nil
            case .cache: return .cache
            case .database: return .database
            case .graphics: return .graphics
            case .debug: return .debug
            }
        }
    }
    
    var filteredExtensions: [PHPExtension] {
        let combined = phpConfig.installedExtensions + phpConfig.availableExtensions
        
        var filtered = combined.filter { ext in
            if !searchText.isEmpty {
                return ext.name.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        
        if let type = selectedFilter.extensionType {
            filtered = filtered.filter { $0.type == type }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Search Bar
            AXSearchBar(text: $searchText, placeholder: "Search extensions...")
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AXSpacing.sm) {
                    ForEach(ExtensionFilter.allCases, id: \.self) { filter in
                        PHPFilterPill(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                }
            }
            
            // Extensions List
            if filteredExtensions.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextTertiary)
                    Text("No extensions found")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.md) {
                        ForEach(filteredExtensions) { ext in
                            ExtensionCard(
                                ext: ext,
                                isInstalling: isInstalling.contains(ext.name),
                                onAction: { await handleExtensionAction(ext) }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func handleExtensionAction(_ extension: PHPExtension) async {
        isInstalling.insert(`extension`.name)
        
        do {
            if `extension`.isInstalled {
                try await ApplicationManager.shared.uninstallPHPExtension(`extension`.name, serverId: serverId)
                successMessage = "Extension \(`extension`.name) uninstalled successfully"
            } else {
                try await ApplicationManager.shared.installPHPExtension(`extension`.name, serverId: serverId)
                successMessage = "Extension \(`extension`.name) installed successfully"
            }
            
            // Refresh extensions list
            await refreshExtensions()
        } catch {
            errorMessage = "Failed to \(`extension`.isInstalled ? "uninstall" : "install") extension: \(error.localizedDescription)"
        }
        
        isInstalling.remove(`extension`.name)
    }
    
    private func refreshExtensions() async {
        do {
            let installedExts = try await ApplicationManager.shared.getInstalledPHPExtensions(serverId: serverId)
            let availableExts = try await ApplicationManager.shared.getAvailablePHPExtensions(serverId: serverId)
            
            await MainActor.run {
                phpConfig.installedExtensions = installedExts
                phpConfig.availableExtensions = availableExts
            }
        } catch {
            errorMessage = "Failed to refresh extensions: \(error.localizedDescription)"
        }
    }
}

private struct PHPFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AXTypography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                .background(isSelected ? Color.axAccentBlue : Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.full)
        }
        .buttonStyle(.plain)
    }
}

private struct ExtensionCard: View {
    let ext: PHPExtension
    let isInstalling: Bool
    let onAction: () async -> Void
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 20))
                .foregroundColor(typeColor)
                .frame(width: 40, height: 40)
                .background(typeColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AXSpacing.sm) {
                    Text(ext.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    
                    // Type Badge
                    Text(ext.type.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.15))
                        .cornerRadius(AXCornerRadius.xs)
                }
                
                Text(ext.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status Badge
            Text(ext.isInstalled ? "Installed" : "Not Installed")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ext.isInstalled ? .axSuccess : .axTextMuted)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                        .fill(ext.isInstalled ? Color.axSuccess.opacity(0.1) : Color.axSurface)
                )
            
            // Action Button
            Button(action: { Task { await onAction() } }) {
                if isInstalling {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(ext.isInstalled ? "Uninstall" : "Install")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 80, height: 32)
            .background(ext.isInstalled ? Color.axError : Color.axAccentBlue)
            .cornerRadius(AXCornerRadius.sm)
            .buttonStyle(.plain)
            .disabled(isInstalling)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var typeColor: Color {
        switch ext.type {
        case .cache: return .axAccentBlue
        case .database: return .green
        case .graphics: return .purple
        case .debug: return .orange
        case .security: return .red
        case .compression: return .yellow
        case .network: return .cyan
        case .other: return .axTextSecondary
        }
    }
}
