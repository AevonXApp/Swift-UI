//
//  PHPPerformanceSection.swift
//  AevonX
//
//  Performance Score section for PHP-FPM.
//

import SwiftUI
import AevonXCoreBridge

struct PHPPerformanceScoreSection: View {
    let serverId: String
    @State private var score: BridgePerformanceScore?
    @State private var isLoading = true

    private let bridge = ApplicationBridge.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                if isLoading {
                    VStack(spacing: AXSpacing.lg) {
                        AXSkeletonStatCard()
                        ForEach(0..<3, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                    .padding(AXSpacing.xl)
                } else if let s = score {
                    ZStack {
                        Circle().stroke(Color.axSurface, lineWidth: 12).frame(width: 120, height: 120)
                        Circle().trim(from: 0, to: Double(s.total) / 100.0)
                            .stroke(scoreColor(s.total), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 120, height: 120).rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(s.total)").font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(scoreColor(s.total))
                            Text("/ 100").font(.system(size: 12)).foregroundColor(.axTextMuted)
                        }
                    }
                    .padding(.top, AXSpacing.xl)

                    VStack(spacing: AXSpacing.md) {
                        ForEach(s.categories, id: \.name) { cat in
                            HStack {
                                Text(cat.name).font(.system(size: 13, weight: .medium)).foregroundColor(.axTextPrimary)
                                Spacer()
                                Text("\(cat.score)").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(scoreColor(cat.score))
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3).fill(Color.axSurface).frame(height: 6)
                                        RoundedRectangle(cornerRadius: 3).fill(scoreColor(cat.score))
                                            .frame(width: geo.size.width * CGFloat(cat.score) / 100.0, height: 6)
                                    }
                                }
                                .frame(width: 100, height: 6)
                            }
                            .padding(AXSpacing.sm)
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.4))
                    .cornerRadius(AXCornerRadius.lg)

                    if !s.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            AXSectionTitle(title: "Suggestions", icon: "lightbulb.fill")
                            ForEach(s.suggestions, id: \.self) { sug in
                                HStack(alignment: .top, spacing: AXSpacing.sm) {
                                    Image(systemName: "arrow.right.circle.fill").font(.system(size: 10)).foregroundColor(.orange).padding(.top, 2)
                                    Text(sug).font(.system(size: 12)).foregroundColor(.axTextSecondary)
                                }
                            }
                        }
                        .padding(AXSpacing.lg)
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.lg)
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadScore() }
    }

    private func loadScore() async {
        let json = await bridge.getPerformanceScore(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<BridgePerformanceScore>.self, from: data),
           r.success { score = r.data }
        isLoading = false
    }

    private func scoreColor(_ s: Int) -> Color {
        if s >= 80 { return .axSuccess }
        if s >= 50 { return .orange }
        return .axError
    }
}
