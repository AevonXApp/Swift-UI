//
//  PHPSessionsSection.swift
//  AevonX
//
//  Session handler & cleanup.
//

import SwiftUI
import AevonXCoreBridge

struct PHPSessionsSection: View {
    let serverId: String
    @State private var isLoading = true
    @State private var isCleaning = false

    @State private var handler = "files"
    @State private var savePath = "/tmp"
    @State private var gcMaxLifetime = "1440"
    @State private var cookieHttponly = false
    @State private var cookieSecure = false
    @State private var cookieSamesite = "Lax"
    @State private var useStrictMode = false
    @State private var activeCount = 0
    @State private var diskUsage = "0 B"

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Session Management", icon: "person.2.fill")

                if isLoading {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 3), spacing: AXSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in AXSkeletonStatCard() }
                    }
                    VStack(spacing: AXSpacing.md) {
                        ForEach(0..<5, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 3), spacing: AXSpacing.md) {
                        AXStatCard(icon: "person.2.fill", label: "Active Sessions", value: "\(activeCount)", color: .cyan, style: .glass)
                        AXStatCard(icon: "internaldrive.fill", label: "Disk Usage", value: diskUsage, color: .purple, style: .glass)
                        AXStatCard(icon: "gear.circle.fill", label: "Handler", value: handler, color: phpPurple, style: .glass)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Session Configuration", icon: "gearshape.fill")
                        sessionRow(label: "save_handler", value: handler)
                        sessionRow(label: "save_path", value: savePath)
                        sessionRow(label: "gc_maxlifetime", value: gcMaxLifetime)
                        sessionRow(label: "cookie_httponly", value: cookieHttponly ? "On" : "Off")
                        sessionRow(label: "cookie_secure", value: cookieSecure ? "On" : "Off")
                        sessionRow(label: "cookie_samesite", value: cookieSamesite)
                        sessionRow(label: "use_strict_mode", value: useStrictMode ? "On" : "Off")
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.3))
                    .cornerRadius(AXCornerRadius.lg)

                    Button {
                        Task { await cleanupSessions() }
                    } label: {
                        HStack {
                            if isCleaning { ProgressView().scaleEffect(0.65).frame(width: 14, height: 14) }
                            else { Image(systemName: "trash.fill") }
                            Text("Clean Expired Sessions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(Color.axWarning.opacity(0.15))
                        .foregroundColor(.axWarning)
                        .cornerRadius(AXCornerRadius.lg)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isCleaning)
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadSessionInfo() }
    }

    private func sessionRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextSecondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
        }
        .padding(.vertical, 4)
    }

    private func loadSessionInfo() async {
        isLoading = true
        let json = await bridge.getSessionInfo(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {
            handler = info["handler"] as? String ?? "files"
            savePath = info["save_path"] as? String ?? "/tmp"
            cookieHttponly = info["cookie_httponly"] as? Bool ?? false
            cookieSecure = info["cookie_secure"] as? Bool ?? false
            cookieSamesite = info["cookie_samesite"] as? String ?? "Lax"
            useStrictMode = info["strict_mode"] as? Bool ?? false
            activeCount = info["active_count"] as? Int ?? 0
            diskUsage = info["disk_usage"] as? String ?? "0 B"
            if let gc = info["gc_maxlifetime"] as? String { gcMaxLifetime = gc }
        }
        isLoading = false
    }

    private func cleanupSessions() async {
        isCleaning = true
        let json = await bridge.cleanupSessions(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            let cleaned = (resp["data"] as? [String: Any])?["cleaned"] as? Int ?? 0
            toast.showSuccess("\(cleaned) expired sessions cleaned")
            await loadSessionInfo()
        } else {
            toast.showError("Failed to clean sessions")
        }
        isCleaning = false
    }
}
