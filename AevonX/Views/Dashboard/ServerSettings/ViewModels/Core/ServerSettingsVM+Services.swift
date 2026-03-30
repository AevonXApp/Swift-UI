//
//  ServerSettingsVM+Services.swift
//  AevonX
//
//  Service management actions: enable/disable, logs, reload.
//

import Foundation

extension ServerSettingsViewModel {

    func enableService(_ name: String) async {
        guard guardOperation("svc.enable.\(name)") else { return }
        defer { endOperation("svc.enable.\(name)") }
        operatingServices.insert(name)
        defer { operatingServices.remove(name) }

        let cmd = await service.serviceControlCmd(initSystem: initSystem, operation: "enable", service: name)
        let _ = await ssh(cmd)
        logActivity(type: "ssh_command", description: "Enabled service: \(name)")
        await loadServices()
    }

    func disableService(_ name: String) async {
        guard guardOperation("svc.disable.\(name)") else { return }
        defer { endOperation("svc.disable.\(name)") }
        operatingServices.insert(name)
        defer { operatingServices.remove(name) }

        let cmd = await service.serviceControlCmd(initSystem: initSystem, operation: "disable", service: name)
        let _ = await ssh(cmd)
        logActivity(type: "ssh_command", description: "Disabled service: \(name)")
        await loadServices()
    }

    func reloadService(_ name: String) async {
        guard guardOperation("svc.reload.\(name)") else { return }
        defer { endOperation("svc.reload.\(name)") }
        operatingServices.insert(name)
        defer { operatingServices.remove(name) }

        let cmd = await service.serviceControlCmd(initSystem: initSystem, operation: "reload", service: name)
        let _ = await ssh(cmd)
        logActivity(type: "ssh_command", description: "Reloaded service: \(name)")
        await loadServices()
    }

    func loadServiceLogs(_ name: String, lines: Int32 = 50) async {
        guard isConnected else { return }
        isLoadingLogs = true
        defer { isLoadingLogs = false }

        let cmd = await service.serviceLogsCmd(initSystem: initSystem, service: name, lines: lines)
        serviceLogs = await ssh(cmd)
    }
}
