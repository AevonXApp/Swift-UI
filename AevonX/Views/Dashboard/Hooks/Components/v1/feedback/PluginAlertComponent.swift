//
//  PluginAlertComponent.swift
//  AevonX
//
//  Alert/banner component for displaying persistent notifications
//  with severity levels: info, warning, error, success.
//

import SwiftUI
import AevonXCore

struct PluginAlertComponent: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @State private var isDismissed: Bool = false
    @StateObject private var vm = HookPluginViewModel()
    @State private var dynamicMessage: String? = nil

    private var severity: HookAlertSeverity { plugin.severity ?? .info }
    private var isDismissible: Bool { plugin.dismissible ?? true }

    var body: some View {
        if !isDismissed {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: severityIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(severityColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(plugin.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.axTextPrimary)

                    if let msg = dynamicMessage ?? plugin.description {
                        Text(msg)
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                if let cmd = plugin.command {
                    Button(action: {
                        Task {
                            await vm.execute(
                                command: cmd,
                                pluginId: plugin.id,
                                serverId: serverId,
                                context: context,
                                namespace: plugin.namespace
                            )
                        }
                    }) {
                        Text(plugin.label ?? "Fix")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.xs)
                            .background(severityColor)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if isDismissible {
                    Button(action: { withAnimation(.easeOut(duration: 0.2)) { isDismissed = true } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.axTextMuted)
                            .padding(6)
                            .background(Color.axSurface.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(severityColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(severityColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, AXSpacing.xxl)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task {
                await loadDynamicMessage()
            }
        }
    }

    private var severityIcon: String {
        switch severity {
        case .info:    return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    private var severityColor: Color {
        switch severity {
        case .info:    return .axAccentBlue
        case .warning: return .axWarning
        case .error:   return .axError
        case .success: return .axSuccess
        }
    }

    private func loadDynamicMessage() async {
        guard let ds = plugin.dataSource else { return }
        let command = HookPluginCommand(
            type: ds.type ?? .coreCmd,
            action: ds.action,
            payload: ds.payload,
            timeout: 10
        )
        await vm.execute(
            command: command,
            pluginId: plugin.id,
            serverId: serverId,
            context: context,
            namespace: plugin.namespace
        )
        if let output = vm.resultOutput {
            dynamicMessage = output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
