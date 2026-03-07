//
//  FileListHeader.swift
//  AevonX
//
//  Column headers for the file list table
//

import SwiftUI
import AevonXCore

// MARK: - File List Header

struct FileListHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            headerColumn("Name", width: nil, alignment: .leading)
            headerColumn("Size", width: 80, alignment: .trailing)
            headerColumn("Mode", width: 50, alignment: .center)
            headerColumn("Owner", width: 70, alignment: .center)
            headerColumn("Modified", width: 130, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axBackgroundSecondary)
    }
    
    private func headerColumn(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        Group {
            if let w = width {
                Text(title)
                    .frame(width: w, alignment: alignment)
            } else {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(.axTextMuted)
    }
}
