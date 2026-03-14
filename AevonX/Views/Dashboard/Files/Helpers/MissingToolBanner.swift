//
//  MissingToolBanner.swift
//  AevonX
//
//  Warning banner shown when a required tool (zip, unrar, etc.) is not installed
//  Provides one-click install capability
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Missing Tool Banner

struct MissingToolBanner: View {
    let tool: FileManagerViewModel.MissingToolInfo
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AXSpacing.xs) {
                    Text("\(tool.toolName)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("not installed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
                Text(tool.description)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            // Install button
            Button(action: { viewModel.installMissingTool() }) {
                HStack(spacing: 4) {
                    if viewModel.isInstallingTool {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                        Text("Installing...")
                            .font(.system(size: 11, weight: .semibold))
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text("Install")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isInstallingTool)
            
            // Dismiss
            Button(action: {
                viewModel.showMissingToolBanner = false
                viewModel.missingTool = nil
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, AXSpacing.sm)
        .padding(.top, AXSpacing.xs)
    }
}
