//
//  TransferSpeedTracker.swift
//  AevonX
//
//  Calculates real-time upload/download speed and ETA
//

import Foundation

// MARK: - Transfer Speed Tracker

class TransferSpeedTracker {
    private var checkpoints: [(time: Date, bytes: Int64)] = []
    private let windowSize: TimeInterval = 3.0  // 3-second rolling window
    
    /// Record a progress checkpoint
    func record(bytesTransferred: Int64) {
        let now = Date()
        checkpoints.append((time: now, bytes: bytesTransferred))
        
        // Keep only recent checkpoints within the window
        checkpoints.removeAll { now.timeIntervalSince($0.time) > windowSize }
    }
    
    /// Current speed in bytes per second
    var bytesPerSecond: Double {
        guard checkpoints.count >= 2,
              let first = checkpoints.first,
              let last = checkpoints.last else {
            return 0
        }
        
        let elapsed = last.time.timeIntervalSince(first.time)
        guard elapsed > 0 else { return 0 }
        
        let bytesTransferred = last.bytes - first.bytes
        return Double(bytesTransferred) / elapsed
    }
    
    /// Formatted speed string (e.g. "1.5 MB/s")
    var formattedSpeed: String {
        let bps = bytesPerSecond
        if bps <= 0 { return "—" }
        
        if bps >= 1_073_741_824 {
            return String(format: "%.1f GB/s", bps / 1_073_741_824)
        } else if bps >= 1_048_576 {
            return String(format: "%.1f MB/s", bps / 1_048_576)
        } else if bps >= 1024 {
            return String(format: "%.0f KB/s", bps / 1024)
        } else {
            return String(format: "%.0f B/s", bps)
        }
    }
    
    /// Estimated time remaining
    func eta(totalBytes: Int64, currentBytes: Int64) -> String {
        let bps = bytesPerSecond
        guard bps > 0 else { return "—" }
        
        let remaining = Double(totalBytes - currentBytes)
        let seconds = remaining / bps
        
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins)m \(secs)s"
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return "\(hours)h \(mins)m"
        }
    }
    
    /// Reset all checkpoints
    func reset() {
        checkpoints.removeAll()
    }
}
