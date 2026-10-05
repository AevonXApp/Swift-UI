//
//  FilesBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core File Management operations.
//  Covers SFTP (remote file operations) and FTP (PureFTPd management).
//

import Foundation
import AevonXCoreLib

// MARK: - Files Bridge

public final class FilesBridge: @unchecked Sendable {

    public static let shared = FilesBridge()
    private init() {}

    // MARK: - SFTP — Directory & File

    public func listDirectoryCmd(path: String, showHidden: Bool = true) -> String {
        withCArgs { c in extract(SFTPListDirectoryCmd(c.str(path), showHidden ? 1 : 0)) }
    }

    public func readFileCmd(path: String) -> String {
        withCArgs { c in extract(SFTPReadFileCmd(c.str(path))) }
    }

    public func fileSizeCmd(path: String) -> String {
        withCArgs { c in extract(SFTPFileSizeCmd(c.str(path))) }
    }

    public func fileInfoCmd(path: String) -> String {
        withCArgs { c in extract(SFTPFileInfoCmd(c.str(path))) }
    }

    public func writeFileCmd(path: String, base64Content: String) -> String {
        withCArgs { c in extract(SFTPWriteFileCmd(c.str(path), c.str(base64Content))) }
    }

    public func downloadFromURLCmd(url: String, destPath: String) -> String {
        withCArgs { c in extract(SFTPDownloadFromURLCmd(c.str(url), c.str(destPath))) }
    }

    public func diskUsageCmd(path: String) -> String {
        withCArgs { c in extract(SFTPDiskUsageCmd(c.str(path))) }
    }

    // MARK: - SFTP — CRUD Operations

    public func deleteItemCmd(path: String) -> String { withCArgs { c in extract(SFTPDeleteItemCmd(c.str(path))) } }
    public func renameItemCmd(from oldPath: String, to newPath: String) -> String {
        withCArgs { c in extract(SFTPRenameItemCmd(c.str(oldPath), c.str(newPath))) }
    }
    public func createDirectoryCmd(path: String) -> String { withCArgs { c in extract(SFTPCreateDirectoryCmd(c.str(path))) } }
    public func changePermissionsCmd(path: String, mode: String) -> String {
        withCArgs { c in extract(SFTPChangePermissionsCmd(c.str(path), c.str(mode))) }
    }
    public func changeOwnerCmd(path: String, owner: String, group: String) -> String {
        withCArgs { c in extract(SFTPChangeOwnerCmd(c.str(path), c.str(owner), c.str(group))) }
    }
    public func copyItemCmd(from src: String, to dest: String) -> String {
        withCArgs { c in extract(SFTPCopyItemCmd(c.str(src), c.str(dest))) }
    }
    public func createFileCmd(path: String) -> String { withCArgs { c in extract(SFTPCreateFileCmd(c.str(path))) } }

    // MARK: - SFTP — Search & Archive

    public func searchFilesCmd(query: String, path: String, maxResults: Int = 100) -> String {
        withCArgs { c in extract(SFTPSearchFilesCmd(c.str(query), c.str(path), Int32(maxResults))) }
    }
    public func createSymlinkCmd(target: String, linkPath: String) -> String {
        withCArgs { c in extract(SFTPCreateSymlinkCmd(c.str(target), c.str(linkPath))) }
    }
    public func extractArchiveCmd(archivePath: String, destPath: String) -> String {
        withCArgs { c in extract(SFTPExtractArchiveCmd(c.str(archivePath), c.str(destPath))) }
    }

    public func searchContentCmd(query: String, path: String, caseSensitive: Bool = true, useRegex: Bool = true, maxResults: Int = 100) -> String {
        withCArgs { c in extract(SFTPSearchContentCmd(c.str(query), c.str(path), caseSensitive ? 1 : 0, useRegex ? 1 : 0, Int32(maxResults))) }
    }
    public func browseSubdirsCmd(path: String) -> String {
        withCArgs { c in extract(SFTPBrowseSubdirsCmd(c.str(path))) }
    }

    // MARK: - FTP — PureFTPd Management

    public func ftpCheckInstallationCmd() -> String { extract(FTPCheckInstallationCmd()) }
    public func ftpInstallCmd() -> String { extract(FTPInstallCmd()) }
    public func ftpSetupPureDBCmd() -> String { extract(FTPSetupPureDBCmd()) }
    public func ftpListUsersCmd() -> String { extract(FTPListUsersCmd()) }

    public func ftpAddUserCmd(username: String, password: String, docRoot: String, quota: Int = 0) -> String {
        withCArgs { c in extract(FTPAddUserCmd(c.str(username), c.str(password), c.str(docRoot), Int32(quota))) }
    }

    public func ftpDeleteUserCmd(username: String) -> String { withCArgs { c in extract(FTPDeleteUserCmd(c.str(username))) } }

    public func ftpToggleUserCmd(username: String, enable: Bool) -> String {
        withCArgs { c in extract(FTPToggleUserCmd(c.str(username), enable ? 1 : 0)) }
    }

    public func ftpChangePasswordCmd(username: String, newPassword: String) -> String {
        withCArgs { c in extract(FTPChangePasswordCmd(c.str(username), c.str(newPassword))) }
    }

    public func ftpChangePortCmd(port: Int) -> String { extract(FTPChangePortCmd(Int32(port))) }
    public func ftpRebuildDBCmd() -> String { extract(FTPRebuildDBCmd()) }

    // FTP Service Control
    public func ftpStartServiceCmd() -> String { extract(FTPStartServiceCmd()) }
    public func ftpStopServiceCmd() -> String { extract(FTPStopServiceCmd()) }
    public func ftpRestartServiceCmd() -> String { extract(FTPRestartServiceCmd()) }

    // FTP Logs & Verification
    public func ftpGetLogsCmd() -> String { extract(FTPGetLogsCmd()) }
    public func ftpVerifyUserCmd(username: String) -> String { withCArgs { c in extract(FTPVerifyUserCmd(c.str(username))) } }
    public func ftpGetServerIPCmd() -> String { extract(FTPGetServerIPCmd()) }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let value = innerData["command"] as? String else { return "" }
        return value
    }
}
