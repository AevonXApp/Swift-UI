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
import AevonXCoreBridge

// MARK: - Chart Type

private enum ChartStyle: String {
    case bar, line, area, doughnut
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

    /// Chart config from plugin definition
    private var chartConfig: HookChartConfig? { plugin.chartConfig }

    private var chartPoints: [ChartPoint] {
        // If chart_config provides keys, use those
        if let config = chartConfig {
            return buildPointsFromConfig(config)
        }
        // Fallback: column-based (first col = label, rest = values)
        guard let labelCol = labelColumn else { return [] }
        var points: [ChartPoint] = []
        for row in vm.rows.prefix(chartConfig?.maxItems ?? 50) {
            let label = row[labelCol.key] ?? "?"
            for valCol in valueColumns {
                let raw = row[valCol.key] ?? "0"
                let value = Double(raw.components(separatedBy: .whitespaces).first ?? raw) ?? 0
                points.append(ChartPoint(label: label, value: value, series: valCol.displayLabel))
            }
        }
        return points
    }

    /// Build chart points from chart_config keys
    private func buildPointsFromConfig(_ config: HookChartConfig) -> [ChartPoint] {
        var points: [ChartPoint] = []
        let max = config.maxItems ?? 50

        if preferredStyle == .doughnut {
            // Pie/Doughnut: use label_key + value_key
            let labelKey = config.labelKey ?? columns.first?.key ?? "label"
            let valueKey = config.valueKey ?? (columns.count > 1 ? columns[1].key : "value")
            for row in vm.rows.prefix(max) {
                let label = row[labelKey] ?? "?"
                let raw = row[valueKey] ?? "0"
                let value = Double(raw.components(separatedBy: .whitespaces).first ?? raw) ?? 0
                points.append(ChartPoint(label: label, value: value, series: label))
            }
        } else {
            // Bar/Line/Area: use x_key + y_keys
            let xKey = config.xKey ?? columns.first?.key ?? "label"
            let yKeys = config.yKeys ?? valueColumns.map { $0.key }
            let labels = config.labels ?? yKeys

            for row in vm.rows.prefix(max) {
                let label = row[xKey] ?? "?"
                for (i, yKey) in yKeys.enumerated() {
                    let raw = row[yKey] ?? "0"
                    let value = Double(raw.components(separatedBy: .whitespaces).first ?? raw) ?? 0
                    let series = i < labels.count ? labels[i] : yKey
                    points.append(ChartPoint(label: label, value: value, series: series))
                }
            }
        }
        return points
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chart content — no toolbar, chart type from JSON only
            if vm.isLoading && vm.rows.isEmpty {
                loadingView
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if chartPoints.isEmpty {
                emptyView
            } else {
                chartContent
                    .padding(AXSpacing.lg)
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
                            Text(col.displayLabel)
                                .font(.system(size: 11))
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }

            // Chart — doughnut (SectorMark) does NOT support axis modifiers
            if chartStyle == .doughnut {
                doughnutChart
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
            } else {
                Group {
                    switch chartStyle {
                    case .bar:
                        barChart
                    case .line:
                        lineChart
                    case .area:
                        areaChart
                    case .doughnut:
                        EmptyView() // handled above
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
        .chartForegroundStyleScale(range: configColors)
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
        .chartForegroundStyleScale(range: configColors)
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
        .chartForegroundStyleScale(range: configColors)
    }

    private var doughnutChart: some View {
        let uniquePoints = Dictionary(grouping: chartPoints, by: { $0.series })
            .compactMap { (series, pts) -> ChartPoint? in
                let total = pts.reduce(0.0) { $0 + $1.value }
                return ChartPoint(label: series, value: total, series: series)
            }
            .sorted { $0.value > $1.value }

        return Chart(uniquePoints) { point in
            SectorMark(
                angle: .value("Value", point.value),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Category", point.label))
            .cornerRadius(3)
        }
        .chartLegend(position: .bottom, spacing: 12)
        .chartForegroundStyleScale(range: configColors)
    }

    // MARK: - Helpers

    private func seriesColor(index: Int) -> Color {
        let colors: [Color] = [.axAccentBlue, .axSuccess, .axWarning, .axError, .purple, .orange]
        return colors[index % colors.count]
    }

    /// Colors from chart_config hex values or default palette
    private var configColors: [Color] {
        if let hexColors = chartConfig?.colors, !hexColors.isEmpty {
            return hexColors.map { hexToColor($0) }
        }
        return [.axAccentBlue, .axSuccess, .axWarning, .axError, .purple, .orange, .cyan, .pink]
    }

    /// Convert hex string to SwiftUI Color
    private func hexToColor(_ hex: String) -> Color {
        let clean = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard clean.count == 6, let rgb = UInt64(clean, radix: 16) else { return .axAccentBlue }
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView().scaleEffect(0.8)
            Text(L10n.PluginsUI.loadingChartData)
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
            Text(L10n.PluginsUI.noChartDataAvailable)
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }
}
