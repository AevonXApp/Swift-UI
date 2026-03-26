//
//  CronScriptLibrary.swift
//  AevonX
//
//  Pre-built script templates organized by category
//

import SwiftUI
import AevonXCoreBridge

struct CronScriptLibrary: View {
    @ObservedObject var vm: CronViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AXSpacing.sm) {
                    categoryPill(label: "All", icon: "square.grid.2x2", category: nil)
                    ForEach(ScriptCategory.allCases) { cat in
                        categoryPill(label: cat.rawValue, icon: cat.icon, category: cat)
                    }
                }
            }
            
            // Scripts grid
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                ForEach(vm.filteredScripts) { template in
                    scriptCard(template)
                }
            }
        }
    }
    
    private func categoryPill(label: String, icon: String, category: ScriptCategory?) -> some View {
        Button(action: { vm.selectedScriptCategory = category }) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(vm.selectedScriptCategory == category ? .white : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 6)
            .background(vm.selectedScriptCategory == category ? Color.axAccentBlue : Color.axBackgroundTertiary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(vm.selectedScriptCategory == category ? Color.clear : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func scriptCard(_ template: ScriptTemplate) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(categoryColor(template.category).opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: template.taskType.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(categoryColor(template.category))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(template.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    Text(template.category.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axTextTertiary)
                }
                
                Spacer()
            }
            
            Text(template.description)
                .font(.system(size: 10))
                .foregroundColor(.axTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: "clock").font(.system(size: 8))
                    Text(template.defaultSchedule.humanReadable).font(.system(size: 9))
                }
                .foregroundColor(.axTextTertiary)
                
                Spacer()
                
                Button(action: { vm.importTemplate(template) }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 10))
                        Text(L10n.Cron.useTemplate).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .cornerRadius(AXCornerRadius.md)
    }
    
    private func categoryColor(_ category: ScriptCategory) -> Color {
        switch category {
        case .serviceManagement: return .axAccentBlue
        case .monitoring: return .axWarning
        case .backup: return .axAccentGreen
        case .maintenance: return .purple
        case .security: return .axError
        }
    }
}
