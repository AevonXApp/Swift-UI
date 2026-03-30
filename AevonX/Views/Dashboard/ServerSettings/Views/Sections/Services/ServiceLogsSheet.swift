//
//  ServiceLogsSheet.swift
//  AevonX
//
//  Sheet displaying recent logs for a service via journalctl/syslog.
//

import SwiftUI

struct ServiceLogsSheet: View {
    @ObservedObject var vm: ServerSettingsViewModel
    let serviceName: String
    @State private var lineCount: Int32 = 50
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            toolbar
            Divider()
            logsContent
        }
        .frame(minWidth: 600, minHeight: 400)
        .task { await vm.loadServiceLogs(serviceName, lines: lineCount) }
    }

    private var header: some View {
        HStack {
            Image(systemName: "doc.text.fill").foregroundColor(.axAccentBlue)
            Text(L10n.ServerSettings.serviceLogsTitle(serviceName))
                .font(AXTypography.headline).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(AXTypography.body).foregroundColor(.axTextMuted)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.lg)
    }

    private var toolbar: some View {
        HStack(spacing: AXSpacing.md) {
            Picker(L10n.ServerSettings.lines, selection: $lineCount) {
                Text("25").tag(Int32(25))
                Text("50").tag(Int32(50))
                Text("100").tag(Int32(100))
                Text("200").tag(Int32(200))
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            Button(action: { Task { await vm.loadServiceLogs(serviceName, lines: lineCount) } }) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "arrow.clockwise")
                    Text(L10n.Button.refresh)
                }
                .font(AXTypography.caption)
                .foregroundColor(.axAccentBlue)
            }.buttonStyle(PlainButtonStyle())

            Button(action: { copyLogs() }) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "doc.on.doc")
                    Text(L10n.Button.copy)
                }
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)
    }

    private var logsContent: some View {
        ScrollView {
            if vm.isLoadingLogs {
                AXSkeletonBlock(lines: 10)
                    .padding(AXSpacing.lg)
            } else if vm.serviceLogs.isEmpty {
                Text(L10n.ServerSettings.noLogsAvailable)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(AXSpacing.xxxl)
            } else {
                Text(vm.serviceLogs)
                    .font(AXTypography.monoXs)
                    .foregroundColor(.axTextSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AXSpacing.lg)
            }
        }
        .background(Color.axBackground)
    }

    private func copyLogs() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(vm.serviceLogs, forType: .string)
        #endif
    }
}

// Make String identifiable for sheet binding
extension String: @retroactive Identifiable {
    public var id: String { self }
}
