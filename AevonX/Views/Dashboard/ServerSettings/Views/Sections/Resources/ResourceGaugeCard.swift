//
//  ResourceGaugeCard.swift
//  AevonX
//
//  Single metric card with value, progress bar, and optional mini chart.
//

import SwiftUI

struct ResourceGaugeCard<Chart: View>: View {
    let title: String
    let value: String
    let subtitle: String
    let percent: Double
    let color: Color
    var chart: (() -> Chart)? = nil

    init(title: String, value: String, subtitle: String, percent: Double, color: Color,
         @ViewBuilder chart: @escaping () -> Chart) {
        self.title = title; self.value = value; self.subtitle = subtitle
        self.percent = percent; self.color = color; self.chart = chart
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                Text(title).font(AXTypography.caption2).foregroundColor(.axTextMuted)
                Spacer()
            }
            Text(value).font(AXTypography.headline).fontWeight(.bold).foregroundColor(color)
            if percent > 0 {
                progressBar
            }
            if let chartBuilder = chart {
                chartBuilder()
            }
            Text(subtitle).font(AXTypography.caption2).foregroundColor(.axTextTertiary).lineLimit(1)
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(color.opacity(0.15))
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(color)
                    .frame(width: max(geo.size.width * min(percent, 1.0), 0))
            }
        }
        .frame(height: 4)
    }
}

// Convenience init without chart
extension ResourceGaugeCard where Chart == EmptyView {
    init(title: String, value: String, subtitle: String, percent: Double, color: Color) {
        self.title = title; self.value = value; self.subtitle = subtitle
        self.percent = percent; self.color = color; self.chart = nil
    }
}
