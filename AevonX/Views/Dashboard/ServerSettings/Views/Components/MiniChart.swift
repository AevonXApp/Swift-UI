//
//  MiniChart.swift
//  AevonX
//
//  Sparkline chart for resource monitoring history.
//

import SwiftUI

struct MiniChart: View {
    let values: [Double]
    let maxValue: Double
    let color: Color
    var height: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            if values.count > 1 {
                Path { path in
                    let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
                    let scaleY = geo.size.height / CGFloat(max(maxValue, 1))

                    path.move(to: point(0, geo.size, stepX, scaleY))
                    for i in 1..<values.count {
                        path.addLine(to: point(i, geo.size, stepX, scaleY))
                    }
                }
                .stroke(color, lineWidth: 1.5)

                Path { path in
                    let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
                    let scaleY = geo.size.height / CGFloat(max(maxValue, 1))

                    path.move(to: CGPoint(x: 0, y: geo.size.height))
                    for i in 0..<values.count {
                        path.addLine(to: point(i, geo.size, stepX, scaleY))
                    }
                    path.addLine(to: CGPoint(x: CGFloat(values.count - 1) * stepX, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(color.opacity(0.1))
            }
        }
        .frame(height: height)
    }

    private func point(_ i: Int, _ size: CGSize, _ stepX: CGFloat, _ scaleY: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(i) * stepX,
            y: size.height - CGFloat(min(values[i], maxValue)) * scaleY
        )
    }
}
