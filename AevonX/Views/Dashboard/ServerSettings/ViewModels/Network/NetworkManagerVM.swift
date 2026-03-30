//
//  NetworkManagerVM.swift
//  AevonX
//
//  ViewModel for network monitoring — interfaces, ports, connections, DNS.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class NetworkManagerVM: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - Interfaces
    @Published var interfaces: [NetworkInterfaceInfo] = []

    // MARK: - Listening Ports
    @Published var listeningPorts: [NetworkListeningPort] = []
    @Published var portSearchText = ""

    // MARK: - Active Connections
    @Published var activeConnections: [ActiveConnection] = []

    // MARK: - DNS
    @Published var dnsContent = ""
    @Published var isEditingDNS = false
    @Published var editedDNS = ""

    // MARK: - Routes
    @Published var routes: [RouteEntry] = []

    // MARK: - Hosts
    @Published var hostsContent = ""
    @Published var isEditingHosts = false
    @Published var editedHosts = ""

    // MARK: - Statistics
    @Published var netStats = ""

    // MARK: - State
    @Published var isLoading = true
    @Published var saveMsg: (String, Bool)? = nil

    var isConnected: Bool {
        SSHBridge.shared.isConnected(serverID: serverId)
    }

    var filteredPorts: [NetworkListeningPort] {
        if portSearchText.isEmpty { return listeningPorts }
        return listeningPorts.filter {
            $0.process.localizedCaseInsensitiveContains(portSearchText) ||
            "\($0.port)".contains(portSearchText)
        }
    }

    var riskyPorts: [NetworkListeningPort] {
        listeningPorts.filter { $0.isRisky }
    }

    init(serverId: String) {
        self.serverId = serverId
    }

    func ssh(_ cmd: String) async -> String {
        guard !cmd.isEmpty else { return "" }
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: cmd)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadAll() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }

        let cmd = await service.networkFullSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseSnapshot(sections)
    }

    func saveDNS() async {
        let cmd = await service.saveDNSCmd(content: editedDNS)
        let out = await ssh(cmd)
        if out.contains("OK") {
            dnsContent = editedDNS; isEditingDNS = false
            saveMsg = ("DNS saved", true)
        } else {
            saveMsg = ("Failed to save DNS", false)
        }
        clearMsg()
    }

    func saveHosts() async {
        let cmd = await service.saveHostsCmd(content: editedHosts)
        let out = await ssh(cmd)
        if out.contains("OK") {
            hostsContent = editedHosts; isEditingHosts = false
            saveMsg = ("Hosts saved", true)
        } else {
            saveMsg = ("Failed to save hosts", false)
        }
        clearMsg()
    }

    private func clearMsg() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.saveMsg = nil }
    }
}
