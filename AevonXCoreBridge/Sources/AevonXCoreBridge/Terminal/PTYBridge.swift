//
//  PTYBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core PTY (pseudo-terminal) operations.
//  Enables real interactive terminal sessions with colors, vim, htop, etc.
//

import Foundation
import AevonXCoreLib

public final class PTYBridge: @unchecked Sendable {

    public static let shared = PTYBridge()
    private init() {}

    // MARK: - Session Lifecycle

    /// Start a PTY session on a connected server.
    /// - Parameters:
    ///   - serverID: The server to open the session on
    ///   - sessionID: Unique ID for this terminal tab
    ///   - rows: Terminal height in rows
    ///   - cols: Terminal width in columns
    /// - Returns: JSON result string
    public func startSession(serverID: String, sessionID: String, rows: Int, cols: Int) -> String {
        withCArgs { c in
            extract(SSHStartPTY(
                c.str(serverID),
                c.str(sessionID),
                Int32(rows),
                Int32(cols)
            ))
        }
    }

    /// Close a PTY session.
    public func closeSession(sessionID: String) -> String {
        withCArgs { c in extract(SSHClosePTY(c.str(sessionID))) }
    }

    // MARK: - I/O

    /// Write raw bytes to PTY stdin (keystrokes, commands, control chars).
    /// Data is base64-encoded for safe C FFI transfer.
    public func write(sessionID: String, data: Data) -> String {
        let base64 = data.base64EncodedString()
        return withCArgs { c in extract(SSHWritePTY(c.str(sessionID), c.str(base64))) }
    }

    /// Write a string to PTY stdin.
    public func writeString(sessionID: String, text: String) -> String {
        guard let data = text.data(using: .utf8) else { return "" }
        return write(sessionID: sessionID, data: data)
    }

    /// Read available output from PTY stdout.
    /// Returns raw bytes (may contain ANSI escape codes).
    public func read(sessionID: String, maxBytes: Int = 8192) -> Data? {
        let json = withCArgs { c in extract(SSHReadPTY(c.str(sessionID), Int32(maxBytes))) }
        guard let jsonData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              result["success"] as? Bool == true,
              let data = result["data"] as? [String: Any],
              let outputB64 = data["output"] as? String,
              let outputData = Data(base64Encoded: outputB64),
              !outputData.isEmpty else {
            return nil
        }
        return outputData
    }

    // MARK: - Terminal Control

    /// Resize the PTY (window-change request).
    public func resize(sessionID: String, rows: Int, cols: Int) -> String {
        withCArgs { c in extract(SSHResizePTY(c.str(sessionID), Int32(rows), Int32(cols))) }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }
}
