//
//  RemoteFleetHeader.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

struct RemoteFleetHeader: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Binding var showAddServer: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.md) {
                    Text("Remote Fleet")
                        .font(AXTypography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    // Server count badge
                    if !viewModel.isLoading {
                        Text("\(viewModel.decryptedServers.count)")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xxs)
                            .background(Color.axAccentBlue.opacity(0.15))
                            .cornerRadius(AXCornerRadius.full)
                    }
                }

                if !viewModel.isLoading {
                    HStack(spacing: AXSpacing.sm) {
                        HStack(spacing: AXSpacing.xs) {
                            Circle()
                                .fill(Color.axSuccess)
                                .frame(width: 6, height: 6)
                            Text("\(viewModel.decryptedServers.filter { $0.isAccessible }.count) Online")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }

                        Text("•")
                            .foregroundColor(.axTextMuted)

                        HStack(spacing: AXSpacing.xs) {
                            Circle()
                                .fill(Color.axTextMuted)
                                .frame(width: 6, height: 6)
                            Text("\(viewModel.decryptedServers.count - viewModel.decryptedServers.filter { $0.isAccessible }.count) Offline")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }

            Spacer()

            // Add Server Button
            Button(action: {
                showAddServer = true
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Server")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(
                    LinearGradient(
                        colors: viewModel.canAddServer
                            ? [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)]
                            : [Color.axTextMuted, Color.axTextMuted.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
                .shadow(color: viewModel.canAddServer ? Color.axAccentBlue.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.canAddServer)
        }
    }
}
