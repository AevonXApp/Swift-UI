//
//  SystemControlVM+Parse.swift
//  AevonX
//
//  Parsing logic for system control snapshot.
//

import Foundation

extension SystemControlVM {

    func parseSnapshot(_ sections: [String: String]) {
        parseHardware(sections["HARDWARE"] ?? "")
        virtType = (sections["VIRT"] ?? "unknown").trimmingCharacters(in: .whitespaces)
        parseSecModule(sections["SECMODULE"] ?? "")
        parseSwap(sections["SWAPINFO"] ?? "")
        parseKernelParams(sections["KERNELPARAMS"] ?? "")
        rebootRequired = (sections["REBOOTREQ"] ?? "no").trimmingCharacters(in: .whitespaces) == "yes"
        scheduledReboot = (sections["SCHEDREBOOT"] ?? "").trimmingCharacters(in: .whitespaces)
    }

    private func parseHardware(_ s: String) {
        for line in s.split(separator: "\n") {
            let parts = line.split(separator: "|", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let val = String(parts[1]).trimmingCharacters(in: .whitespaces)
            switch key {
            case "cpu_model": hardware.cpuModel = val
            case "cpu_cores": hardware.cpuCores = val
            case "arch": hardware.arch = val
            case "total_ram": hardware.totalRAM = formatBytes(val)
            case "disk_total": hardware.totalDisk = formatBytes(val)
            default: break
            }
        }
    }

    private func parseSecModule(_ s: String) {
        let parts = s.split(separator: "|")
        secModuleType = parts.count > 0 ? String(parts[0]) : "none"
        secModuleStatus = parts.count > 1 ? String(parts[1]) : "none"
    }

    private func parseSwap(_ s: String) {
        swapEntries = s.split(separator: "\n").compactMap { line in
            let cols = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard cols.count >= 4, cols[0] != "NAME" else { return nil }
            return SwapInfo(
                name: cols[0],
                type: cols.count > 1 ? cols[1] : "",
                size: cols.count > 2 ? cols[2] : "",
                used: cols.count > 3 ? cols[3] : "",
                priority: cols.count > 4 ? cols[4] : ""
            )
        }
    }

    private func parseKernelParams(_ s: String) {
        kernelParams = s.split(separator: "\n").compactMap { line in
            let parts = String(line).split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let val = parts[1].trimmingCharacters(in: .whitespaces)
            return KernelParam(key: key, value: val)
        }
    }

    private func formatBytes(_ s: String) -> String {
        guard let bytes = UInt64(s) else { return s }
        if bytes >= 1_073_741_824 {
            return String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
        } else if bytes >= 1_048_576 {
            return String(format: "%.0f MB", Double(bytes) / 1_048_576)
        }
        return "\(bytes) B"
    }
}
