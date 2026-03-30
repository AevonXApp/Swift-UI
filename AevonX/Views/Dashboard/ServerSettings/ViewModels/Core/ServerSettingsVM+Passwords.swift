//
//  ServerSettingsVM+Passwords.swift
//  AevonX
//
//  Password change actions for ServerSettingsViewModel.
//

import Foundation

extension ServerSettingsViewModel {

    func changeRootPassword() async {
        guard guardOperation("rootPwd") else { return }
        defer { endOperation("rootPwd") }
        guard validatePwd(rootNewPwd, rootConfirmPwd, setMsg: { self.rootMsg = $0 }) else { return }
        isChangingRoot = true; defer { isChangingRoot = false }

        let cmd = await service.rootPasswordCmd(password: rootNewPwd)
        let out = await ssh(cmd)
        if out.contains("OK") {
            rootMsg = ("Root password changed", true); rootNewPwd = ""; rootConfirmPwd = ""
            logActivity(type: "password_changed", description: "Root password changed")
        } else {
            rootMsg = ("Failed: \(out)", false)
        }
        clearMsg(after: 5) { self.rootMsg = nil }
    }

    func changeMySQLPassword() async {
        guard guardOperation("mysqlPwd") else { return }
        defer { endOperation("mysqlPwd") }
        guard validatePwd(mysqlNewPwd, mysqlConfirmPwd, setMsg: { self.mysqlMsg = $0 }) else { return }
        isChangingMySQL = true; defer { isChangingMySQL = false }

        let cmd = await service.mysqlPasswordCmd(password: mysqlNewPwd)
        let out = await ssh(cmd)
        if out.contains("OK") {
            mysqlMsg = ("MySQL password changed", true); mysqlNewPwd = ""; mysqlConfirmPwd = ""
            logActivity(type: "password_changed", description: "MySQL root password changed")
        } else {
            mysqlMsg = ("Failed: \(out)", false)
        }
        clearMsg(after: 5) { self.mysqlMsg = nil }
    }

    func changePGPassword() async {
        guard guardOperation("pgPwd") else { return }
        defer { endOperation("pgPwd") }
        guard validatePwd(pgNewPwd, pgConfirmPwd, setMsg: { self.pgMsg = $0 }) else { return }
        isChangingPG = true; defer { isChangingPG = false }

        let cmd = await service.postgresPasswordCmd(password: pgNewPwd)
        let out = await ssh(cmd)
        if out.contains("OK") {
            pgMsg = ("PostgreSQL password changed", true); pgNewPwd = ""; pgConfirmPwd = ""
            logActivity(type: "password_changed", description: "PostgreSQL password changed")
        } else {
            pgMsg = ("Failed: \(out)", false)
        }
        clearMsg(after: 5) { self.pgMsg = nil }
    }
}
