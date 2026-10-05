//
//  FTPService.swift
//  AevonXCoreBridge
//
//  SSH-based FTP management service (PureFTPd) — replaces AevonXCore's FTPService.
//  Uses Go-backed SSHBridge for all SSH operations.
//

import Foundation

// MARK: - FTP Service

public actor FTPService {

    public static let shared = FTPService()

    private let passwdFile = "/etc/pure-ftpd/pureftpd.passwd"
    private let pdbFile    = "/etc/pure-ftpd/pureftpd.pdb"

    private init() {}

    // MARK: - SSH Helper

    private func ssh(_ command: String, serverId: String) async -> SSHResult {
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: command)
        return SSHResult.parse(json)
    }

    // MARK: - Setup PureDB

    private func ensurePureDBSetup(serverId: String) async {
        _ = await ssh("""
        PASSWD="\(passwdFile)"
        PDB="\(pdbFile)"
        touch "$PASSWD" 2>/dev/null
        chmod 600 "$PASSWD" 2>/dev/null
        if [ -d /etc/pure-ftpd/conf ]; then
          echo "$PDB" > /etc/pure-ftpd/conf/PureDB
          mkdir -p /etc/pure-ftpd/auth 2>/dev/null
          ln -sf /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50puredb 2>/dev/null
        fi
        if [ -f /etc/pure-ftpd/pure-ftpd.conf ]; then
          if ! grep -q '^PureDB' /etc/pure-ftpd/pure-ftpd.conf; then
            echo "PureDB $PDB" >> /etc/pure-ftpd/pure-ftpd.conf
          fi
        fi
        pure-pw mkdb "$PDB" -f "$PASSWD" 2>/dev/null || true
        systemctl restart pure-ftpd 2>/dev/null || service pure-ftpd restart 2>/dev/null || true
        """, serverId: serverId)
    }

    private func rebuildDB(serverId: String) async {
        _ = await ssh(
            "pure-pw mkdb '\(pdbFile)' -f '\(passwdFile)' 2>/dev/null || true",
            serverId: serverId
        )
    }

    // MARK: - Check Installation

    public func checkInstallation(serverId: String) async throws -> FTPServerInfo {
        let result = await ssh("""
        if command -v pure-pw >/dev/null 2>&1; then
          echo "INSTALLED"
          pure-ftpd --help 2>&1 | head -1 || echo "unknown"
          systemctl is-active pure-ftpd 2>/dev/null || echo "inactive"
          PORT=21
          for CONF in /etc/pure-ftpd/pure-ftpd.conf /etc/pure-ftpd.conf; do
            if [ -f "$CONF" ]; then
              P=$(grep '^Bind' "$CONF" 2>/dev/null | sed 's/.*,//')
              [ -n "$P" ] && PORT="$P"
              break
            fi
          done
          echo "PORT:$PORT"
        else
          echo "NOT_INSTALLED"
        fi
        """, serverId: serverId)

        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        if output.contains("NOT_INSTALLED") {
            return FTPServerInfo()
        }

        let lines = output.components(separatedBy: "\n")
        let isInstalled = lines.first?.contains("INSTALLED") ?? false
        let version = lines.count > 1 ? extractVersion(from: lines[1]) : ""
        let isRunning = lines.contains { $0.trimmingCharacters(in: .whitespaces) == "active" }
        var port = 21
        if let portLine = lines.first(where: { $0.contains("PORT:") }) {
            port = Int(portLine.replacingOccurrences(of: "PORT:", with: "").trimmingCharacters(in: .whitespaces)) ?? 21
        }

        let ipResult = await ssh("hostname -I 2>/dev/null | awk '{print $1}'", serverId: serverId)
        let ip = ipResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalIP = ip.isEmpty ? "localhost" : ip

        if isInstalled {
            await ensurePureDBSetup(serverId: serverId)
        }

        return FTPServerInfo(
            isInstalled: isInstalled,
            isRunning: isRunning,
            version: version,
            port: port,
            ftpAddress: "ftp://\(finalIP):\(port)"
        )
    }

    private func extractVersion(from line: String) -> String {
        let patterns = ["pure-ftpd v", "Pure-FTPd "]
        for pattern in patterns {
            if let range = line.range(of: pattern, options: .caseInsensitive) {
                let version = line[range.upperBound...]
                    .prefix(while: { $0.isNumber || $0 == "." })
                if !version.isEmpty { return String(version) }
            }
        }
        return line.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Install PureFTPd

    public func installPureFTPd(serverId: String) async throws -> String {
        let result = await ssh("""
        export DEBIAN_FRONTEND=noninteractive
        if command -v apt-get >/dev/null 2>&1; then
          apt-get update -qq && apt-get install -y pure-ftpd 2>&1
        elif command -v yum >/dev/null 2>&1; then
          yum install -y pure-ftpd 2>&1
        elif command -v dnf >/dev/null 2>&1; then
          dnf install -y pure-ftpd 2>&1
        else
          echo "ERROR: No supported package manager found"
          exit 1
        fi
        systemctl enable pure-ftpd 2>/dev/null || true
        systemctl start pure-ftpd 2>/dev/null || service pure-ftpd start 2>/dev/null || true
        """, serverId: serverId)

        await ensurePureDBSetup(serverId: serverId)
        return result.stdout
    }

    // MARK: - List Users

    public func listUsers(serverId: String) async throws -> [FTPUser] {
        let result = await ssh(
            "pure-pw list -f '\(passwdFile)' 2>/dev/null || pure-pw list 2>/dev/null || echo ''",
            serverId: serverId
        )
        var users = parseUserList(result.stdout)

        let rawPasswd = await ssh("cat '\(passwdFile)' 2>/dev/null || echo ''", serverId: serverId)
        let disabledUsers = Set(
            rawPasswd.stdout.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
                .compactMap { line -> String? in
                    let parts = line.components(separatedBy: ":")
                    guard parts.count >= 2 else { return nil }
                    return parts[1].hasPrefix("!!") ? parts[0] : nil
                }
        )

        for i in users.indices {
            if disabledUsers.contains(users[i].username) {
                users[i].status = .inactive
            }
        }

        return users
    }

    private func parseUserList(_ raw: String) -> [FTPUser] {
        var users: [FTPUser] = []

        for line in raw.split(separator: "\n") {
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard !str.isEmpty else { continue }

            let parts = str.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2 else { continue }

            let username = parts[0]
            var docRoot = parts[1]
            if docRoot.hasSuffix("/./") {
                docRoot = String(docRoot.dropLast(3))
            } else if docRoot.hasSuffix("/.") {
                docRoot = String(docRoot.dropLast(2))
            }

            users.append(FTPUser(
                username: username,
                password: "••••••••",
                status: .active,
                documentRoot: docRoot,
                quota: 0,
                note: ""
            ))
        }

        return users
    }

    // MARK: - Add User

    public func addUser(_ user: FTPUser, serverId: String) async throws {
        let quota = user.quota > 0 ? "-N \(user.quota)" : ""
        let safeRoot = ShellSanitizer.quote(user.documentRoot)

        _ = await ssh(
            "mkdir -p \(safeRoot) 2>/dev/null; chown ftpuser:ftpuser \(safeRoot) 2>/dev/null || true",
            serverId: serverId
        )

        let passB64 = Data(user.password.utf8).base64EncodedString()

        let addResult = await ssh("""
        PASS=$(printf '%s' '\(passB64)' | base64 -d)
        printf '%s\\n%s\\n' "$PASS" "$PASS" | pure-pw useradd '\(user.username)' -u ftpuser -g ftpuser -d \(safeRoot) \(quota) -f '\(passwdFile)'
        """, serverId: serverId)

        if addResult.exitCode != 0 {
            let detail = addResult.stderr.isEmpty ? addResult.stdout : addResult.stderr
            throw NSError(domain: "FTPService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create FTP user: \(detail.isEmpty ? "Unknown error" : detail)"
            ])
        }

        await rebuildDB(serverId: serverId)

        let verify = await ssh(
            "pure-pw show '\(user.username)' -f '\(passwdFile)' 2>/dev/null && echo 'USER_EXISTS' || echo 'USER_NOT_FOUND'",
            serverId: serverId
        )
        if verify.stdout.contains("USER_NOT_FOUND") {
            throw NSError(domain: "FTPService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "User was created but not found in password database."
            ])
        }
    }

    // MARK: - Delete User

    public func deleteUser(_ user: FTPUser, serverId: String) async throws {
        _ = await ssh("pure-pw userdel '\(user.username)' -f '\(passwdFile)' 2>&1", serverId: serverId)
        await rebuildDB(serverId: serverId)
    }

    // MARK: - Toggle User

    public func toggleUser(_ user: FTPUser, enable: Bool, serverId: String) async throws {
        let name = user.username
        let file = passwdFile

        if enable {
            _ = await ssh("sed -i 's/^\(name):!!/\(name):/' '\(file)'", serverId: serverId)
        } else {
            _ = await ssh("sed -i '/^\(name):!!/!s/^\(name):/\(name):!!/' '\(file)'", serverId: serverId)
        }

        await rebuildDB(serverId: serverId)
    }

    // MARK: - Change Password

    public func changePassword(username: String, newPassword: String, serverId: String) async throws {
        let passB64 = Data(newPassword.utf8).base64EncodedString()
        _ = await ssh("""
        PASS=$(printf '%s' '\(passB64)' | base64 -d)
        printf '%s\\n%s\\n' "$PASS" "$PASS" | pure-pw passwd '\(username)' -f '\(passwdFile)'
        """, serverId: serverId)
        await rebuildDB(serverId: serverId)
    }

    // MARK: - Change FTP Port

    public func changeFTPPort(to port: Int, serverId: String) async throws {
        _ = await ssh("""
        CONFIG="/etc/pure-ftpd/pure-ftpd.conf"
        if [ ! -f "$CONFIG" ]; then
          CONFIG="/etc/pure-ftpd.conf"
        fi
        if [ -f "$CONFIG" ]; then
          sed -i 's/^Bind.*/Bind 0.0.0.0,\(port)/' "$CONFIG"
          if ! grep -q '^Bind' "$CONFIG"; then
            echo "Bind 0.0.0.0,\(port)" >> "$CONFIG"
          fi
        fi
        systemctl restart pure-ftpd 2>/dev/null || service pure-ftpd restart 2>/dev/null || true
        """, serverId: serverId)
    }

    // MARK: - Service Control

    public func startService(serverId: String) async throws {
        _ = await ssh("systemctl start pure-ftpd 2>/dev/null || service pure-ftpd start 2>/dev/null", serverId: serverId)
    }

    public func stopService(serverId: String) async throws {
        _ = await ssh("systemctl stop pure-ftpd 2>/dev/null || service pure-ftpd stop 2>/dev/null", serverId: serverId)
    }

    public func restartService(serverId: String) async throws {
        _ = await ssh("systemctl restart pure-ftpd 2>/dev/null || service pure-ftpd restart 2>/dev/null", serverId: serverId)
    }

    // MARK: - Logs

    public func getLogs(serverId: String) async throws -> [FTPLogEntry] {
        let result = await ssh("""
        for LOG in /var/log/pure-ftpd/transfer.log /var/log/pureftpd.log /var/log/syslog /var/log/messages; do
          if [ -f "$LOG" ]; then
            grep -i 'pure-ftpd\\|ftp' "$LOG" 2>/dev/null | tail -100
            break
          fi
        done
        """, serverId: serverId)
        return parseLogs(result.stdout)
    }

    private func parseLogs(_ raw: String) -> [FTPLogEntry] {
        var entries: [FTPLogEntry] = []

        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let timestamp: String
            let message: String
            if trimmed.count > 15 {
                timestamp = String(trimmed.prefix(15))
                message = String(trimmed.dropFirst(15)).trimmingCharacters(in: .whitespaces)
            } else {
                timestamp = ""
                message = trimmed
            }

            entries.append(FTPLogEntry(timestamp: timestamp, message: message, type: detectLogType(message)))
        }

        return entries.reversed()
    }

    private func detectLogType(_ message: String) -> FTPLogType {
        let lower = message.lowercased()
        if lower.contains("login") || lower.contains("authentication") || lower.contains("new connection") {
            return .login
        } else if lower.contains("logout") || lower.contains("disconnected") || lower.contains("ended") {
            return .logout
        } else if lower.contains("upload") || lower.contains("stored") {
            return .upload
        } else if lower.contains("download") || lower.contains("retrieved") {
            return .download
        } else if lower.contains("error") || lower.contains("fail") || lower.contains("denied") || lower.contains("refused") {
            return .error
        }
        return .info
    }

    // MARK: - Generate Password

    public nonisolated func generatePassword(length: Int = 16) -> String {
        // Use only safe characters that won't break shell interpolation or SQL quoting.
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#%^_+-="
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
