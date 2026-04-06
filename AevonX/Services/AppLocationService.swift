//
//  AppLocationService.swift
//  AevonX
//
//  Detects app location and handles move-to-Applications flow
//

import SwiftUI
import Combine

@MainActor
final class AppLocationService: ObservableObject {
    static let shared = AppLocationService()

    @Published var didPrompt: Bool {
        didSet { UserDefaults.standard.set(didPrompt, forKey: SettingsKey.didPromptMoveToApplications) }
    }

    private init() {
        self.didPrompt = UserDefaults.standard.bool(forKey: SettingsKey.didPromptMoveToApplications)
    }

    private let appPath = Bundle.main.bundlePath

    // MARK: - Location Detection

    var isInApplicationsFolder: Bool {
        appPath.hasPrefix("/Applications") ||
        appPath.hasPrefix(NSHomeDirectory() + "/Applications")
    }

    var isRunningFromDMG: Bool {
        appPath.hasPrefix("/Volumes/")
    }

    var isRunningFromDownloads: Bool {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
        return !downloads.isEmpty && appPath.hasPrefix(downloads)
    }

    var shouldPrompt: Bool {
        !isInApplicationsFolder && !didPrompt
    }

    // MARK: - Move to Applications

    func moveToApplications() {
        let appName = Bundle.main.bundleURL.lastPathComponent
        let destinationURL = URL(fileURLWithPath: "/Applications/\(appName)")
        let sourceURL = Bundle.main.bundleURL

        do {
            // Remove existing copy in Applications if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Copy app to /Applications
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            // If running from DMG, eject the volume after a short delay
            let dmgVolumePath = isRunningFromDMG ? extractVolumePath(from: appPath) : nil

            // Launch the copy from /Applications and terminate current instance
            let script = """
            #!/bin/bash
            sleep 0.5
            open "\(destinationURL.path)"
            \(dmgVolumePath.map { "sleep 1 && diskutil eject \"\($0)\" 2>/dev/null" } ?? "")
            rm -- "$0"
            """

            let scriptURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("aevonx-move-\(UUID().uuidString).sh")
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)

            let chmod = Process()
            chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmod.arguments = ["+x", scriptURL.path]
            try chmod.run()
            chmod.waitUntilExit()

            let launcher = Process()
            launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
            launcher.arguments = [scriptURL.path]
            launcher.standardOutput = nil
            launcher.standardError = nil
            try launcher.run()

            NSApplication.shared.terminate(nil)

        } catch {
            debugLog("[AppLocationService] ERROR: Failed to move to Applications: \(error.localizedDescription)")
        }
    }

    func dismissPrompt() {
        didPrompt = true
    }

    // MARK: - Helpers

    private func extractVolumePath(from path: String) -> String? {
        // /Volumes/AevonX/AevonX.app → /Volumes/AevonX
        let components = path.split(separator: "/")
        guard components.count >= 2, components[0] == "Volumes" else { return nil }
        return "/\(components[0])/\(components[1])"
    }
}
