//
//  FileBreadcrumb.swift
//  AevonX
//
//  Breadcrumb navigation bar for the file browser
//

import SwiftUI
import AevonXCore

// MARK: - Breadcrumb Bar

struct FileBreadcrumb: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Root
                Button(action: { viewModel.navigateTo("/") }) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
                
                let components = viewModel.pathComponents
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.axTextMuted)
                    
                    Button(action: { viewModel.navigateTo(component.path) }) {
                        Text(component.name)
                            .font(.system(size: 12, weight: index == components.count - 1 ? .semibold : .regular))
                            .foregroundColor(index == components.count - 1 ? .axTextPrimary : .axTextSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
