//
//  PluginGaugeComponent.swift
//  AevonX
//
//  Circular metric gauge with color thresholds,
//  label, and auto-refresh from data_source.
//

import SwiftUI
import AevonXCore

public struct PluginGaugeComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var value: Double = 0
    @State private var maxValue: Double = 100
    @State private var label: String = ""
    @State private var unit: String = "%"

    public var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Header
            HStack {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
            }

            // Gauge
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.axBorder.opacity(0.3), lineWidth: 8)

                // Value ring
                Circle()
                    .trim(from: 0, to: CGFloat(min(value / maxValue, 1.0)))
                    .stroke(
                        AngularGradient(
                            colors: [gaugeColor.opacity(0.6), gaugeColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: value)

                // Center value
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(gaugeColor)
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
            }
            .frame(width: 100, height: 100)

            // Label
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(AXSpacing.lg)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .task { await loadData() }
    }

    private var gaugeColor: Color {
        let pct = value / maxValue * 100
        if pct >= 90 { return .axError }
        if pct >= 70 { return .axWarning }
        return .axSuccess
    }

    private func loadData() async {
        guard let ds = plugin.dataSource else { return }
        let cmd = HookPluginCommand(type: ds.type ?? .coreCmd, action: ds.action, payload: ds.payload)
        await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

        if let output = vm.resultOutput,
           let data = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            value = json["value"] as? Double ?? 0
            maxValue = json["max"] as? Double ?? 100
            label = json["label"] as? String ?? ""
            unit = json["unit"] as? String ?? "%"
        }
    }
}
