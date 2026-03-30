//
//  NetworkManagerVM+Parse.swift
//  AevonX
//
//  Parsing logic for network snapshot sections.
//

import Foundation

extension NetworkManagerVM {

    func parseSnapshot(_ sections: [String: String]) {
        parseInterfaces(
            addrs: sections["INTERFACES"] ?? "",
            macs: sections["MAC"] ?? "",
            statuses: sections["IFSTATUS"] ?? ""
        )
        parseListeningPorts(sections["LISTENING"] ?? "")
        parseConnections(sections["CONNECTIONS"] ?? "")
        dnsContent = sections["DNS"] ?? ""
        parseRoutes(sections["ROUTES"] ?? "")
        hostsContent = sections["HOSTS"] ?? ""
        netStats = sections["NETSTATS"] ?? ""
    }

    // MARK: - Interfaces

    private func parseInterfaces(addrs: String, macs: String, statuses: String) {
        // Build MAC lookup: iface -> mac
        var macMap: [String: String] = [:]
        for line in macs.split(separator: "\n") {
            let parts = line.split(separator: "|")
            guard parts.count >= 2 else { continue }
            macMap[String(parts[0])] = String(parts[1])
        }

        // Build status lookup: iface -> UP/DOWN
        var statusMap: [String: String] = [:]
        for line in statuses.split(separator: "\n") {
            let parts = line.split(separator: "|")
            guard parts.count >= 2 else { continue }
            statusMap[String(parts[0])] = String(parts[1])
        }

        // Parse addresses: iface|inet/inet6|ip
        var seen: [String: NetworkInterfaceInfo] = [:]
        for line in addrs.split(separator: "\n") {
            let parts = line.split(separator: "|")
            guard parts.count >= 3 else { continue }
            let name = String(parts[0])
            let family = String(parts[1])
            let ip = String(parts[2])
            guard family == "inet" else { continue } // IPv4 only for main display
            if seen[name] != nil { continue }
            seen[name] = NetworkInterfaceInfo(
                id: name,
                name: name,
                ipAddress: ip,
                macAddress: macMap[name] ?? "—",
                status: statusMap[name] ?? "UNKNOWN"
            )
        }
        interfaces = Array(seen.values).sorted { $0.name < $1.name }
    }

    // MARK: - Listening Ports

    private func parseListeningPorts(_ s: String) {
        // ss -tulnp output: proto  state  recv-q  send-q  local  peer  process
        listeningPorts = s.split(separator: "\n").compactMap { line in
            let cols = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard cols.count >= 5 else { return nil }
            let proto = cols[0]
            let local = cols[4]
            // Extract address and port from local (e.g. 0.0.0.0:22 or [::]:22 or *:22)
            let (addr, port) = splitHostPort(local)
            guard let portNum = Int(port) else { return nil }
            // Process info from last column (e.g. users:(("sshd",pid=1234,fd=3)))
            let processInfo = cols.count >= 7 ? cols[6] : ""
            let (pid, procName) = parseProcessField(processInfo)
            return NetworkListeningPort(
                id: "\(proto):\(addr):\(port)",
                port: portNum, proto: proto, address: addr,
                pid: pid, process: procName
            )
        }
    }

    private func splitHostPort(_ s: String) -> (String, String) {
        // Handle [::]:port, *:port, 0.0.0.0:port, 127.0.0.1:port
        if let lastColon = s.lastIndex(of: ":") {
            let addr = String(s[s.startIndex..<lastColon])
            let port = String(s[s.index(after: lastColon)...])
            return (addr, port)
        }
        return (s, "0")
    }

    private func parseProcessField(_ s: String) -> (String, String) {
        // Format: users:(("name",pid=123,fd=3))
        var pid = "—"
        var name = "—"
        if let pidRange = s.range(of: "pid=") {
            let after = s[pidRange.upperBound...]
            pid = String(after.prefix(while: { $0.isNumber }))
        }
        if let nameStart = s.range(of: "((\"") {
            let after = s[nameStart.upperBound...]
            if let nameEnd = after.firstIndex(of: "\"") {
                name = String(after[after.startIndex..<nameEnd])
            }
        }
        return (pid, name)
    }

    // MARK: - Active Connections

    private func parseConnections(_ s: String) {
        activeConnections = s.split(separator: "\n").compactMap { line in
            let cols = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard cols.count >= 5 else { return nil }
            let proto = cols[0]
            let local = cols[3]
            let remote = cols[4]
            let (_, localPort) = splitHostPort(local)
            let (remoteAddr, remotePort) = splitHostPort(remote)
            let processInfo = cols.count >= 6 ? cols[5] : ""
            let (pid, procName) = parseProcessField(processInfo)
            return ActiveConnection(
                proto: proto, localPort: localPort,
                remoteAddr: remoteAddr, remotePort: remotePort,
                pid: pid, process: procName
            )
        }
    }

    // MARK: - Routes

    private func parseRoutes(_ s: String) {
        routes = s.split(separator: "\n").compactMap { line in
            let str = String(line)
            let parts = str.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard !parts.isEmpty else { return nil }
            let dest = parts[0]
            var gw = "—"
            var iface = "—"
            var extra: [String] = []
            var i = 1
            while i < parts.count {
                switch parts[i] {
                case "via": if i + 1 < parts.count { gw = parts[i + 1]; i += 1 }
                case "dev": if i + 1 < parts.count { iface = parts[i + 1]; i += 1 }
                default: extra.append(parts[i])
                }
                i += 1
            }
            return RouteEntry(destination: dest, gateway: gw, iface: iface, extra: extra.joined(separator: " "))
        }
    }
}
