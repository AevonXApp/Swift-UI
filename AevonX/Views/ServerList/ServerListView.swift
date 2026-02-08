//
//  ServerListView.swift
//  AevonX
//
//  Remote Fleet - Server list with card/grid view, sorting, and view toggle
//

import SwiftUI

enum ServerViewMode {
    case list
    case grid
}

enum ServerEnvironment: String {
    case production = "production"
    case staging = "staging"
    case development = "development"
}

enum ServerSortOption {
    case nameAsc
    case nameDesc
    case dateAdded
    case status
    
    var label: String {
        switch self {
        case .nameAsc: return "Name A-Z"
        case .nameDesc: return "Name Z-A"
        case .dateAdded: return "Date Added"
        case .status: return "Status"
        }
    }
    
    var icon: String {
        switch self {
        case .nameAsc: return "arrow.up.arrow.down"
        case .nameDesc: return "arrow.up.arrow.down"
        case .dateAdded: return "calendar"
        case .status: return "circle.fill"
        }
    }
}

struct ServerListView: View {
    @Binding var servers: [Server]
    @Binding var selectedServer: Server?
    @State private var searchText = ""
    @State private var selectedFilter: ServerEnvironment? = nil
    @State private var viewMode: ServerViewMode = .grid
    @State private var sortOption: ServerSortOption = .nameAsc
    @State private var showSortMenu = false
    
    // Callbacks for server actions
    var onConnect: (Server) -> Void = { _ in }
    var onEdit: (Server) -> Void = { _ in }
    var onDelete: (Server) -> Void = { _ in }
    
    var filteredAndSortedServers: [Server] {
        // Only show remote servers in Remote Fleet
        let remoteServers = servers.filter { $0.type == .remote }
        
        let filtered = remoteServers.filter { server in
            let matchesSearch = searchText.isEmpty ||
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.host.localizedCaseInsensitiveContains(searchText) ||
                server.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            
            let matchesFilter = selectedFilter == nil || server.tags.contains(selectedFilter?.rawValue.lowercased() ?? "")
            
            return matchesSearch && matchesFilter
        }
        
        return filtered.sorted { s1, s2 in
            switch sortOption {
            case .nameAsc:
                return s1.name < s2.name
            case .nameDesc:
                return s1.name > s2.name
            case .dateAdded:
                return (s1.lastConnected ?? Date.distantPast) > (s2.lastConnected ?? Date.distantPast)
            case .status:
                return s1.status.rawValue < s2.status.rawValue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AXSpacing.xl) {
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("Remote Fleet")
                            .font(AXTypography.largeTitle)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("\(servers.filter { $0.status == .online }.count) of \(servers.count) servers online")
                            .font(AXTypography.callout)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "plus")
                            Text("Add Server")
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Search, Filter, Sort, and View Mode Bar
                HStack(spacing: AXSpacing.md) {
                    // Search
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.axTextMuted)
                        
                        TextField("Search servers...", text: $searchText)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .frame(width: 240)
                    
                    // Type Filters - Only Remote servers in Remote Fleet
                    HStack(spacing: AXSpacing.sm) {
                        FilterPill(
                            title: "All",
                            isSelected: selectedFilter == nil,
                            action: { selectedFilter = nil }
                        )
                        
                        FilterPill(
                            title: "Production",
                            isSelected: selectedFilter == .production,
                            action: { selectedFilter = .production }
                        )
                        
                        FilterPill(
                            title: "Staging",
                            isSelected: selectedFilter == .staging,
                            action: { selectedFilter = .staging }
                        )
                        
                        FilterPill(
                            title: "Development",
                            isSelected: selectedFilter == .development,
                            action: { selectedFilter = .development }
                        )
                    }
                    
                    Spacer()
                    
                    // Sort Menu
                    Menu {
                        ForEach([ServerSortOption.nameAsc, .nameDesc, .dateAdded, .status], id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                HStack {
                                    Image(systemName: option.icon)
                                    Text(option.label)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                    }
                    
                    // View Mode Toggle
                    HStack(spacing: AXSpacing.xs) {
                        Button(action: { viewMode = .grid }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 14))
                                .foregroundColor(viewMode == .grid ? .axBackground : .axTextSecondary)
                                .frame(width: 32, height: 32)
                                .background(viewMode == .grid ? Color.axAccentBlue : Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 14))
                                .foregroundColor(viewMode == .list ? .axBackground : .axTextSecondary)
                                .frame(width: 32, height: 32)
                                .background(viewMode == .list ? Color.axAccentBlue : Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    
                    // Import/Export
                    Menu {
                        Button("Import from JSON...") {}
                        Button("Import from CSV...") {}
                        Divider()
                        Button("Export All...") {}
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                    }
                }
            }
            .padding(AXSpacing.xxl)
            .background(Color.axBackground)
            
            Divider()
                .background(Color.axBorder)
            
            // Server Content
            ScrollView {
                if viewMode == .grid {
                    ServerGridView(
                        servers: filteredAndSortedServers,
                        selectedServer: $selectedServer,
                        onConnect: onConnect,
                        onEdit: onEdit,
                        onDelete: onDelete
                    )
                } else {
                    ServerListContentView(
                        servers: filteredAndSortedServers,
                        selectedServer: $selectedServer
                    )
                }
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
    }
}

// MARK: - Grid View
struct ServerGridView: View {
    let servers: [Server]
    @Binding var selectedServer: Server?
    let onConnect: (Server) -> Void
    let onEdit: (Server) -> Void
    let onDelete: (Server) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AXSpacing.md),
            GridItem(.flexible(), spacing: AXSpacing.md),
            GridItem(.flexible(), spacing: AXSpacing.md)
        ], spacing: AXSpacing.md) {
            ForEach(servers) { server in
                ServerCard(
                    server: server,
                    isSelected: selectedServer?.id == server.id,
                    onConnect: { onConnect(server) },
                    onEdit: { onEdit(server) },
                    onDelete: { onDelete(server) }
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedServer = server
                    }
                }
            }
        }
        .padding(AXSpacing.lg)
    }
}

// MARK: - List View
struct ServerListContentView: View {
    let servers: [Server]
    @Binding var selectedServer: Server?
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(servers.enumerated()), id: \.element.id) { index, server in
                ServerRow(
                    server: server,
                    isSelected: selectedServer?.id == server.id
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedServer = server
                    }
                }
                
                if index < servers.count - 1 {
                    Divider()
                        .background(Color.axBorder.opacity(0.5))
                        .padding(.horizontal, AXSpacing.xxl)
                }
            }
        }
        .padding(.vertical, AXSpacing.lg)
    }
}

// MARK: - Server Card (Grid View)
struct ServerCard: View {
    let server: Server
    let isSelected: Bool
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Header with Icon and Status
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(customColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: server.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(customColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(server.name)
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    Text(server.host)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            // Action buttons
            HStack(spacing: AXSpacing.sm) {
                // Connect button
                Button(action: onConnect) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("Connect")
                            .font(AXTypography.caption2)
                    }
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Edit button
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.axError)
                        .frame(width: 28, height: 28)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(isSelected ? Color.axAccentBlue.opacity(0.5) : Color.axBorder, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(
                    color: isSelected ? Color.axAccentBlue.opacity(0.15) : (isHovered ? Color.black.opacity(0.08) : Color.clear),
                    radius: isSelected ? 8 : (isHovered ? 4 : 0),
                    x: 0,
                    y: isSelected ? 2 : (isHovered ? 1 : 0)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var customColor: Color {
        Color(hex: server.customColor)
    }
    
    private var statusColor: Color {
        switch server.status {
        case .online: return .axSuccess
        case .offline: return .axTextMuted
        case .maintenance: return .axWarning
        case .error: return .axError
        }
    }
}

// MARK: - Card Vital
struct CardVital: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
            
            Text("\(Int(value))%")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AXTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .axBackground : isHovered ? .axTextPrimary : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(isSelected ? Color.axAccentBlue : (isHovered ? Color.axSurfaceHover : Color.axSurface))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.full)
                        .stroke(isSelected ? Color.clear : Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.full)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Server Row (List View)
struct ServerRow: View {
    let server: Server
    let isSelected: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            // Server Icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(serverTypeColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: serverIcon)
                    .font(.system(size: 20))
                    .foregroundColor(serverTypeColor)
            }
            
            // Server Info
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(server.name)
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    
                    if server.type == .local {
                        Text("LOCAL")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axAccentGreen)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axAccentGreen.opacity(0.12))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                }
                
                Text(server.type == .remote ? server.host : server.os ?? "Local Machine")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            // Tags
            HStack(spacing: AXSpacing.xs) {
                ForEach(server.tags.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextTertiary)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
            
            // Vitals Preview
            if let cpu = server.cpuUsage {
                HStack(spacing: AXSpacing.md) {
                    VitalPreview(label: "CPU", value: cpu, color: cpu > 80 ? .axError : .axAccentGreen)
                    
                    if let mem = server.memoryUsage {
                        VitalPreview(label: "RAM", value: mem, color: mem > 80 ? .axError : .axAccentBlue)
                    }
                }
                .frame(width: 120)
            }
            
            // Status
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(server.status.rawValue)
                    .font(AXTypography.caption)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs)
            .background(statusColor.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(isSelected ? Color.axAccentBlue.opacity(0.08) : (isHovered ? Color.axSurfaceHover.opacity(0.5) : Color.clear))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(isSelected ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.xs)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var serverIcon: String {
        switch server.type {
        case .remote:
            return "server.rack"
        case .local:
            return "desktopcomputer"
        }
    }
    
    private var serverTypeColor: Color {
        switch server.type {
        case .remote:
            return .axAccentBlue
        case .local:
            return .axAccentGreen
        }
    }
    
    private var statusColor: Color {
        switch server.status {
        case .online: return .axSuccess
        case .offline: return .axTextMuted
        case .maintenance: return .axWarning
        case .error: return .axError
        }
    }
}

struct VitalPreview: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
            
            Text("\(Int(value))%")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .monospaced()
        }
    }
}

#Preview {
    ServerListView(
        servers: .constant([]),
        selectedServer: .constant(nil)
    )
    .frame(width: 900, height: 700)
    .background(Color.axBackground)
}
