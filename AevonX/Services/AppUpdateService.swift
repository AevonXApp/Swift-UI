//
//  AppUpdateService.swift
//  AevonX
//
//  Auto-update service: check, download, verify, install & relaunch
//

import SwiftUI
import Combine
import CryptoKit
import AevonXCoreBridge

// MARK: - Models

struct AppVersionInfo: Codable, Identifiable {
    let id: String
    let version: String
    let buildNumber: Int
    let changelog: String
    let downloadURL: String
    let downloadHash: String
    let downloadSize: Int64
    let isMandatory: Bool
    let releasedAt: String

    enum CodingKeys: String, CodingKey {
        case id, version, changelog
        case buildNumber = "build_number"
        case downloadURL = "download_url"
        case downloadHash = "download_hash"
        case downloadSize = "download_size"
        case isMandatory = "is_mandatory"
        case releasedAt = "released_at"
    }
}

struct CheckUpdateResponse: Codable {
    let updateAvailable: Bool
    let version: AppVersionInfo?
    let forceUpdate: Bool?
    let forceReason: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case version, message
        case updateAvailable = "update_available"
        case forceUpdate = "force_update"
        case forceReason = "force_reason"
    }
}

struct DownloadUpdateResponse: Codable {
    let downloadURL: String
    let hash: String
    let size: Int64
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case hash, size
        case downloadURL = "download_url"
        case expiresAt = "expires_at"
    }
}

// MARK: - State

enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable
    case downloading(progress: Double)
    case downloaded
    case installing
    case error(String)

    static func == (lhs: UpdateState, rhs: UpdateState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.checking, .checking), (.upToDate, .upToDate),
             (.updateAvailable, .updateAvailable), (.downloaded, .downloaded),
             (.installing, .installing):
            return true
        case (.downloading(let a), .downloading(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Service

@MainActor
final class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()

    @Published var state: UpdateState = .idle
    @Published var availableVersion: AppVersionInfo?
    @Published var downloadProgress: Double = 0
    @Published var isForceUpdate: Bool = false

    @AppStorage(SettingsKey.checkForUpdates) var autoCheck = true
    @AppStorage(SettingsKey.updateChannel) var channel = "stable"
    @AppStorage(SettingsKey.autoDownloadUpdates) var autoDownload = true
    @AppStorage(SettingsKey.skippedVersion) var skippedVersion = ""

    @AppStorage(SettingsKey.updateCheckInterval) private var checkIntervalHours: Int = 6

    private var checkInterval: TimeInterval {
        TimeInterval(checkIntervalHours) * 60 * 60
    }
    private var lastCheckDate: Date?
    private var downloadTask: URLSessionDownloadTask?
    private var downloadDelegate: DownloadDelegate?

    private var baseURL: String {
        AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Check for Update

    func checkForUpdate(silent: Bool = false) async {
        if !silent { state = .checking }

        do {
            let token = try await getToken()
            var request = URLRequest(url: URL(string: "\(baseURL)/app/check-update")!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(currentVersion, forHTTPHeaderField: "X-App-Version")
            request.setValue(currentBuild, forHTTPHeaderField: "X-Build-Number")
            request.setValue("macos", forHTTPHeaderField: "X-Platform")
            request.setValue(ProcessInfo.processInfo.operatingSystemVersionString, forHTTPHeaderField: "X-OS-Version")
            request.setValue(channel, forHTTPHeaderField: "X-Channel")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if !silent { state = .error("Server returned an error.") }
                return
            }

            let result = try JSONDecoder().decode(CheckUpdateResponse.self, from: data)
            lastCheckDate = Date()

            if result.updateAvailable, let version = result.version {
                // Skip if user already skipped this version (unless force)
                let force = result.forceUpdate ?? false
                if !force && version.version == skippedVersion {
                    state = .upToDate
                    return
                }

                availableVersion = version
                isForceUpdate = force
                state = .updateAvailable

                if autoDownload && !force {
                    await downloadUpdate()
                }
            } else {
                if !silent { state = .upToDate }
            }
        } catch {
            if !silent { state = .error(error.localizedDescription) }
        }
    }

    // MARK: - Download Update

    func downloadUpdate() async {
        guard let version = availableVersion else { return }

        do {
            let token = try await getToken()
            var request = URLRequest(url: URL(string: "\(baseURL)/app/download-update/\(version.id)")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                state = .error("Failed to get download URL.")
                return
            }

            let downloadInfo = try JSONDecoder().decode(DownloadUpdateResponse.self, from: data)

            guard let url = URL(string: downloadInfo.downloadURL) else {
                state = .error("Invalid download URL.")
                return
            }

            state = .downloading(progress: 0)
            downloadProgress = 0

            let delegate = DownloadDelegate { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                    self?.state = .downloading(progress: progress)
                }
            }
            self.downloadDelegate = delegate

            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let (localURL, _) = try await session.download(from: url)

            // Move to persistent temp location
            let destURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("AevonX-\(version.version).zip")
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: localURL, to: destURL)

            // Verify hash
            let expectedHash = downloadInfo.hash.replacingOccurrences(of: "sha256:", with: "")
            let fileData = try Data(contentsOf: destURL)
            let computedHash = SHA256.hash(data: fileData)
                .compactMap { String(format: "%02x", $0) }
                .joined()

            guard computedHash == expectedHash else {
                try? FileManager.default.removeItem(at: destURL)
                state = .error("Download verification failed. Please try again.")
                return
            }

            state = .downloaded

            // Report success
            await reportUpdate(versionId: version.id, status: "downloaded")

        } catch {
            state = .error("Download failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Install & Relaunch

    func installAndRelaunch() async {
        guard let version = availableVersion else { return }

        state = .installing

        let zipPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("AevonX-\(version.version).zip")

        guard FileManager.default.fileExists(atPath: zipPath.path) else {
            state = .error("Downloaded file not found. Please download again.")
            return
        }

        let currentAppPath = Bundle.main.bundlePath
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AevonX-Update-\(UUID().uuidString)")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Unzip
            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            unzipProcess.arguments = ["-o", zipPath.path, "-d", tempDir.path]
            unzipProcess.standardOutput = nil
            unzipProcess.standardError = nil
            try unzipProcess.run()
            unzipProcess.waitUntilExit()

            guard unzipProcess.terminationStatus == 0 else {
                state = .error("Failed to extract update.")
                return
            }

            // Find the .app bundle in extracted contents
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
                state = .error("Invalid update package.")
                return
            }

            // Write updater script
            let pid = ProcessInfo.processInfo.processIdentifier
            let script = """
            #!/bin/bash
            while kill -0 \(pid) 2>/dev/null; do
                sleep 0.2
            done
            rm -rf "\(currentAppPath)"
            mv "\(appBundle.path)" "\(currentAppPath)"
            open "\(currentAppPath)"
            rm -rf "\(tempDir.path)"
            rm -rf "\(zipPath.path)"
            rm -- "$0"
            """

            let scriptPath = tempDir.appendingPathComponent("update.sh")
            try script.write(to: scriptPath, atomically: true, encoding: .utf8)

            // Make executable
            let chmod = Process()
            chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmod.arguments = ["+x", scriptPath.path]
            try chmod.run()
            chmod.waitUntilExit()

            // Launch updater detached
            let updater = Process()
            updater.executableURL = URL(fileURLWithPath: "/bin/bash")
            updater.arguments = [scriptPath.path]
            updater.standardOutput = nil
            updater.standardError = nil
            try updater.run()

            // Report and quit
            await reportUpdate(versionId: version.id, status: "installing")
            NSApplication.shared.terminate(nil)

        } catch {
            state = .error("Install failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Skip Version

    func skipVersion() {
        if let version = availableVersion {
            skippedVersion = version.version
        }
        state = .idle
        availableVersion = nil
        isForceUpdate = false
    }

    // MARK: - Auto-Check on Launch

    func checkOnLaunchIfNeeded() {
        guard autoCheck else { return }
        if let last = lastCheckDate, Date().timeIntervalSince(last) < checkInterval {
            return
        }
        Task { await checkForUpdate(silent: true) }
    }

    // MARK: - Periodic Check

    func startPeriodicCheck() {
        guard autoCheck else { return }
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(checkInterval))
                guard autoCheck else { continue }
                await checkForUpdate(silent: true)
            }
        }
    }

    // MARK: - Helpers

    private func getToken() async throws -> String {
        guard let token = await AuthService.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        return token
    }

    private func reportUpdate(versionId: String, status: String) async {
        do {
            let token = try await getToken()
            var request = URLRequest(url: URL(string: "\(baseURL)/app/report-update")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode([
                "version_id": versionId,
                "status": status
            ])
            let _ = try? await URLSession.shared.data(for: request)
        } catch {}
    }

    var downloadedZipExists: Bool {
        guard let version = availableVersion else { return false }
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("AevonX-\(version.version).zip")
        return FileManager.default.fileExists(atPath: path.path)
    }

    var formattedDownloadSize: String {
        guard let version = availableVersion else { return "" }
        let mb = Double(version.downloadSize) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Double) -> Void

    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Handled by the async download call
    }
}
