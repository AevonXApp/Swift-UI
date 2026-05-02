//
//  FileSidebar.swift
//  AevonX
//
//  Sidebar with quick access paths, sort options, and disk usage
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Sidebar

struct FileSidebar: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.Files.quickAccess)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.md)
                .padding(.top, AXSpacing.md)
                .padding(.bottom, AXSpacing.sm)
            
            ForEach(viewModel.quickAccessPaths, id: \.path) { item in
                sidebarItem(icon: item.icon, title: item.title, path: item.path)
            }
            
            // Favorites section
            if !viewModel.favorites.isEmpty {
                Divider()
                    .background(Color.axBorder)
                    .padding(.vertical, AXSpacing.sm)
                
                Text(L10n.Label.favorites)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.bottom, AXSpacing.xs)
                
                ForEach(viewModel.favorites) { fav in
                    sidebarItem(icon: "star.fill", title: fav.name, path: fav.path)
                }
            }
            
            if !viewModel.quickAccessPaths.isEmpty {
                Divider()
                    .background(Color.axBorder)
                    .padding(.vertical, AXSpacing.sm)
            }
            
            // Sort options
            Text(L10n.Files.sortBy)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.md)
                .padding(.bottom, AXSpacing.xs)
            
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(FileSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(.system(size: 11))
            .padding(.horizontal, AXSpacing.sm)
            
            Spacer()
            
            // Disk usage
            if !viewModel.diskUsage.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text("Used: \(viewModel.diskUsage)")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextTertiary)
                }
                .padding(AXSpacing.md)
            }
        }
        .background(Color.axSurface.opacity(0.4))
    }
    
    private func sidebarItem(icon: String, title: String, path: String) -> some View {
        let isActive = viewModel.currentPath == path
        
        return Button(action: { viewModel.navigateToQuickAccess(path) }) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? .axAccentBlue : .axTextMuted)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? .axTextPrimary : .axTextSecondary)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(isActive ? Color.axAccentBlue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
