//
//  ConnectionProgressPopup.swift
//  AevonX
//
//  Beautiful connection progress popup with animated progress bar
//

import SwiftUI

struct ConnectionProgressPopup: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    let serverName: String
    let onCancel: () -> Void
    let onSuccess: () -> Void
    
    @State private var showContent = false
    @State private var progressAnimation: Double = 0
    @State private var shimmerOffset: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { /* Prevent dismissal by tapping outside */ }
            
            // Main card
            VStack(spacing: AXSpacing.xl) {
                // Header with icon
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        // Animated ring
                        Circle()
                            .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: progressAnimation)
                            .stroke(
                                Color.axAccentBlue,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progressAnimation)
                        
                        // Icon based on state
                        Image(systemName: connectionIcon)
                            .font(.system(size: 32))
                            .foregroundColor(connectionColor)
                            .symbolEffect(.pulse, options: .repeating, isActive: viewModel.isConnecting)
                    }
                    
                    Text(viewModel.isConnecting ? "Connecting to \(serverName)" : 
                         (viewModel.isConnected ? "Connected!" : "Connection Failed"))
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(viewModel.connectionStage.rawValue)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Progress bar
                VStack(spacing: AXSpacing.sm) {
                    // Progress bar container with fixed width
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axSurface)
                            .frame(height: 8)
                        
                        // Progress
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geometry.size.width * viewModel.connectionProgress), height: 8)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.connectionProgress)
                        }
                        .frame(height: 8)
                        
                        // Shimmer effect - removed infinite animation to save CPU
                        // The progress bar animation is sufficient visual feedback
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("\(Int(viewModel.connectionProgress * 100))%")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                        
                        Spacer()
                        
                        if viewModel.isConnecting {
                            Text("Please wait...")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }
                
                // Error message if failed
                if let error = viewModel.connectionError, !viewModel.isConnecting && !viewModel.isConnected {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axError)
                        Text(error)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                            .multilineTextAlignment(.center)
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                }
                
                // Action buttons
                HStack(spacing: AXSpacing.md) {
                    // Cancel button (shown while connecting)
                    if viewModel.isConnecting {
                        Button(action: {
                            print("[ConnectionProgressPopup] Cancel button tapped")
                            Task {
                                await viewModel.disconnect()
                                onCancel()
                            }
                        }) {
                            Text("Cancel")
                                .font(AXTypography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.axTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Retry button (shown on failure)
                    if !viewModel.isConnecting && !viewModel.isConnected && viewModel.connectionError != nil {
                        Button(action: {
                            print("[ConnectionProgressPopup] Retry button tapped")
                            Task {
                                await viewModel.connect()
                            }
                        }) {
                            Text("Retry")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.axBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AXSpacing.md)
                                .background(Color.axAccentBlue)
                                .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Open Dashboard button (shown on success)
                    if viewModel.isConnected {
                        Button(action: {
                            print("[ConnectionProgressPopup] Open Dashboard button tapped")
                            onSuccess()
                        }) {
                            HStack(spacing: AXSpacing.sm) {
                                Text("Open Dashboard")
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axSuccess)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(AXSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .fill(Color.axBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .frame(maxWidth: 400)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showContent)
        }
        .onAppear {
            print("[ConnectionProgressPopup] Appeared for server: \(serverName)")
            showContent = true
            progressAnimation = viewModel.connectionProgress
            
            // Note: Connection is now handled by ServerDashboardView
            // We don't connect here to avoid duplicate connections
            // The popup just shows the connection progress/status
        }
        .onChange(of: viewModel.connectionProgress) { _, newProgress in
            print("[ConnectionProgressPopup] Progress updated: \(Int(newProgress * 100))%")
            progressAnimation = newProgress
        }
        .onChange(of: viewModel.isConnected) { _, isConnected in
            if isConnected {
                print("[ConnectionProgressPopup] Connection successful!")
                // Auto-open dashboard after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onSuccess()
                }
            }
        }
        .onChange(of: viewModel.connectionError) { _, error in
            if let error = error {
                print("[ConnectionProgressPopup] Connection failed: \(error)")
            }
        }
    }
    
    private var connectionIcon: String {
        if viewModel.isConnected {
            return "checkmark.circle.fill"
        } else if viewModel.connectionError != nil && !viewModel.isConnecting {
            return "xmark.circle.fill"
        } else {
            return "bolt.fill"
        }
    }
    
    private var connectionColor: Color {
        if viewModel.isConnected {
            return .axSuccess
        } else if viewModel.connectionError != nil && !viewModel.isConnecting {
            return .axError
        } else {
            return .axAccentBlue
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.axBackground
        
        ConnectionProgressPopup(
            viewModel: ServerConnectionViewModel(
                server: Server(
                    name: "Test Server",
                    host: "192.168.1.1",
                    port: 22,
                    username: "root",
                    status: .offline,
                    type: .remote,
                    tags: [],
                    lastConnected: nil,
                    os: nil,
                    location: nil
                ),
                serverId: "test-id"
            ),
            serverName: "Test Server",
            onCancel: {},
            onSuccess: {}
        )
    }
}
