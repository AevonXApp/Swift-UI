//
//  AXLogDetailSheet.swift
//  AevonX
//
//  Log detail sheet + helper views for showing parsed log entry details.
//

import SwiftUI

// MARK: - AX Log Detail Sheet

struct AXLogDetailSheet: View {
    let log: AXLogEntryDisplay
    let viewModel: AXLogsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(log.timeFormatted)
                        .font(.system(size: 12))
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    if log.type == .access {
                        accessLogDetails
                    } else {
                        errorLogDetails
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(width: 700)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }

    private var accessLogDetails: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            AXDetailSection(title: "Request Information", icon: "arrow.right.circle.fill") {
                AXLogDetailRow(label: "Method", value: log.method ?? "N/A")
                AXLogDetailRow(label: "URL", value: log.urlOrMessage)
                AXLogDetailRow(label: "Status Code", value: log.statusCode != nil ? "\(log.statusCode!)" : "N/A")
                AXLogDetailRow(label: "Response Time", value: log.responseTime ?? "N/A")
            }

            AXDetailSection(title: "Client Information", icon: "network") {
                AXLogDetailRow(label: "IP Address", value: log.ip ?? "N/A")
                AXLogDetailRow(label: "User Agent", value: log.userAgent ?? "N/A")
                AXLogDetailRow(label: "Referer", value: log.referer ?? "N/A")
            }

            if let ip = log.ip {
                AXDetailSection(title: "Actions", icon: "shield.fill") {
                    Button(action: {
                        viewModel.selectedIP = ip
                        viewModel.showIPBlockSheet = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Block IP Address: \(ip)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axError)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var errorLogDetails: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            AXDetailSection(title: "Error Information", icon: "exclamationmark.triangle.fill") {
                AXLogDetailRow(label: "Level", value: log.level?.uppercased() ?? "N/A")
                AXLogDetailRow(label: "Message", value: log.urlOrMessage)
                if let file = log.file {
                    AXLogDetailRow(label: "File", value: file)
                }
                if let line = log.line {
                    AXLogDetailRow(label: "Line", value: "\(line)")
                }
            }
        }
    }
}

// MARK: - Detail Helpers

struct AXDetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content

    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axAccentBlue)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.axTextPrimary)
            }
            VStack(spacing: AXSpacing.xs) {
                content()
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }
}

struct AXLogDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
