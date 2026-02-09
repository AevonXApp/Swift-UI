//
//  WebsiteTableView.swift
//  AevonX
//
//  Table view displaying websites with actions
//

import SwiftUI

// MARK: - Website Table View

struct WebsiteTableView: View {
    let websites: [WebsiteInfo]
    let onSelect: (WebsiteInfo) -> Void
    let onToggle: (WebsiteInfo) -> Void
    let onDeploy: (WebsiteInfo) -> Void
    let onDelete: (WebsiteInfo) -> Void
    let onLogs: (WebsiteInfo) -> Void
    let onConfig: (WebsiteInfo) -> Void
    let onSSL: (WebsiteInfo) -> Void

    var body: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                // Table Header
                tableHeader

                Divider()
                    .background(Color.axBorder)

                // Table Rows
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(websites) { website in
                            WebsiteRow(
                                website: website,
                                onToggle: { onToggle(website) },
                                onDeploy: { onDeploy(website) },
                                onDelete: { onDelete(website) },
                                onLogs: { onLogs(website) },
                                onConfig: { onConfig(website) },
                                onSSL: { onSSL(website) }
                            )
                            .onTapGesture {
                                onSelect(website)
                            }
                        }
                    }
                    .padding(AXSpacing.md)
                }
            }
        }
        .padding(.horizontal, AXSpacing.xl)
    }

    private var tableHeader: some View {
        HStack(spacing: AXSpacing.md) {
            Text("Status")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 70, alignment: .leading)

            Text("Website")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 200, alignment: .leading)

            Text("SSL")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 60, alignment: .center)

            Text("Runtime")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 80, alignment: .center)

            Text("Disk")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 80, alignment: .trailing)

            Text("Deployed")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text("Actions")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 120, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axBackgroundTertiary)
    }
}
