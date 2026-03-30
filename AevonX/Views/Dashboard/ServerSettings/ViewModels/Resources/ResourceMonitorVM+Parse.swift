//
//  ResourceMonitorVM+Parse.swift
//  AevonX
//
//  Parsing logic for resource snapshot sections.
//

import Foundation

extension ResourceMonitorVM {

    func parseSnapshot(_ sections: [String: String]) {
        parseCPU(sections["CPU"] ?? "")
        parseCores(sections["CORES"] ?? "")
        parseLoad(sections["LOAD"] ?? "")
        parseRAM(sections["RAM"] ?? "")
        parseSwap(sections["SWAP"] ?? "")
        parseIOWait(sections["IOWAIT"] ?? "")
        parseProcessCount(sections["PROCS"] ?? "")
        topCPUProcesses = parseProcessList(sections["TOPCPU"] ?? "")
        topMemProcesses = parseProcessList(sections["TOPMEM"] ?? "")
        parseNetIO(sections["NETIO"] ?? "")
        parseDiskIO(sections["DISKIO"] ?? "")
        parseTemp(sections["TEMP"] ?? "")
        parseDiskPartitions(sections["DISK"] ?? "", inodes: sections["INODE"] ?? "")
        appendHistory()
    }

    private func parseCPU(_ s: String) {
        cpuPercent = Double(s.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func parseCores(_ s: String) {
        cpuCores = Int(s.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func parseLoad(_ s: String) {
        let parts = s.split(separator: "|")
        if parts.count >= 3 {
            loadAvg1 = Double(parts[0]) ?? 0
            loadAvg5 = Double(parts[1]) ?? 0
            loadAvg15 = Double(parts[2]) ?? 0
        }
    }

    private func parseRAM(_ s: String) {
        let parts = s.split(separator: "|")
        if parts.count >= 6 {
            ramTotal = UInt64(parts[0]) ?? 0
            ramUsed = UInt64(parts[1]) ?? 0
            ramFree = UInt64(parts[2]) ?? 0
            // parts[3] = shared, parts[4] = buffers, parts[5] = cached/available
            ramBuffers = UInt64(parts[4]) ?? 0
            ramCached = UInt64(parts[5]) ?? 0
        }
    }

    private func parseSwap(_ s: String) {
        let parts = s.split(separator: "|")
        if parts.count >= 2 {
            swapTotal = UInt64(parts[0]) ?? 0
            swapUsed = UInt64(parts[1]) ?? 0
        }
    }

    private func parseIOWait(_ s: String) {
        ioWait = Double(s.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func parseProcessCount(_ s: String) {
        processCount = Int(s.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    func parseProcessList(_ s: String) -> [ServerProcessInfo] {
        s.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count >= 5 else { return nil }
            let user = String(parts[0])
            let pid = Int(parts[1]) ?? 0
            let cpu = Double(parts[2]) ?? 0
            let mem = Double(parts[3]) ?? 0
            let cmd = String(parts[4]).trimmingCharacters(in: .whitespaces)
            guard !cmd.isEmpty else { return nil }
            return ServerProcessInfo(user: user, pid: pid, cpuPercent: cpu, memPercent: mem, command: cmd)
        }
    }

    private func parseNetIO(_ s: String) {
        let parts = s.split(separator: "|")
        if parts.count >= 2 {
            let rx = UInt64(parts[0]) ?? 0
            let tx = UInt64(parts[1]) ?? 0
            calculateNetworkRate(rx: rx, tx: tx)
        }
    }

    private func calculateNetworkRate(rx: UInt64, tx: UInt64) {
        guard let prevTime = prevNetTime else {
            prevNetRx = rx; prevNetTx = tx; prevNetTime = Date()
            return
        }
        let elapsed = Date().timeIntervalSince(prevTime)
        guard elapsed > 0 else { return }
        networkRxRate = Double(rx >= prevNetRx ? rx - prevNetRx : 0) / elapsed
        networkTxRate = Double(tx >= prevNetTx ? tx - prevNetTx : 0) / elapsed
        prevNetRx = rx; prevNetTx = tx; prevNetTime = Date()
    }

    private func parseDiskIO(_ s: String) {
        let parts = s.split(separator: "|")
        if parts.count >= 2 {
            diskReadSectors = UInt64(parts[0]) ?? 0
            diskWriteSectors = UInt64(parts[1]) ?? 0
        }
    }

    private func parseTemp(_ s: String) {
        let val = Double(s.trimmingCharacters(in: .whitespaces))
        cpuTemp = (val != nil && val! > 0) ? val : nil
    }

    private func parseDiskPartitions(_ diskStr: String, inodes: String) {
        // Parse inode data into lookup
        var inodeMap: [String: Int] = [:]
        for line in inodes.split(separator: "\n") {
            let cols = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard cols.count >= 4 else { continue }
            let mount = cols[0]
            let pctStr = cols[3].replacingOccurrences(of: "%", with: "")
            if let pct = Int(pctStr) { inodeMap[mount] = pct }
        }

        diskPartitions = diskStr.split(separator: "\n").compactMap { line in
            let cols = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard cols.count >= 6 else { return nil }
            let pct = Int(cols[5].replacingOccurrences(of: "%", with: "")) ?? 0
            var part = DiskPartitionInfo(
                mount: cols[0], filesystem: cols[1],
                size: cols[2], used: cols[3], available: cols[4], usagePercent: pct
            )
            part.inodeUsedPercent = inodeMap[cols[0]]
            return part
        }
    }

    private func appendHistory() {
        cpuHistory.append(cpuPercent)
        if cpuHistory.count > 60 { cpuHistory.removeFirst() }
        ramHistory.append(ramPercent)
        if ramHistory.count > 60 { ramHistory.removeFirst() }
    }
}
