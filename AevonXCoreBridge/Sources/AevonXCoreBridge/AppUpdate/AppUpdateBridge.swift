//
//  AppUpdateBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for the App self-update HTTP calls implemented in Go.
//  Replaces URLSession code in AevonX/Services/AppUpdateService.swift.
//
//  The actual binary download (signed CDN URL → local zip) still happens in
//  Swift via URLSessionDownloadTask because it needs OS-level progress
//  callbacks. The download URL itself is server-issued and contains no
//  client-side secrets.
//

import Foundation
import AevonXCoreLib

extension APIBridge {

    /// GET /app/check-update — returns CheckUpdateResponse JSON inside AuthServiceResult.
    public func checkAppUpdate(
        baseURL: String,
        token: String,
        appVersion: String,
        buildNumber: String,
        platform: String,
        osVersion: String,
        channel: String,
        language: String
    ) -> String {
        withCArgs { c in
            extractAppUpdate(APICheckAppUpdate(
                c.str(baseURL), c.str(token),
                c.str(appVersion), c.str(buildNumber),
                c.str(platform), c.str(osVersion),
                c.str(channel), c.str(language)
            ))
        }
    }

    /// POST /app/download-update/{id} — returns DownloadUpdateResponse JSON.
    public func requestAppUpdateDownload(baseURL: String, token: String, versionID: String) -> String {
        withCArgs { c in
            extractAppUpdate(APIRequestAppUpdateDownload(c.str(baseURL), c.str(token), c.str(versionID)))
        }
    }

    /// POST /app/report-update — telemetry. Caller usually ignores result.
    public func reportAppUpdate(baseURL: String, token: String, versionID: String, status: String) -> String {
        withCArgs { c in
            extractAppUpdate(APIReportAppUpdate(
                c.str(baseURL), c.str(token), c.str(versionID), c.str(status)
            ))
        }
    }

    // MARK: - Async wrappers

    public func checkAppUpdateAsync(
        baseURL: String,
        token: String,
        appVersion: String,
        buildNumber: String,
        platform: String,
        osVersion: String,
        channel: String,
        language: String
    ) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.checkAppUpdate(
                baseURL: baseURL, token: token,
                appVersion: appVersion, buildNumber: buildNumber,
                platform: platform, osVersion: osVersion,
                channel: channel, language: language
            )
        }.value
    }

    public func requestAppUpdateDownloadAsync(baseURL: String, token: String, versionID: String) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.requestAppUpdateDownload(baseURL: baseURL, token: token, versionID: versionID)
        }.value
    }

    public func reportAppUpdateAsync(baseURL: String, token: String, versionID: String, status: String) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.reportAppUpdate(baseURL: baseURL, token: token, versionID: versionID, status: status)
        }.value
    }

    // MARK: - Helper

    private func extractAppUpdate(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { free(cStr) }
        return String(cString: cStr)
    }
}
