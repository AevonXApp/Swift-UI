//
//  OptimizationSaveHelper.swift
//  AevonX
//
//  Canonical parser for the "save optimization" response pattern shared by
//  every application optimization section (PHP, Nginx, Apache, MySQL,
//  PostgreSQL, Redis, LiteSpeed, OPcache).
//
//  Core's response shape (AppSaveOptimization in exports_applications.go):
//
//     {
//       "success": true,              // outer — did the SSH round-trip work
//       "data": {
//         "saved": true,              // did the shell reach OPTIMIZATION_SAVED
//         "needs_restart": false,     // marker contained RESTART_REQUIRED
//         "stdout": "..."             // raw command output
//       },
//       "time": 1776142547
//     }
//
//  The OLD bug: every section read the outer `success` only — meaning the
//  SSH call was transported — and displayed "saved" even when `data.saved`
//  was false or the shell command actually failed. This helper checks both
//  layers and reloads from the server so the UI reflects reality.
//

import Foundation

/// Outcome of a save-optimization SSH roundtrip.
public enum OptSaveResult {
    /// Changes persisted AND the service was hot-reloaded. UI: green toast +
    /// refresh from server.
    case ok(stdout: String)

    /// Changes persisted but the service needs a manual restart before they
    /// take effect (databases: MySQL, PostgreSQL). UI: yellow warning.
    case okNeedsRestart(stdout: String)

    /// Something went wrong — malformed envelope, `saved == false`, or Core
    /// returned `success == false`.
    case failed(reason: String, stdout: String, stderr: String)
}

public func parseOptSaveResponse(_ raw: String) -> OptSaveResult {
    guard let data = raw.data(using: .utf8),
          let outer = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return .failed(reason: "Core returned malformed JSON", stdout: raw, stderr: "")
    }

    // Outer envelope check (SSH transport).
    let coreSuccess = (outer["success"] as? Bool) ?? false
    if !coreSuccess {
        let err = (outer["error"] as? String) ?? "SSH call failed"
        return .failed(reason: err, stdout: "", stderr: raw)
    }

    guard let inner = outer["data"] as? [String: Any] else {
        return .failed(reason: "Core envelope missing data block", stdout: raw, stderr: "")
    }

    let stdout = (inner["stdout"] as? String) ?? ""
    let saved = (inner["saved"] as? Bool) ?? false
    let needsRestart = (inner["needs_restart"] as? Bool) ?? false

    if !saved {
        // Command ran but didn't reach the persistence step (marker missing).
        return .failed(
            reason: "Command ran but didn't persist (missing save marker)",
            stdout: stdout,
            stderr: ""
        )
    }

    return needsRestart ? .okNeedsRestart(stdout: stdout) : .ok(stdout: stdout)
}

@MainActor
public func showOptSaveToast(_ result: OptSaveResult, appTitle: String, rawEnvelope: String) {
    switch result {
    case .ok(let stdout):
        GlobalToastManager.shared.showSuccess(
            "\(appTitle) saved and reloaded",
            details: "stdout:\n\(stdout)\n\n── envelope ──\n\(rawEnvelope)",
            detailsTitle: appTitle
        )
    case .okNeedsRestart(let stdout):
        GlobalToastManager.shared.showWarning(
            "\(appTitle) saved — restart required to apply",
            details: """
            stdout:
            \(stdout)

            These directives take effect only after a full service restart.
            Connections may drop briefly.

            ── envelope ──
            \(rawEnvelope)
            """,
            detailsTitle: appTitle
        )
    case .failed(let reason, let stdout, let stderr):
        GlobalToastManager.shared.showError(
            "\(appTitle) save failed",
            details: """
            reason: \(reason)

            stdout:
            \(stdout.isEmpty ? "(empty)" : stdout)

            stderr:
            \(stderr.isEmpty ? "(empty)" : stderr)

            ── envelope ──
            \(rawEnvelope)
            """,
            detailsTitle: appTitle
        )
    }
}
