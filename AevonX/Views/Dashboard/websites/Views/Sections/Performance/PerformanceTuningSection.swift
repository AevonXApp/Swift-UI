//
//  PerformanceTuningSection.swift
//  AevonX
//
//  Performance tuning UI: buffers, timeouts, gzip, presets, worker info
//

import SwiftUI
import AevonXCoreBridge

struct PerformanceTuningSection: View {
    @ObservedObject var viewModel: PerformanceTuningViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Performance Tuning", icon: "slider.horizontal.3")

                // Presets
                AXConfigCard(icon: "wand.and.stars", title: "Quick Presets", subtitle: "Apply a pre-configured performance profile") {
                    HStack(spacing: AXSpacing.md) {
                        presetButton(name: "conservative", icon: "tortoise", color: .axSuccess, description: "Safe defaults")
                        presetButton(name: "balanced", icon: "speedometer", color: .axAccentBlue, description: "Recommended")
                        presetButton(name: "aggressive", icon: "hare", color: .orange, description: "Max performance")
                    }
                }

                // Worker Info
                if let info = viewModel.workerInfo {
                    AXConfigCard(icon: "cpu", title: "Nginx Workers", subtitle: "Current worker configuration") {
                        HStack(spacing: AXSpacing.xl) {
                            infoStat(label: "CPU Cores", value: "\(info.cpuCores)", color: .axAccentBlue)
                            infoStat(label: "Workers", value: info.workerProcesses, color: .axSuccess)
                            infoStat(label: "Connections", value: "\(info.workerConnections)", color: .orange)
                        }
                    }
                }

                // Directives by category
                let categories = Dictionary(grouping: viewModel.directives, by: { $0.category })
                ForEach(["Buffers", "Timeouts", "Compression", "Other"], id: \.self) { category in
                    if let items = categories[category], !items.isEmpty {
                        AXConfigCard(icon: categoryIcon(category), title: category, subtitle: categoryDesc(category)) {
                            VStack(spacing: AXSpacing.sm) {
                                ForEach(items) { item in
                                    directiveRow(item)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadSettings() } }
    }

    // MARK: - Preset Button

    private func presetButton(name: String, icon: String, color: Color, description: String) -> some View {
        Button(action: {
            viewModel.selectedPreset = name
            Task { await viewModel.applyPreset() }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                Text(name.capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(description)
                    .font(.system(size: 9))
                    .foregroundColor(.axTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.md)
            .background(color.opacity(viewModel.selectedPreset == name ? 0.12 : 0.04))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(viewModel.selectedPreset == name ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    // MARK: - Directive Row

    private func directiveRow(_ item: DirectiveItem) -> some View {
        HStack {
            Circle()
                .fill(item.isSet ? Color.axSuccess : Color.axTextMuted.opacity(0.3))
                .frame(width: 6, height: 6)
            Text(item.name)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 200, alignment: .leading)
            Text(item.value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(item.isSet ? .axAccentBlue : .axTextMuted)
            Spacer()
            if !item.isSet {
                Text("default")
                    .font(.system(size: 9))
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.axTextMuted.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
    }

    private func infoStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func categoryIcon(_ cat: String) -> String {
        switch cat {
        case "Buffers": return "memorychip"
        case "Timeouts": return "clock"
        case "Compression": return "arrow.down.right.and.arrow.up.left"
        default: return "gearshape"
        }
    }

    private func categoryDesc(_ cat: String) -> String {
        switch cat {
        case "Buffers": return "Memory allocation for proxied responses"
        case "Timeouts": return "Connection and response timeout durations"
        case "Compression": return "Gzip and HTTP/2 settings"
        default: return "Additional configuration"
        }
    }
}
