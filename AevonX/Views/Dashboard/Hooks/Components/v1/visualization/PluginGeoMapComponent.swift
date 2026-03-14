//
//  PluginGeoMapComponent.swift
//  AevonX
//
//  Geographic attack visualization using SwiftUI.
//  Shows country-level attack data with bar chart and top-N list.
//  Data comes from GeoIP-enabled commands.
//

import SwiftUI
import Charts
import AevonXCoreBridge

struct PluginGeoMapComponent: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = PluginDataTableViewModel()
    @State private var hoveredCountry: String? = nil

    private var columns: [HookColumnDefinition] { plugin.columns ?? [] }
    private var dataSource: HookDataSource? { plugin.dataSource }

    private var countryKey: String {
        plugin.chartConfig?.labelKey ?? columns.first?.key ?? "country"
    }
    private var valueKey: String {
        plugin.chartConfig?.valueKey ?? (columns.count > 1 ? columns[1].key : "count")
    }
    private var maxItems: Int { plugin.chartConfig?.maxItems ?? 15 }

    private var geoData: [GeoPoint] {
        vm.rows.compactMap { row -> GeoPoint? in
            guard let country = row[countryKey], !country.isEmpty else { return nil }
            let rawValue = row[valueKey] ?? "0"
            let value = Double(rawValue.components(separatedBy: .whitespaces).first ?? rawValue) ?? 0
            return GeoPoint(country: country, value: value)
        }
        .sorted { $0.value > $1.value }
        .prefix(maxItems)
        .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().background(Color.axBorder)

            if vm.isLoading && vm.rows.isEmpty {
                loadingView
            } else if vm.rows.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.xl) {
                        geoBarChart
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.top, AXSpacing.lg)

                        geoCardsGrid
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.bottom, AXSpacing.lg)
                    }
                }
            }
        }
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder, lineWidth: 1))
        .task {
            await vm.load(plugin: plugin, serverId: serverId, context: context)
        }
    }

    private var header: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: plugin.icon ?? "globe")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.axAccentBlue)
            Text(plugin.name)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Spacer()

            if !geoData.isEmpty {
                let total = geoData.reduce(0.0) { $0 + $1.value }
                Text("\(Int(total)) total from \(geoData.count) countries")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Button(action: { Task { await vm.load(plugin: plugin, serverId: serverId, context: context) } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextMuted)
                    .padding(6)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.lg)
        .background(Color.axBackgroundTertiary)
    }

    private var geoBarChart: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Attack Origins")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Chart(geoData) { point in
                BarMark(
                    x: .value("Requests", point.value),
                    y: .value("Country", point.country)
                )
                .foregroundStyle(barColor(for: point))
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.axTextSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.axBorder)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.axTextMuted)
                }
            }
            .frame(height: CGFloat(max(geoData.count * 28, 100)))
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        )
    }

    private var geoCardsGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 3)
        return LazyVGrid(columns: cols, spacing: AXSpacing.md) {
            ForEach(Array(geoData.enumerated()), id: \.element.country) { index, point in
                geoCard(point: point, rank: index + 1)
            }
        }
    }

    private func geoCard(point: GeoPoint, rank: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text("\(rank)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(rankColor(rank))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(countryFlag(point.country)) \(point.country)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(formatCount(point.value))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()
        }
        .padding(AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
        )
    }

    private func barColor(for point: GeoPoint) -> Color {
        let maxVal = geoData.first?.value ?? 1
        let ratio = point.value / max(maxVal, 1)
        if ratio > 0.7 { return .axError }
        if ratio > 0.3 { return .axWarning }
        return .axAccentBlue
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .axError
        case 2: return .axWarning
        case 3: return .orange
        default: return .axTextMuted
        }
    }

    private func formatCount(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(Int(value))
    }

    private func countryFlag(_ code: String) -> String {
        let uppercased = code.uppercased()
        guard uppercased.count == 2 else { return "🌍" }
        let base: UInt32 = 127397
        var flag = ""
        for scalar in uppercased.unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag.isEmpty ? "🌍" : flag
    }

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView().scaleEffect(1.2)
            Text("Loading geographic data…")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var emptyView: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "globe")
                .font(.system(size: 40))
                .foregroundColor(.axTextMuted)
            Text("No geographic data available")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct GeoPoint: Identifiable {
    let id = UUID()
    let country: String
    let value: Double
}
