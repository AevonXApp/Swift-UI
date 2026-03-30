//
//  NetworkModels.swift
//  AevonX
//
//  Data models for network monitoring.
//

import SwiftUI

// MARK: - Network Interface

struct NetworkInterfaceInfo: Identifiable {
    let id: String
    let name: String
    let ipAddress: String
    let macAddress: String
    let status: String

    var statusColor: Color {
        status.uppercased().contains("UP") ? .axSuccess : .axTextMuted
    }
}

// MARK: - Listening Port

struct NetworkListeningPort: Identifiable {
    let id: String
    let port: Int
    let proto: String
    let address: String
    let pid: String
    let process: String

    var isRisky: Bool { Self.riskyPorts[port] != nil && (address == "0.0.0.0" || address == "::") }
    var riskMessage: String? { Self.riskyPorts[port] }

    static let riskyPorts: [Int: String] = [
        21: "FTP — insecure, use SFTP",
        23: "Telnet — extremely insecure",
        25: "SMTP — may relay spam",
        445: "SMB — common attack vector",
        3389: "RDP — brute force target",
        8080: "HTTP proxy — often misconfigured",
        27017: "MongoDB — often open without auth",
    ]
}

// MARK: - Active Connection

struct ActiveConnection: Identifiable {
    let id = UUID()
    let proto: String
    let localPort: String
    let remoteAddr: String
    let remotePort: String
    let pid: String
    let process: String
}

// MARK: - Route Entry

struct RouteEntry: Identifiable {
    let id = UUID()
    let destination: String
    let gateway: String
    let iface: String
    let extra: String
}

// MARK: - Connection Filter

enum ConnectionFilter: String, CaseIterable {
    case all = "All"
    case established = "Established"
    case timeWait = "Time Wait"
}
