//
//  EnhancedLogModels.swift
//  AevonX
//
//  Models and parsers for the website-specific parsed log table.
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

// MARK: - Table Models

struct IndexedLogLine: Identifiable {
    var id: Int { index }
    let index: Int
    let content: String
}

struct ParsedLogLine {
    let timestamp: String
    let level: String
    let ip: String
    let method: String
    let url: String
    let statusCode: String
    let size: String
    let userAgent: String
    let message: String
    let raw: String
}

// MARK: - Log Parser

enum EnhancedLogParser {

    static func parse(_ raw: String) -> ParsedLogLine {
        var timestamp = ""
        var level = "info"
        var ip = ""
        var method = ""
        var url = ""
        var statusCode = ""
        var size = ""
        var userAgent = ""

        let parts = raw.split(separator: " ", maxSplits: 1)
        if let first = parts.first {
            let candidate = String(first)
            if candidate.contains(".") || candidate.contains(":") { ip = candidate }
        }

        if let bracketMatch = raw.range(of: "\\[([^\\]]+)\\]", options: .regularExpression) {
            let rawTS = String(raw[bracketMatch]).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            timestamp = formatTimestamp(rawTS)
        }

        if let reqMatch = raw.range(of: "\"(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS) ([^ ]+) HTTP[^\"]*\"", options: .regularExpression) {
            let reqStr = String(raw[reqMatch]).replacingOccurrences(of: "\"", with: "")
            let reqParts = reqStr.split(separator: " ")
            if reqParts.count >= 2 { method = String(reqParts[0]); url = String(reqParts[1]) }
        }

        let statusPattern = try? NSRegularExpression(pattern: "\" (\\d{3}) (\\d+)", options: [])
        if let match = statusPattern?.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex..., in: raw)) {
            if let r1 = Range(match.range(at: 1), in: raw) { statusCode = String(raw[r1]) }
            if let r2 = Range(match.range(at: 2), in: raw) {
                if let bytes = Int(raw[r2]) { size = AXFormatter.formatBytes(bytes) }
            }
        }

        let uaPattern = try? NSRegularExpression(pattern: "\"([^\"]{15,})\"\\s*$", options: [])
        if let match = uaPattern?.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex..., in: raw)),
           let r = Range(match.range(at: 1), in: raw) { userAgent = String(raw[r]) }

        if let code = Int(statusCode) {
            switch code {
            case 500...599: level = "error"
            case 400...499: level = "warn"
            case 200...399: level = "info"
            default: break
            }
        }

        let lower = raw.lowercased()
        if lower.contains("[error]") || lower.contains("[crit]") || lower.contains("[emerg]") { level = "error" }
        else if lower.contains("[warn") || lower.contains("[notice]") { level = "warn" }

        return ParsedLogLine(
            timestamp: timestamp.isEmpty ? "—" : timestamp,
            level: level, ip: ip, method: method, url: url,
            statusCode: statusCode, size: size, userAgent: userAgent,
            message: raw, raw: raw
        )
    }

    // MARK: - Formatting

    static func formatTimestamp(_ raw: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss Z"
        if let date = formatter.date(from: raw) {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd HH:mm"
            return out.string(from: date)
        }
        formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss"
        if let date = formatter.date(from: raw) {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd HH:mm"
            return out.string(from: date)
        }
        if raw.count > 16 { return String(raw.prefix(16)) }
        return raw
    }


    // MARK: - Badges

    static func levelColor(_ level: String) -> Color {
        switch level {
        case "error", "fatal", "crit": return .red
        case "warn", "notice": return .orange
        case "info": return .green
        default: return .axTextMuted
        }
    }

    static func statusColor(_ code: String) -> Color {
        guard let num = Int(code) else { return .axTextMuted }
        switch num {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .axTextMuted
        }
    }

    static func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .axAccentBlue
        case "POST": return .green
        case "DELETE": return .red
        default: return .axTextMuted
        }
    }
}
