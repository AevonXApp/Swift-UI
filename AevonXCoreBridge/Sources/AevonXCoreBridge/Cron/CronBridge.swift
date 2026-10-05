//
//  CronBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Cron management operations.
//

import Foundation
import AevonXCoreLib

// MARK: - Cron Bridge

/// Bridge to Go Core Cron operations.
/// Provides type-safe Swift APIs for cron job management.
public final class CronBridge: @unchecked Sendable {

    public static let shared = CronBridge()
    private init() {}

    // MARK: - List & Parse

    public func listJobsCmd() -> String {
        let result = CronListJobsCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    public func parseCrontab(output: String) -> BridgeResponse {
        let result = withCArgs { c in CronParseCrontab(c.str(output)) }
        defer { CoreFreeString(result) }
        return parseResponse(result)
    }

    // MARK: - Script Write

    public func writeScriptCmds(scriptDir: String, logDir: String, jobID: String, userScript: String) -> [String] {
        let result = withCArgs { c in CronWriteScriptCmds(c.str(scriptDir), c.str(logDir), c.str(jobID), c.str(userScript)) }
        defer { CoreFreeString(result) }
        return extractStringArray(result, key: "commands")
    }

    // MARK: - Add Job

    public func addJobCmd(minute: String, hour: String, dom: String, month: String, dow: String, scriptPath: String, jobName: String, taskType: String) -> String {
        let result = withCArgs { c in CronAddJobCmd(c.str(minute), c.str(hour), c.str(dom), c.str(month), c.str(dow), c.str(scriptPath), c.str(jobName), c.str(taskType)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    public func ensureRunningCmd() -> String {
        let result = CronEnsureRunningCmd()
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // MARK: - Delete Job

    public func deleteJobCmd(rawLine: String) -> String {
        let result = withCArgs { c in CronDeleteJobCmd(c.str(rawLine)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    public func deleteScriptCmd(scriptDir: String, jobID: String) -> String {
        let result = withCArgs { c in CronDeleteScriptCmd(c.str(scriptDir), c.str(jobID)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // MARK: - Toggle

    public func toggleJobCmd(rawLine: String, enable: Bool) -> String {
        let result = withCArgs { c in CronToggleJobCmd(c.str(rawLine), enable ? 1 : 0) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // MARK: - Execute Now

    public func executeNowCmd(scriptPath: String) -> String {
        let result = withCArgs { c in CronExecuteNowCmd(c.str(scriptPath)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // MARK: - Script Reading

    public func readScriptCmd(scriptPath: String) -> String {
        let result = withCArgs { c in CronReadScriptCmd(c.str(scriptPath)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    // MARK: - Logs

    public func readLogCmd(logDir: String, jobID: String) -> String {
        let result = withCArgs { c in CronReadLogCmd(c.str(logDir), c.str(jobID)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    public func clearLogCmd(logDir: String, jobID: String) -> String {
        let result = withCArgs { c in CronClearLogCmd(c.str(logDir), c.str(jobID)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "command") ?? ""
    }

    public func parseLogOutput(output: String) -> BridgeResponse {
        let result = withCArgs { c in CronParseLogOutput(c.str(output)) }
        defer { CoreFreeString(result) }
        return parseResponse(result)
    }

    // MARK: - Templates

    public func getScriptLibrary() -> BridgeResponse {
        let result = CronGetScriptLibrary()
        defer { CoreFreeString(result) }
        return parseResponse(result)
    }

    public func defaultScript(taskType: String, param: String) -> String {
        let result = withCArgs { c in CronDefaultScript(c.str(taskType), c.str(param)) }
        defer { CoreFreeString(result) }
        return extractString(result, key: "script") ?? ""
    }

    public func getAllTaskTypes() -> BridgeResponse {
        let result = CronGetAllTaskTypes()
        defer { CoreFreeString(result) }
        return parseResponse(result)
    }

    // MARK: - Helpers

    private func extractString(_ cStr: UnsafeMutablePointer<CChar>?, key: String) -> String? {
        guard let cStr = cStr else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let value = innerData[key] as? String else { return nil }
        return value
    }

    private func extractStringArray(_ cStr: UnsafeMutablePointer<CChar>?, key: String) -> [String] {
        guard let cStr = cStr else { return [] }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let array = innerData[key] as? [String] else { return [] }
        return array
    }

    private func parseResponse(_ cStr: UnsafeMutablePointer<CChar>?) -> BridgeResponse {
        guard let cStr = cStr else {
            return makeBridgeError("null response")
        }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8) else {
            return makeBridgeError("invalid json")
        }
        return (try? JSONDecoder().decode(BridgeResponse.self, from: data))
            ?? makeBridgeError("decode failed")
    }

    private func makeBridgeError(_ message: String) -> BridgeResponse {
        let json = """
        {"success":false,"error":"\(message)"}
        """
        return try! JSONDecoder().decode(BridgeResponse.self, from: json.data(using: .utf8)!)
    }
}
