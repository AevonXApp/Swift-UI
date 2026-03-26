//
//  AXLaunchLogLine.swift
//  AevonX
//
//  Single log line in the progress terminal.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchLogLineView: View {
    let line: AXLaunchLogLine

    var body: some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Text(line.time)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .frame(width: 70, alignment: .leading)

            Circle()
                .fill(levelColor)
                .frame(width: 6, height: 6)
                .padding(.top, 4)

            Text(line.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(levelColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AXSpacing.xxxs)
    }

    private var levelColor: Color {
        switch line.level {
        case "error": return .axError
        case "warn", "warning": return .axWarning
        case "success": return .axSuccess
        default: return .axTextSecondary
        }
    }
}
