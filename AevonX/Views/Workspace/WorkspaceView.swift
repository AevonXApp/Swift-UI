//
//  WorkspaceView.swift
//  AevonX
//
//  Local Workspace - Project management for Laravel, Go, etc.
//

import SwiftUI
import AevonXCore

struct Project: Identifiable {
    let id = UUID()
    var name: String
    var type: ProjectType
    var path: String
    var status: ProjectStatus
    var lastOpened: Date
    var services: [ProjectService]
}

enum ProjectType: String, CaseIterable {
    case laravel = "Laravel"
    case go = "Go"
    case node = "Node.js"
    case python = "Python"
    case rust = "Rust"
    case docker = "Docker"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .laravel: return "laravel" // Custom or use generic
        case .go: return "g.circle"
        case .node: return "n.circle"
        case .python: return "p.circle"
        case .rust: return "r.circle"
        case .docker: return "shippingbox.fill"
        case .other: return "folder"
        }
    }
    
    var color: Color {
        switch self {
        case .laravel: return Color(hex: "#FF2D20")
        case .go: return Color(hex: "#00ADD8")
        case .node: return Color(hex: "#339933")
        case .python: return Color(hex: "#3776AB")
        case .rust: return Color(hex: "#DEA584")
        case .docker: return Color(hex: "#2496ED")
        case .other: return .axTextSecondary
        }
    }
}

enum ProjectStatus: String {
    case running = "Running"
    case stopped = "Stopped"
    case error = "Error"
    
    var color: Color {
        switch self {
        case .running: return .axSuccess
        case .stopped: return .axTextMuted
        case .error: return .axError
        }
    }
}

struct ProjectService: Identifiable {
    let id = UUID()
    var name: String
    var isRunning: Bool
    var port: Int?
}

struct WorkspaceView: View {
    @State private var projects: [Project] = [
        Project(
            name: "AevonX API",
            type: .laravel,
            path: "~/Projects/aevonx-api",
            status: .running,
            lastOpened: Date().addingTimeInterval(-3600),
            services: [
                ProjectService(name: "PHP Server", isRunning: true, port: 8000),
                ProjectService(name: "MySQL", isRunning: true, port: 3306),
                ProjectService(name: "Redis", isRunning: true, port: 6379)
            ]
        ),
        Project(
            name: "Microservices Gateway",
            type: .go,
            path: "~/Projects/gateway",
            status: .running,
            lastOpened: Date().addingTimeInterval(-7200),
            services: [
                ProjectService(name: "Go Server", isRunning: true, port: 8080),
                ProjectService(name: "gRPC", isRunning: true, port: 50051)
            ]
        ),
        Project(
            name: "Dashboard Frontend",
            type: .node,
            path: "~/Projects/dashboard",
            status: .stopped,
            lastOpened: Date().addingTimeInterval(-86400),
            services: [
                ProjectService(name: "Vite Dev", isRunning: false, port: 5173),
                ProjectService(name: "Storybook", isRunning: false, port: 6006)
            ]
        ),
        Project(
            name: "Data Pipeline",
            type: .python,
            path: "~/Projects/pipeline",
            status: .running,
            lastOpened: Date().addingTimeInterval(-172800),
            services: [
                ProjectService(name: "Celery Worker", isRunning: true, port: nil),
                ProjectService(name: "Flower", isRunning: true, port: 5555)
            ]
        ),
        Project(
            name: "Auth Service",
            type: .rust,
            path: "~/Projects/auth-service",
            status: .error,
            lastOpened: Date().addingTimeInterval(-259200),
            services: [
                ProjectService(name: "Rust Server", isRunning: false, port: 3000)
            ]
        )
    ]
    
    @State private var searchText = ""
    @State private var selectedType: ProjectType? = nil
    @State private var selectedProject: Project?
    
    var filteredProjects: [Project] {
        projects.filter { project in
            let matchesSearch = searchText.isEmpty ||
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.path.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || project.type == selectedType
            
            return matchesSearch && matchesType
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AXSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Local Workspace")
                            .font(AXTypography.largeTitle)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("\(projects.filter { $0.status == .running }.count) of \(projects.count) projects running")
                            .font(AXTypography.callout)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "plus")
                            Text("Add Project")
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Search & Filters
                HStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.axTextMuted)
                        
                        TextField("Search projects...", text: $searchText)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    
                    // Type Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.sm) {
                            FilterPill(
                                title: "All",
                                isSelected: selectedType == nil,
                                action: { selectedType = nil }
                            )
                            
                            ForEach(ProjectType.allCases, id: \.self) { type in
                                FilterPill(
                                    title: type.rawValue,
                                    isSelected: selectedType == type,
                                    action: { selectedType = type }
                                )
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(AXSpacing.xl)
            
            Divider()
                .background(Color.axBorder)
            
            // Projects Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AXSpacing.lg),
                    GridItem(.flexible(), spacing: AXSpacing.lg)
                ], spacing: AXSpacing.lg) {
                    ForEach(filteredProjects) { project in
                        ProjectCard(project: project, isSelected: selectedProject?.id == project.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedProject = project
                                }
                            }
                    }
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
    }
}

struct ProjectCard: View {
    let project: Project
    let isSelected: Bool
    
    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(project.type.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Text(String(project.type.rawValue.prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(project.type.color)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(project.name)
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(project.type.rawValue)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    
                    Spacer()
                    
                    StatusIndicator(status: projectStatus, showLabel: false, size: 8)
                }
                
                Divider()
                    .background(Color.axBorder)
                
                // Path
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    
                    Text(project.path)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                }
                
                // Services
                if !project.services.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Services")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                        
                        HStack(spacing: AXSpacing.xs) {
                            ForEach(project.services.prefix(3)) { service in
                                ServiceBadge(service: service)
                            }
                            
                            if project.services.count > 3 {
                                Text("+\(project.services.count - 3)")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                                    .padding(.horizontal, AXSpacing.xs)
                                    .padding(.vertical, AXSpacing.xxxs)
                                    .background(Color.axBackgroundTertiary)
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }
                
                // Footer
                HStack {
                    Text("Opened \(timeAgo(project.lastOpened))")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                    
                    Spacer()
                    
                    HStack(spacing: AXSpacing.xs) {
                        Button(action: {}) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.axSuccess)
                                .frame(width: 24, height: 24)
                                .background(Color.axSuccess.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(project.status == .running)
                        .opacity(project.status == .running ? 0.5 : 1)
                        
                        Button(action: {}) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.axError)
                                .frame(width: 24, height: 24)
                                .background(Color.axError.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(project.status != .running)
                        .opacity(project.status != .running ? 0.5 : 1)
                        
                        Button(action: {}) {
                            Image(systemName: "terminal")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextSecondary)
                                .frame(width: 24, height: 24)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(isSelected ? Color.axAccentBlue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    private var projectStatus: ServerStatus {
        switch project.status {
        case .running: return .online
        case .stopped: return .offline
        case .error: return .error
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        AXFormatter.formatTimeAgo(date)
    }
}

struct ServiceBadge: View {
    let service: ProjectService
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(service.isRunning ? Color.axSuccess : Color.axTextMuted)
                .frame(width: 4, height: 4)
            
            Text(service.name)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextSecondary)
            
            if let port = service.port {
                Text(":\(port)")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                    .monospaced()
            }
        }
        .padding(.horizontal, AXSpacing.xs)
        .padding(.vertical, AXSpacing.xxxs)
        .background(Color.axBackgroundTertiary)
        .cornerRadius(AXCornerRadius.sm)
    }
}

#Preview {
    WorkspaceView()
        .frame(width: 900, height: 700)
        .background(Color.axBackground)
}
