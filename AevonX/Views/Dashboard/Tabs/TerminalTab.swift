//
//  TerminalTab.swift
//  AevonX
//
//  Main Terminal tab — redesigned to match AevonX design system
//  Uses axColors, AXSpacing, AXCornerRadius, AXTypography
//  Follows CronTab toolbar pattern
//

import SwiftUI
import AevonXCoreBridge
import AppKit

// MARK: - Terminal Tab View

struct TerminalTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var viewModel: ServerConnectionViewModel
    @StateObject private var preferences = TerminalPreferences.shared
    @State private var showSettings = false
    @State private var showSnippets = false
    
    // Active session
    private var activeVM: TerminalViewModel? {
        guard viewModel.terminalSessions.indices.contains(viewModel.activeTerminalIndex) else {
            return nil
        }
        return viewModel.terminalSessions[viewModel.activeTerminalIndex]
    }
    
    init(server: Server, serverId: String, viewModel: ServerConnectionViewModel) {
        self.server = server
        self.serverId = serverId
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar (matches CronTab pattern)
            toolbar
            
            Divider().background(Color.axBorder)
            
            // Search bar (conditional)
            if let vm = activeVM, vm.isSearchVisible {
                TerminalSearchBar(viewModel: vm)
            }
            
            // Danger warning (conditional)
            if let vm = activeVM, let warning = vm.dangerWarning {
                dangerWarningBar(warning: warning, vm: vm)
            }
            
            // Terminal content
            ZStack {
                if let terminalVM = activeVM {
                    TerminalView(viewModel: terminalVM, preferences: preferences)
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            if let vm = activeVM {
                TerminalSettingsSheet(viewModel: vm, preferences: preferences)
            }
        }
        .popover(isPresented: $showSnippets, arrowEdge: .bottom) {
            if let vm = activeVM {
                TerminalSnippetsSheet(viewModel: vm)
            }
        }
        .onDisappear {
            activeVM?.commandSuggestions = []
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        VStack(spacing: 0) {
            // Row 1: Title + Connection info
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                    Text("Terminal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }
                
                Spacer()
                
                // Connection info
                if let vm = activeVM {
                    connectionBadge(vm: vm)
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.md)
            
            // Row 2: Session tabs + Actions
            HStack(spacing: AXSpacing.md) {
                // Session tabs
                sessionTabs
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.md)
        }
    }
    
    // MARK: - Session Tabs
    
    private var sessionTabs: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.terminalSessions.indices, id: \.self) { index in
                sessionTab(index: index)
            }
            
            // New session button
            Button(action: { viewModel.createTerminalSession() }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("New")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func sessionTab(index: Int) -> some View {
        let isActive = viewModel.activeTerminalIndex == index
        let session = viewModel.terminalSessions[index]
        
        return Button(action: {
            viewModel.activeTerminalIndex = index
            session.sessionInfo.hasUnreadOutput = false
        }) {
            HStack(spacing: AXSpacing.xs) {
                // Activity indicator
                Circle()
                    .fill(session.isConnected ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 6, height: 6)
                
                // Unread dot
                if session.sessionInfo.hasUnreadOutput && !isActive {
                    Circle()
                        .fill(Color.axAccentBlue)
                        .frame(width: 5, height: 5)
                }
                
                Image(systemName: "terminal")
                    .font(.system(size: 10))
                
                Text(session.sessionInfo.name + " \(index + 1)")
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)
                
                // Close button
                if viewModel.terminalSessions.count > 1 {
                    Button(action: { viewModel.closeTerminalSession(at: index) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isActive ? .axTextSecondary : .axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(isActive ? .axTextPrimary : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 7)
            .background(isActive ? Color.axAccentBlue.opacity(0.15) : Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
        .padding(.trailing, AXSpacing.xxs)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: AXSpacing.sm) {
            // Search
            toolbarButton(icon: "magnifyingglass", label: "Search") {
                activeVM?.toggleSearch()
            }
            
            // Snippets
            toolbarButton(icon: "text.page.badge.magnifyingglass", label: "Snippets") {
                showSnippets = true
            }
            
            // Clear
            toolbarButton(icon: "trash", label: "Clear") {
                activeVM?.clear()
            }
            
            // Settings
            toolbarButton(icon: "gearshape", label: "Settings") {
                showSettings = true
            }
            
            Divider()
                .frame(height: 20)
                .background(Color.axBorder)
            
            // Disconnect
            Button(action: { activeVM?.disconnect() }) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "power")
                        .font(.system(size: 10))
                    Text("Disconnect")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.axError)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 6)
                .background(Color.axError.opacity(0.08))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 6)
            .background(Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Connection Badge
    
    private func connectionBadge(vm: TerminalViewModel) -> some View {
        HStack(spacing: AXSpacing.sm) {
            if vm.isConnected {
                HStack(spacing: AXSpacing.xs) {
                    Text(server.name)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                    
                    Text(server.host)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                        .lineLimit(1)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
            }
            
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(statusColor(for: vm))
                    .frame(width: 7, height: 7)
                Text(statusText(for: vm))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor(for: vm))
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs)
            .background(statusColor(for: vm).opacity(0.08))
            .cornerRadius(AXCornerRadius.full)
        }
    }
    
    private func statusColor(for vm: TerminalViewModel) -> Color {
        switch vm.state {
        case .connected: return .axSuccess
        case .connecting, .reconnecting: return .axWarning
        case .disconnected: return .axTextMuted
        case .error: return .axError
        }
    }
    
    private func statusText(for vm: TerminalViewModel) -> String {
        switch vm.state {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .reconnecting(let attempt): return "Reconnecting (\(attempt))..."
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
    
    // MARK: - Danger Warning
    
    private func dangerWarningBar(warning: DangerousCommandDetector.Analysis, vm: TerminalViewModel) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: warning.level == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(warning.level == .critical ? .axError : .axWarning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("⚠️ Dangerous Command Detected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(warning.reason)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                if let suggestion = warning.suggestion {
                    Text("💡 \(suggestion)")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                }
            }
            
            Spacer()
            
            HStack(spacing: AXSpacing.sm) {
                Button(action: { vm.cancelDangerousCommand() }) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 5)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { vm.confirmDangerousCommand() }) {
                    Text("Execute Anyway")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 5)
                        .background(Color.axError)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axError.opacity(0.06))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.axError.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "terminal.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.axAccentBlue.opacity(0.5))
            }
            
            Text("Initializing Terminal...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Establishing secure shell session")
                .font(AXTypography.body)
                .foregroundColor(.axTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
