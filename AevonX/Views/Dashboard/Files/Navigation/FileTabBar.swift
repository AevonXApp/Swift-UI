//
//  FileTabBar.swift
//  AevonX
//
//  Tab bar component for multi-tab file browser navigation
//

import SwiftUI
import AevonXCore

// MARK: - File Tab Bar

struct FileTabBar: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(viewModel.tabs.enumerated()), id: \.element.id) { index, tab in
                        tabItem(tab, index: index)
                    }
                }
                .padding(.horizontal, 6)
            }
            
            Spacer()
            
            // New Tab Button — prominent green circle
            Button(action: { viewModel.createTab() }) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 10)
            .help("New Tab")
        }
        .frame(height: 36)
        .background(Color.axBackgroundSecondary)
    }
    
    private func tabItem(_ tab: FileBrowserTabState, index: Int) -> some View {
        let isActive = index == viewModel.activeTabIndex
        
        return HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundColor(isActive ? .blue : .axTextMuted)
            
            Text(tab.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .lineLimit(1)
            
            if viewModel.tabs.count > 1 {
                Button(action: { viewModel.closeTab(at: index) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .foregroundColor(isActive ? .white : .axTextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.axAccentBlue.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { viewModel.switchToTab(index) }
    }
}
