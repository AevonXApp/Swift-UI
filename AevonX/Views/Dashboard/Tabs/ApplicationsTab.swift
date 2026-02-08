//
//  ApplicationsTab.swift
//  AevonX
//
//  Applications/Stack management tab (Nginx, PHP, Docker, etc.)
//

import SwiftUI

// MARK: - Local Application Status
enum AppStatus: String, CaseIterable {
    case online = "Online"
    case offline = "Offline"
    case maintenance = "Maintenance"
    case error = "Error"
}

// MARK: - Local Application Model
struct AppModel: Identifiable {
    let id = UUID()
    var name: String
    var version: String
    var status: AppStatus
    var isRunning: Bool
    var autoStart: Bool
    var port: Int?
    var memoryUsage: Double?
}

struct ApplicationsTab: View {
    @State private var applications: [AppModel] = [
        AppModel(
            name: "Nginx",
            version: "1.24.0",
            status: .online,
            isRunning: true,
            autoStart: true,
            port: 80,
            memoryUsage: 45.2
        ),
        AppModel(
            name: "PHP-FPM",
            version: "8.2.10",
            status: .online,
            isRunning: true,
            autoStart: true,
            port: 9000,
            memoryUsage: 128.5
        ),
        AppModel(
            name: "MySQL",
            version: "8.0.34",
            status: .online,
            isRunning: true,
            autoStart: true,
            port: 3306,
            memoryUsage: 456.3
        ),
        AppModel(
            name: "Redis",
            version: "7.0.12",
            status: .online,
            isRunning: true,
            autoStart: true,
            port: 6379,
            memoryUsage: 32.1
        ),
        AppModel(
            name: "Docker",
            version: "24.0.5",
            status: .online,
            isRunning: true,
            autoStart: true,
            port: nil,
            memoryUsage: 234.7
        ),
        AppModel(
            name: "Supervisor",
            version: "4.2.5",
            status: .online,
            isRunning: true,
            autoStart: true,
            port: 9001,
            memoryUsage: 12.4
        ),
        AppModel(
            name: "Elasticsearch",
            version: "8.9.0",
            status: .offline,
            isRunning: false,
            autoStart: false,
            port: 9200,
            memoryUsage: nil
        )
    ]
    
    var runningApps: [AppModel] { applications.filter { $0.isRunning } }
    var stoppedApps: [AppModel] { applications.filter { !$0.isRunning } }
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Summary Cards
            HStack(spacing: AXSpacing.lg) {
                ServiceSummaryCard(
                    title: "Running",
                    count: runningApps.count,
                    total: applications.count,
                    color: .axSuccess,
                    icon: "checkmark.circle.fill"
                )
                
                ServiceSummaryCard(
                    title: "Stopped",
                    count: stoppedApps.count,
                    total: applications.count,
                    color: .axTextMuted,
                    icon: "xmark.circle.fill"
                )
                
                ServiceSummaryCard(
                    title: "Auto-start",
                    count: applications.filter { $0.autoStart }.count,
                    total: applications.count,
                    color: .axAccentBlue,
                    icon: "power"
                )
                
                ServiceSummaryCard(
                    title: "Memory Used",
                    count: Int(applications.compactMap { $0.memoryUsage }.reduce(0, +)),
                    total: 2048,
                    color: .axWarning,
                    icon: "memorychip",
                    isMemory: true
                )
            }
            
            // Services List
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Services")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10))
                                Text("Restart All")
                                    .font(AXTypography.caption)
                            }
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xs)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axBackgroundTertiary)
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    // Service Rows
                    ForEach(applications) { app in
                        ServiceRow(application: app)
                        
                        if app.id != applications.last?.id {
                            Divider()
                                .background(Color.axBorder)
                                .padding(.leading, AXSpacing.lg)
                        }
                    }
                }
            }
        }
    }
}

struct ServiceSummaryCard: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    let icon: String
    var isMemory: Bool = false
    
    var body: some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: AXSpacing.xs) {
                    Text(isMemory ? "\(count)" : "\(count)")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    if !isMemory {
                        Text("/ \(total)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    } else {
                        Text("MB")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ServiceRow: View {
    @State var application: AppModel
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon & Name
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(application.isRunning ? Color.axSuccess.opacity(0.15) : Color.axTextMuted.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: serviceIcon)
                        .font(.system(size: 16))
                        .foregroundColor(application.isRunning ? .axSuccess : .axTextMuted)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(application.name)
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    
                    Text("v\(application.version)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }
            .frame(width: 160, alignment: .leading)
            
            // Status
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(application.isRunning ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 6, height: 6)
                
                Text(application.isRunning ? "Running" : "Stopped")
                    .font(AXTypography.caption)
                    .foregroundColor(application.isRunning ? .axSuccess : .axTextMuted)
            }
            .frame(width: 80, alignment: .leading)
            
            // Port
            if let port = application.port {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "number")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    
                    Text("\(port)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .monospaced()
                }
                .frame(width: 70, alignment: .leading)
            } else {
                Text("-")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .frame(width: 70, alignment: .leading)
            }
            
            // Memory
            if let memory = application.memoryUsage {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView(value: min(memory / 500, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: memory > 400 ? .axError : .axAccentBlue))
                        .frame(width: 60)
                    
                    Text("\(String(format: "%.0f", memory)) MB")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .monospaced()
                }
                .frame(width: 130, alignment: .leading)
            } else {
                Text("-")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .frame(width: 130, alignment: .leading)
            }
            
            Spacer()
            
            // Auto-start Toggle
            HStack(spacing: AXSpacing.sm) {
                Text("Auto")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                
                Toggle("", isOn: $application.autoStart)
                    .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                    .frame(width: 36)
            }
            .frame(width: 80)
            
            // Actions
            HStack(spacing: AXSpacing.sm) {
                Button(action: { application.isRunning.toggle() }) {
                    Image(systemName: application.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(application.isRunning ? .axError : .axSuccess)
                        .frame(width: 32, height: 32)
                        .background((application.isRunning ? Color.axError : Color.axSuccess).opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 32, height: 32)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Menu {
                    Button("View Logs") {}
                    Button("Edit Configuration") {}
                    Divider()
                    Button("Check for Updates") {}
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
    }
    
    private var serviceIcon: String {
        switch application.name.lowercased() {
        case let name where name.contains("nginx"): return "server.rack"
        case let name where name.contains("php"): return "p.circle"
        case let name where name.contains("mysql"), let name where name.contains("mariadb"): return "cylinder"
        case let name where name.contains("redis"): return "bolt.fill"
        case let name where name.contains("docker"): return "shippingbox.fill"
        case let name where name.contains("supervisor"): return "eye.fill"
        case let name where name.contains("elastic"): return "magnifyingglass"
        default: return "gearshape.fill"
        }
    }
}

#Preview {
    ApplicationsTab()
        .padding()
        .background(Color.axBackground)
}
