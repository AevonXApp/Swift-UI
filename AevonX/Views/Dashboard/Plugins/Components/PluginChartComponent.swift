//
//  PluginChartComponent.swift
//  AevonX
//
//  Native SwiftUI Charts component driven by plugin JSON.
//  Supports: bar, line, area chart types.
//  Data fetched via data_source → SSH → parsed → rendered.
//

import SwiftUI
import Charts
import Combine
import AevonXCore

// MARK: - Chart Type

private enum ChartStyle: String {
    case bar, line, area
}

// MARK: - Chart Data Point

private struct ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let series: String
}

// MARK: - Plugin Chart Component

struct PluginChartComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = PluginDataTableViewModel()
    @State private var chartStyle: ChartStyle = .bar

    private var columns: [HookColumnDefinition] { plugin.columns ?? [] }
    private var labelColumn: HookColumnDefinition? { columns.first }
    private var valueColumns: [HookColumnDefinition] { Array(columns.dropFirst()) }

    // Derive chart style from plugin metadata or default to bar
    private var preferredStyle: ChartStyle {
        if let meta = plugin.chartType {
            return ChartStyle(rawValue: meta) ?? .bar
        }
        return .bar
    }

    private var chartPoints: [ChartPoint] {
        guard let labelCol = labelColumn else { return [] }
        var points: [ChartPoint] = []
        for row in vm.rows.prefix(50) {
            let label = row[labelCol.key] ?? "?"
            for valCol in valueColumns {
                let raw = row[valCol.key] ?? "0"
                let value = Double(raw.components(separatedBy: .whitespaces).first ?? raw) ?? 0
                points.append(ChartPoint(label: label, value: value, series: valCol.label))
            }
        }
        return points
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                // Chart type picker
                HStack(spacing: 2) {
                    chartStyleButton(.bar, icon: "chart.bar.fill")
                    chartStyleButton(.line, icon: "chart.line.uptrend.xyaxis")
                    chartStyleButton(.area, icon: "chart.xyaxis.line")
                }
                .padding(3)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))

                Spacer()

                if !vm.rows.isEmpty {
                    Text("\(vm.rows.count) data points")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }

                Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                            .animation(vm.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: vm.isLoading)
                        Text("Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider()

            // Chart content
            if vm.isLoading && vm.rows.isEmpty {
                loadingView
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if chartPoints.isEmpty {
                emptyView
            } else {
                chartContent
                    .padding(AXSpacing.xl)
            }
        }
        .task {
            chartStyle = preferredStyle
            await vm.load(plugin: plugin, serverId: serverId, context: context)
        }
    }

    // MARK: - Chart Renderers

    @ViewBuilder
    private var chartContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Legend
            if valueColumns.count > 1 {
                HStack(spacing: AXSpacing.lg) {
                    ForEach(Array(valueColumns.enumerated()), id: \.offset) { i, col in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(seriesColor(index: i))
                                .frame(width: 12, height: 4)
                            Text(col.label)
                                .font(.system(size: 11))
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }

            // Chart
            Group {
                switch chartStyle {
                case .bar:
                    barChart
                case .line:
                    lineChart
                case .area:
                    areaChart
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.axTextMuted)
                    AxisGridLine()
                        .foregroundStyle(Color.axBorder.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.axTextMuted)
                    AxisGridLine()
                        .foregroundStyle(Color.axBorder.opacity(0.4))
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color.axBackground.opacity(0.5))
            }
        }
    }

    private var barChart: some View {
        Chart(chartPoints) { point in
            BarMark(
                x: .value("Label", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .cornerRadius(3)
        }
        .chartForegroundStyleScale(seriesColorMap)
    }

    private var lineChart: some View {
        Chart(chartPoints) { point in
            LineMark(
                x: .value("Label", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .lineStyle(StrokeStyle(lineWidth: 2))
            .symbol(Circle().strokeBorder(lineWidth: 1.5))
            .symbolSize(30)
        }
        .chartForegroundStyleScale(seriesColorMap)
    }

    private var areaChart: some View {
        Chart(chartPoints) { point in
            AreaMark(
                x: .value("Label", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .opacity(0.3)

            LineMark(
                x: .value("Label", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartForegroundStyleScale(seriesColorMap)
    }

    // MARK: - Helpers

    private func chartStyleButton(_ style: ChartStyle, icon: String) -> some View {
        Button(action: { chartStyle = style }) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(chartStyle == style ? .white : .axTextMuted)
                .frame(width: 28, height: 24)
                .background(chartStyle == style ? Color.axAccentBlue : Color.clear)
                .cornerRadius(AXCornerRadius.xs)
        }
        .buttonStyle(.plain)
    }

    private func seriesColor(index: Int) -> Color {
        let colors: [Color] = [.axAccentBlue, .axSuccess, .axWarning, .axError, .purple, .orange]
        return colors[index % colors.count]
    }

    private var seriesColorMap: KeyValuePairs<String, Color> {
        // Build from valueColumns
        var pairs: [(String, Color)] = []
        for (i, col) in valueColumns.enumerated() {
            pairs.append((col.label, seriesColor(index: i)))
        }
        // KeyValuePairs needs literal — fallback to single color if dynamic
        return ["Value": .axAccentBlue]
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView().scaleEffect(0.8)
            Text("Loading chart data...")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(.axWarning)
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await vm.load(plugin: plugin, serverId: serverId, context: context) }
            }
            .buttonStyle(.plain)
            .foregroundColor(.axAccentBlue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }

    private var emptyView: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "chart.bar")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text("No chart data available")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }
}
