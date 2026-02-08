//
//  DBDetailSidebar.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBDetailSidebar: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(viewModel.database.type.brandColor)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(viewModel.database.name)
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)

                    Text("\(viewModel.database.type.displayName) \(viewModel.database.version ?? "")")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            }
            .padding(AXSpacing.lg)

            Divider()

            // Navigation
            VStack(spacing: AXSpacing.xxs) {
                ForEach(DatabaseDetailSection.allCases, id: \.self) { section in
                    sidebarRow(section)
                }
            }
            .padding(AXSpacing.sm)

            Spacer()
        }
        .frame(width: 220)
        .background(Color.axBackground)
    }

    private func sidebarRow(_ section: DatabaseDetailSection) -> some View {
        let isSelected = viewModel.currentSection == section
        
        return Button {
            viewModel.currentSection = section
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: section.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? viewModel.database.type.brandColor : .axTextSecondary)
                    .frame(width: 20)
                
                Text(section.rawValue)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
                
                Spacer()
                
                if section == .tables {
                    Text("\(viewModel.tables.count)")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                
                if section == .activityLog && !viewModel.activityLog.isEmpty {
                    Text("\(viewModel.activityLog.count)")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(isSelected ? viewModel.database.type.brandColor.opacity(0.1) : Color.clear)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}
