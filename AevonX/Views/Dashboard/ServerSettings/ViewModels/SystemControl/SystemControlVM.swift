//
//  SystemControlVM.swift
//  AevonX
//
//  ViewModel for system control — reboot, shutdown, swap, kernel params.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class SystemControlVM: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - Hardware
    @Published var hardware = HardwareInfo()
    @Published var virtType = ""

    // MARK: - Security Module
    @Published var secModuleType = ""
    @Published var secModuleStatus = ""

    // MARK: - Swap
    @Published var swapEntries: [SwapInfo] = []
    @Published var newSwapSizeMB = ""

    // MARK: - Kernel Params
    @Published var kernelParams: [KernelParam] = []

    // MARK: - Reboot
    @Published var rebootRequired = false
    @Published var scheduledReboot = ""
    @Published var scheduleTime = "+5"

    // MARK: - State
    @Published var isLoading = true
    @Published var saveMsg: (String, Bool)? = nil
    @Published var showRebootConfirm = false
    @Published var showShutdownConfirm = false

    var isConnected: Bool {
        SSHBridge.shared.isConnected(serverID: serverId)
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
        guard isConnected else { isLoading = false; return }
        isLoading = true
        defer { isLoading = false }
        let cmd = await service.systemControlSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseSnapshot(sections)
    }

    // MARK: - Actions

    func reboot() async {
        let cmd = await service.systemRebootCmd()
        _ = await ssh(cmd)
        showMsg(L10n.ServerSettings.rebootInitiated, true)
    }

    func shutdown() async {
        let cmd = await service.systemShutdownCmd()
        _ = await ssh(cmd)
        showMsg(L10n.ServerSettings.shutdownInitiated, true)
    }

    func scheduleReboot() async {
        guard !scheduleTime.isEmpty else { return }
        let cmd = await service.systemScheduleRebootCmd(when: scheduleTime)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.rebootScheduled, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.rebootScheduleFailed, false)
        }
    }

    func cancelReboot() async {
        let cmd = await service.systemCancelRebootCmd()
        let out = await ssh(cmd)
        if out.contains("OK") {
            scheduledReboot = ""
            showMsg(L10n.ServerSettings.rebootCancelled, true)
        } else {
            showMsg(L10n.ServerSettings.rebootCancelFailed, false)
        }
    }

    func resizeSwap() async {
        guard let mb = Int32(newSwapSizeMB) else { return }
        let cmd = await service.systemSwapResizeCmd(sizeMB: mb)
        let out = await ssh(cmd)
        if out.contains("OK") {
            newSwapSizeMB = ""
            showMsg(L10n.ServerSettings.swapResized, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.swapResizeFailed, false)
        }
    }

    func setKernelParam(key: String, value: String) async {
        let cmd = await service.systemSetKernelParamCmd(key: key, value: value)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.paramUpdated, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.paramUpdateFailed, false)
        }
    }

    private func showMsg(_ text: String, _ success: Bool) {
        saveMsg = (text, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.saveMsg = nil }
    }
}
