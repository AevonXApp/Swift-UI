//
//  UserManagementVM+Parse.swift
//  AevonX
//
//  Parsing logic for advanced user management snapshot.
//

import Foundation

extension UserManagementVM {

    func parseSnapshot(_ sections: [String: String]) {
        parseSessions(sections["SESSIONS"] ?? "")
        parseGroups(sections["GROUPS"] ?? "")
        parseSudoers(sections["SUDOERS"] ?? "")
        parsePasswordStatus(sections["PWDSTATUS"] ?? "")
        parseDiskUsage(sections["DISKUSAGE"] ?? "")
        parseLoginHistory(sections["LOGINHISTORY"] ?? "")
    }

    private func parseSessions(_ s: String) {
        activeSessions = s.split(separator: "\n").compactMap { line in
            // who output: user terminal date time (ip)
            let parts = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            let user = parts[0]
            let terminal = parts[1]
            let time = parts.count >= 4 ? "\(parts[2]) \(parts[3])" : parts[2]
            let fromIP = parts.count >= 5 ? parts[4]
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "") : "local"
            return ActiveSession(user: user, terminal: terminal, fromIP: fromIP, loginTime: time)
        }
    }

    private func parseGroups(_ s: String) {
        groups = s.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count >= 3 else { return nil }
            let name = String(parts[0])
            let gid = String(parts[1])
            let membersStr = String(parts[2])
            let members = membersStr.isEmpty ? [] : membersStr.split(separator: ",").map(String.init)
            return SystemGroup(name: name, gid: gid, members: members)
        }.sorted { $0.name < $1.name }
    }

    private func parseSudoers(_ s: String) {
        sudoUsers = s.trimmingCharacters(in: .whitespaces)
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func parsePasswordStatus(_ s: String) {
        passwordStatuses = s.split(separator: "\n").compactMap { line in
            // Format: username|status|lastChanged|minDays|maxDays
            let parts = line.split(separator: "|")
            guard parts.count >= 3 else { return nil }
            return PasswordStatus(
                username: String(parts[0]),
                status: String(parts[1]),
                lastChanged: String(parts[2]),
                minDays: parts.count > 3 ? String(parts[3]) : "",
                maxDays: parts.count > 4 ? String(parts[4]) : ""
            )
        }
    }

    private func parseDiskUsage(_ s: String) {
        diskUsages = s.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count >= 2 else { return nil }
            return UserDiskUsage(path: String(parts[0]), size: String(parts[1]))
        }
    }

    private func parseLoginHistory(_ s: String) {
        loginHistory = s.split(separator: "\n").compactMap { line in
            let str = String(line)
            guard !str.hasPrefix("wtmp") && !str.isEmpty else { return nil }
            let parts = str.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            let fromIP = parts.count > 2 ? parts[2] : "—"
            let dateRange = parts.count > 3 ? parts[3...].joined(separator: " ") : ""
            return SSHRecentLogin(user: parts[0], terminal: parts[1], fromIP: fromIP, dateRange: dateRange)
        }
    }
}
