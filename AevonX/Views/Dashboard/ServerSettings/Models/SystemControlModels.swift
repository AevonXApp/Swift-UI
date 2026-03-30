//
//  SystemControlModels.swift
//  AevonX
//
//  Data models for system control.
//

import SwiftUI

// MARK: - Hardware Info

struct HardwareInfo {
    var cpuModel = ""
    var cpuCores = ""
    var arch = ""
    var totalRAM = ""
    var totalDisk = ""
}

// MARK: - Swap Info

struct SwapInfo: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let size: String
    let used: String
    let priority: String
}

// MARK: - Kernel Parameter

struct KernelParam: Identifiable {
    var id: String { key }
    let key: String
    var value: String
}
