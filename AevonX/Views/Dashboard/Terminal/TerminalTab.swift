//
//  TerminalTab.swift
//  AevonX
//
//  Warp-inspired terminal tab.
//  SwiftTerm fills the full area. Suggestions appear above cursor. Real directory listing.
//

import SwiftUI
import AppKit
import AevonXCoreBridge

// MARK: - Main Tab

struct TerminalTab: View {

    let server: Server
    let serverId: String
    @ObservedObject var viewModel: ServerConnectionViewModel
    @EnvironmentObject var settings: AppSettingsManager

    @StateObject private var prefs = TerminalPreferences.shared
    @State private var sessions: [TerminalTabViewModel] = []
    @State private var activeIndex: Int = 0
    @State private var showSettings = false
    @State private var showFolderBrowser = false

    // Folder browser state
    @State private var dirContents: [String] = []
    @State private var isLoadingDirs = false

    private var active: TerminalTabViewModel? {
        sessions.indices.contains(activeIndex) ? sessions[activeIndex] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().background(Color.axBorder.opacity(0.3))
            if let s = active {
                pathBar(session: s)
                Divider().background(Color.axBorder.opacity(0.12))
                terminalArea(session: s)
            } else {
                prefs.theme.background.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(prefs.theme.background)
        .onAppear { if sessions.isEmpty { createSession() } }
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            if let s = active {
                TerminalSettingsSheet(viewModel: stubVM(s), preferences: prefs)
            }
        }
    }

    // MARK: - Terminal Area

    @ViewBuilder
    private func terminalArea(session: TerminalTabViewModel) -> some View {
        ZStack(alignment: .bottomLeading) {
            TerminalSwiftView(session: session, font: prefs.nsFont, theme: prefs.theme)
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 8)

            // Suggestions — appear ABOVE cursor line
            TerminalSuggestionOverlay(session: session, onSelect: { suggestion in
                selectSuggestion(suggestion, session: session)
            })
            .padding(.leading, 8)
        }
    }

    // MARK: - Path Bar

    private func pathBar(session: TerminalTabViewModel) -> some View {
        HStack(spacing: 0) {
            // Folder icon → opens browser popover
            Button(action: {
                showFolderBrowser = true
                loadDirectories(session: session)
            }) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.axAccentBlue.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showFolderBrowser, arrowEdge: .bottom) {
                folderBrowserPopover(session: session)
            }

            Divider().frame(height: 12).background(Color.axBorder.opacity(0.3))

            // Clickable path breadcrumb
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    if session.currentDirectory == "~" || session.currentDirectory.isEmpty {
                        Label("~", systemImage: "house")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                    } else {
                        Text("/")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color.axTextMuted.opacity(0.35))

                        ForEach(Array(session.pathSegments.enumerated()), id: \.offset) { idx, seg in
                            Button(action: {
                                session.write(text: "cd \(seg.path)\n")
                            }) {
                                Text(seg.label)
                                    .font(.system(
                                        size: 11,
                                        weight: idx == session.pathSegments.count - 1 ? .semibold : .regular,
                                        design: .monospaced
                                    ))
                                    .foregroundColor(
                                        idx == session.pathSegments.count - 1
                                            ? .axTextPrimary
                                            : .axTextSecondary
                                    )
                            }
                            .buttonStyle(.plain)

                            if idx < session.pathSegments.count - 1 {
                                Text("/")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color.axTextMuted.opacity(0.28))
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }

            Spacer()

            // Host (privacy-masked if enabled)
            Text(server.host)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted.opacity(0.55))
                .padding(.trailing, 14)
        }
        .frame(height: 28)
        .background(Color.axSurface.opacity(0.25))
    }

    // MARK: - Folder Browser Popover (real directory listing via SSHBridge)

    private func folderBrowserPopover(session: TerminalTabViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.axAccentBlue)
                    .font(.system(size: 12))
                Text(session.currentDirectory.isEmpty ? "~" : session.currentDirectory)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    loadDirectories(session: session)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().background(Color.axBorder.opacity(0.4))

            // Go up
            folderRow(icon: "arrow.up.circle", label: "../  Go up", color: .axTextSecondary) {
                session.write(text: "cd ..\n")
                showFolderBrowser = false
            }

            Divider().background(Color.axBorder.opacity(0.15))

            ScrollView {
                VStack(spacing: 0) {
                    if isLoadingDirs {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.6)
                                .padding(.trailing, 4)
                            Text(L10n.Terminal.loadingDirectories)
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)
                    } else if dirContents.isEmpty {
                        Text(L10n.Terminal.noSubdirectories)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                    } else {
                        ForEach(dirContents, id: \.self) { dir in
                            folderRow(icon: "folder.fill", label: dir, color: .axAccentBlue.opacity(0.7)) {
                                let path = session.currentDirectory == "~"
                                    ? "~/\(dir)"
                                    : "\(session.currentDirectory)/\(dir)"
                                session.write(text: "cd \"\(path)\"\n")
                                showFolderBrowser = false
                            }
                            Divider().background(Color.axBorder.opacity(0.1))
                        }
                    }
                }
            }
            .frame(maxHeight: 280)

            // Recent visited
            let recent = recentDirectories(from: session)
            if !recent.isEmpty {
                Divider().background(Color.axBorder.opacity(0.3))
                Text(L10n.Label.recent)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                ForEach(recent, id: \.self) { dir in
                    folderRow(icon: "clock", label: dir, color: .axTextMuted) {
                        session.write(text: "cd \"\(dir)\"\n")
                        showFolderBrowser = false
                    }
                }
            }

            Spacer().frame(height: 8)
        }
        .frame(width: 340)
        .background(Color.axBackground)
    }

    private func folderRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                    .frame(width: 14)
                Text(label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 9))
                    .foregroundColor(.axTextMuted.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load Real Directory Listing

    private func loadDirectories(session: TerminalTabViewModel) {
        guard session.isConnected else { return }
        isLoadingDirs = true
        dirContents = []
        let path = session.currentDirectory == "~" ? "$HOME" : session.currentDirectory

        Task {
            let output = await SSHBridge.shared.executeAsync(
                serverID: serverId,
                command: "ls -1p \"\(path)\" 2>/dev/null | grep '/$' | sed 's|/$||' | head -50"
            )
            let dirs = output
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix(".") }
                .sorted()
            await MainActor.run {
                dirContents = dirs
                isLoadingDirs = false
            }
        }
    }

    private func recentDirectories(from session: TerminalTabViewModel) -> [String] {
        var dirs: [String] = []
        var seen = Set<String>()
        for cmd in session.commandHistory.reversed() {
            let t = cmd.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("cd ") {
                let path = String(t.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                if !path.isEmpty && path != ".." && path != "-"
                    && seen.insert(path).inserted {
                    dirs.append(path)
                }
            }
            if dirs.count >= 5 { break }
        }
        return dirs
    }

    // MARK: - Suggestion Selection

    private func selectSuggestion(_ suggestion: String, session: TerminalTabViewModel) {
        let currentLen = session.currentInput.count
        if currentLen > 0 {
            session.write(data: Data(repeating: 0x7F, count: currentLen))
        }
        session.write(data: Data(suggestion.utf8))
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axAccentBlue)
                Text(L10n.Terminal.terminal)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.axTextPrimary)
            }
            .padding(.trailing, AXSpacing.xs)

            HStack(spacing: AXSpacing.xxs) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { i, s in
                    sessionTab(index: i, session: s)
                }
                Button(action: createSession) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 24, height: 24)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let s = active { connectionBadge(s) }

            Divider().frame(height: 16).background(Color.axBorder)

            tbBtn(icon: "trash", label: "Clear")        { active?.clear() }
            tbBtn(icon: "gearshape", label: "Settings") { showSettings = true }

            Button(action: { active?.disconnect() }) {
                HStack(spacing: 3) {
                    Image(systemName: "power").font(.system(size: 10))
                    Text(L10n.Terminal.disconnect).font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.axError)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 5)
                .background(Color.axError.opacity(0.08))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
    }

    private func sessionTab(index: Int, session: TerminalTabViewModel) -> some View {
        let isActive = index == activeIndex
        return Button(action: { activeIndex = index }) {
            HStack(spacing: 5) {
                Circle()
                    .fill(session.isConnected ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 5, height: 5)
                Text(session.sessionName)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)
                    .foregroundColor(isActive ? .axTextPrimary : .axTextSecondary)
                if sessions.count > 1 {
                    Button(action: { removeSession(at: index) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 5)
            .background(isActive ? Color.axAccentBlue.opacity(0.14) : Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func tbBtn(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 5)
            .background(Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func connectionBadge(_ s: TerminalTabViewModel) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Circle().fill(badgeColor(s)).frame(width: 6, height: 6)
            Text(badgeLabel(s))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(badgeColor(s))
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(badgeColor(s).opacity(0.08))
        .cornerRadius(AXCornerRadius.full)
    }

    private func badgeColor(_ s: TerminalTabViewModel) -> Color {
        switch s.connectionState {
        case .connected:                  return .axSuccess
        case .connecting, .reconnecting:  return .axWarning
        case .disconnected:               return .axTextMuted
        case .error:                      return .axError
        }
    }

    private func badgeLabel(_ s: TerminalTabViewModel) -> String {
        switch s.connectionState {
        case .connected:           return L10n.Terminal.connected
        case .connecting:          return L10n.Terminal.connecting
        case .reconnecting(let n): return "\(L10n.Terminal.reconnecting) (\(n))"
        case .disconnected:        return L10n.Terminal.disconnected
        case .error(let m):        return m
        }
    }

    // MARK: - Session Management

    private func createSession() {
        let n = sessions.count + 1
        let s = TerminalTabViewModel(serverId: serverId, name: "Session \(n)")
        sessions.append(s)
        activeIndex = sessions.count - 1
        Task { await s.connect(serverName: server.name, serverHost: server.host) }
    }

    private func removeSession(at index: Int) {
        guard sessions.indices.contains(index) else { return }
        sessions[index].disconnect()
        sessions.remove(at: index)
        activeIndex = max(0, min(activeIndex, sessions.count - 1))
        if sessions.isEmpty { createSession() }
    }

    private func stubVM(_ tab: TerminalTabViewModel) -> AXTerminalViewModel {
        AXTerminalViewModel(serverId: tab.serverId)
    }
}
