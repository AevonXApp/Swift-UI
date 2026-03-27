//
//  RemoteFleetHeader.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

struct RemoteFleetHeader: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Binding var showAddServer: Bool
    @Binding var showPaywall: Bool
    var onLaunch: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.md) {
                    Text(L10n.Fleet.title)
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
                            Text(L10n.Fleet.online(viewModel.decryptedServers.filter { $0.isAccessible }.count))
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }

                        Text("•")
                            .foregroundColor(.axTextMuted)

                        HStack(spacing: AXSpacing.xs) {
                            Circle()
                                .fill(Color.axTextMuted)
                                .frame(width: 6, height: 6)
                            Text(L10n.Fleet.offline(viewModel.decryptedServers.count - viewModel.decryptedServers.filter { $0.isAccessible }.count))
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }

            Spacer()

            // Launch Button
            if viewModel.isAuthenticated, let onLaunch {
                AXFleetLaunchButton(action: onLaunch)
            }

            // Add Server Button — hidden if not logged in, shows paywall if locked
            if viewModel.isAuthenticated {
                AXFleetAddServerButton(
                    canAdd: viewModel.canAddServer,
                    onAdd: { showAddServer = true },
                    onUpgrade: { showPaywall = true }
                )
            }
        }
    }
}

// MARK: - Launch Button

private struct AXFleetLaunchButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12))
                Text(L10n.AXLaunch.fleetButton)
            }
            .font(AXTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(
                LinearGradient(
                    colors: [Color.axAccentGreen, Color.axAccentGreen.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AXCornerRadius.md)
            .shadow(color: Color.axAccentGreen.opacity(isHovered ? 0.5 : 0.3), radius: isHovered ? 12 : 8, y: 4)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Add Server Button

private struct AXFleetAddServerButton: View {
    let canAdd: Bool
    let onAdd: () -> Void
    let onUpgrade: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: { canAdd ? onAdd() : onUpgrade() }) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: canAdd ? "plus.circle.fill" : "lock.fill")
                    .font(.system(size: 14))
                Text(canAdd ? L10n.Fleet.addServer : L10n.Button.upgrade)
            }
            .font(AXTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(
                LinearGradient(
                    colors: canAdd
                        ? [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)]
                        : [Color.orange, Color.orange.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AXCornerRadius.md)
            .shadow(color: (canAdd ? Color.axAccentBlue : Color.orange).opacity(isHovered ? 0.5 : 0.3), radius: isHovered ? 12 : 8, y: 4)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}
