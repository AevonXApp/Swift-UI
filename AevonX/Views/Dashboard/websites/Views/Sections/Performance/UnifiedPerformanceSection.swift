//
//  UnifiedPerformanceSection.swift
//  AevonX
//
//  Unified performance section — merges Performance + Performance Tuning
//

import SwiftUI
import AevonXCore

struct UnifiedPerformanceSection: View {
    let serverId: String
    let domain: String
    let docRoot: String
    @ObservedObject var tuningVM: PerformanceTuningViewModel
    @State private var selectedTab: PerfTab = .analysis

    enum PerfTab: String, CaseIterable, Identifiable {
        case analysis = "Analysis"
        case tuning = "Tuning"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                SectionHeader(title: "Performance", icon: "gauge.with.dots.needle.67percent")

                Picker("", selection: $selectedTab) {
                    ForEach(PerfTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .analysis:
                    PerformanceSection(
                        serverId: serverId,
                        domain: domain,
                        docRoot: docRoot
                    )
                case .tuning:
                    PerformanceTuningSection(viewModel: tuningVM)
                }
            }
        }
        .background(Color.axBackground)
    }
}
