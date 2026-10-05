//
//  InfrastructureBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Infrastructure operations.
//  Provides package catalog, presets, conflict detection, environment parsing,
//  server scanning, install step building, and queue management.
//

import Foundation
import AevonXCoreLib

public final class InfrastructureBridge: @unchecked Sendable {

    public static let shared = InfrastructureBridge()
    private init() {}

    // MARK: - Package Catalog

    /// Returns full package catalog JSON for quick install UI.
    public func getPackageCatalog() -> String {
        extract(InfraGetPackageCatalog())
    }

    /// Returns all preset stacks JSON.
    public func getPresets() -> String {
        extract(InfraGetPresets())
    }

    // MARK: - Conflict Detection

    /// Check for conflicts among selected packages.
    /// - Parameter selectionsJSON: JSON array of QISelection objects.
    public func detectConflicts(selectionsJSON: String) -> String {
        withCArgs { c in extract(InfraDetectConflicts(c.str(selectionsJSON))) }
    }

    // MARK: - Environment

    /// Decode and validate a ServerEnvironment JSON.
    public func decodeServerEnvironment(json: String) -> String {
        withCArgs { c in extract(InfraDecodeServerEnvironment(c.str(json))) }
    }

    /// Decode a server scan result and check if server is fresh.
    public func decodeServerScan(json: String) -> String {
        withCArgs { c in extract(InfraDecodeServerScan(c.str(json))) }
    }

    // MARK: - Quick Install: Scan

    /// Returns the SSH command to probe installed packages on a server.
    public func scanCommand() -> String {
        extract(InfraScanCommand())
    }

    /// Parses scan command stdout into packageId→version map JSON.
    public func parseScanOutput(stdout: String) -> String {
        withCArgs { c in extract(InfraParseScanOutput(c.str(stdout))) }
    }

    // MARK: - Quick Install: Build Steps

    /// Builds ordered install steps from selections.
    /// - Parameter json: JSON with selections, package_manager, installed_packages
    public func buildSteps(json: String) -> String {
        withCArgs { c in extract(InfraBuildSteps(c.str(json))) }
    }

    /// Returns the shell command for a specific install step.
    public func shellCommand(stepTitle: String, packageId: String, versionId: String, pkgMgr: String) -> String {
        withCArgs { c in extract(InfraShellCommand(c.str(stepTitle), c.str(packageId), c.str(versionId), c.str(pkgMgr))) }
    }

    /// Estimates install time in minutes for selected packages.
    /// - Parameters:
    ///   - selectionsJSON: JSON array of QISelection objects
    ///   - pkgMgr: Package manager type (apt, dnf, yum)
    public func estimatedMinutes(selectionsJSON: String, pkgMgr: String) -> String {
        withCArgs { c in extract(InfraEstimatedMinutes(c.str(selectionsJSON), c.str(pkgMgr))) }
    }

    // MARK: - Quick Install: Queue

    /// Generates the background install bash script.
    /// - Parameter json: JSON with steps and install_commands
    public func queueGenerateScript(json: String) -> String {
        withCArgs { c in extract(InfraQueueGenerateScript(c.str(json))) }
    }

    /// Parses raw poll output into QIQueueState JSON.
    public func queueParseState(raw: String) -> String {
        withCArgs { c in extract(InfraQueueParseState(c.str(raw))) }
    }

    // MARK: - Quick Install: SSH Commands

    /// Returns the SSH command to poll queue state files.
    public func pollCommand() -> String {
        extract(InfraPollCommand())
    }

    /// Returns the SSH command to cancel the running install.
    public func cancelCommand() -> String {
        extract(InfraCancelCommand())
    }

    /// Returns the SSH command to remove all queue files.
    public func cleanupCommand() -> String {
        extract(InfraCleanupCommand())
    }

    /// Returns the SSH command to check if an install is running.
    public func isRunningCommand() -> String {
        extract(InfraIsRunningCommand())
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }
}
