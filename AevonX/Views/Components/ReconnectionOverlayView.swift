//
//  ReconnectionOverlayView.swift
//  AevonX
//
//  Reconnection UI with 3-tier visual system:
//  - Banner:  floating top bar with status message
//  - Overlay: full semi-transparent overlay with detailed progress
//

import SwiftUI
import AevonXCore

// MARK: - Reconnection Overlay View

/// A 2-in-1 view that displays either a banner or full overlay
/// depending on the current reconnection tier.
struct ReconnectionOverlayView: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    
    var body: some View {
        Group {
            switch viewModel.reconnectionTier {
            case .silent:
                EmptyView()
                
            case .banner:
                reconnectionBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                
            case .overlay:
                reconnectionOverlay
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.reconnectionTier)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isReconnecting)
        .animation(.easeInOut(duration: 0.3), value: viewModel.reconnectionFailed)
    }
    
    // MARK: - Tier 2: Floating Banner
    
    private var reconnectionBanner: some View {
        VStack {
            HStack(spacing: AXSpacing.md) {
                // Animated spinner
                if !viewModel.reconnectionFailed {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.axWarning)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axError)
                        .font(.system(size: 14))
                }
                
                // Status text
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.reconnectionFailed ? "Reconnection Failed" : "Reconnecting...")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    
                    if let reason = viewModel.reconnectionReason {
                        Text(reason)
                            .font(.system(size: 10))
                            .foregroundColor(.axTextSecondary)
                    }
                }
                
                Spacer()
                
                // Attempt counter
                if viewModel.reconnectionAttempt > 0 && !viewModel.reconnectionFailed {
                    Text("Attempt \(viewModel.reconnectionAttempt)/\(viewModel.reconnectionMaxAttempts)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.axSurface.opacity(0.6))
                        .cornerRadius(4)
                }
                
                // Action button
                if viewModel.reconnectionFailed {
                    Button(action: { viewModel.retryReconnection() }) {
                        Text("Retry")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.axAccentBlue.opacity(0.15))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                
                // Cancel/dismiss
                Button(action: { viewModel.cancelReconnection() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 20, height: 20)
                        .background(Color.axSurface.opacity(0.5))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(
                                viewModel.reconnectionFailed ? Color.axError.opacity(0.3) : Color.axWarning.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            )
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.md)
            
            Spacer()
        }
    }
    
    // MARK: - Tier 3: Full Overlay
    
    private var reconnectionOverlay: some View {
        ZStack {
            // Dimming backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { /* Prevent accidental dismissal */ }
            
            // Central card
            VStack(spacing: AXSpacing.xl) {
                // Animated icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.axWarning.opacity(0.15), lineWidth: 3)
                        .frame(width: 64, height: 64)
                    
                    if !viewModel.reconnectionFailed {
                        // Spinning arc
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(Color.axWarning, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(spinAngle))
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.axWarning)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.axError)
                    }
                }
                
                // Title and message
                VStack(spacing: AXSpacing.sm) {
                    Text(viewModel.reconnectionFailed ? "Reconnection Failed" : "Reconnecting to Server")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    if let reason = viewModel.reconnectionReason {
                        Text(reason)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    if viewModel.reconnectionFailed, let finalError = viewModel.reconnectionFinalError {
                        Text(finalError)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
                
                // Progress info
                if !viewModel.reconnectionFailed {
                    VStack(spacing: AXSpacing.md) {
                        // Progress bar
                        let progress = Double(viewModel.reconnectionAttempt) / Double(viewModel.reconnectionMaxAttempts)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.axSurface)
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.axWarning)
                                .frame(
                                    width: max(0, CGFloat(progress) * 260),
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                        .frame(width: 260, height: 6)
                        
                        // Attempt and timing info
                        HStack {
                            Text("Attempt \(viewModel.reconnectionAttempt) of \(viewModel.reconnectionMaxAttempts)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                            
                            Spacer()
                            
                            if viewModel.reconnectionNextRetryIn > 0 {
                                Text("Next retry in \(Int(viewModel.reconnectionNextRetryIn))s")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                        .frame(width: 260)
                    }
                }
                
                // Action buttons
                HStack(spacing: AXSpacing.md) {
                    // Cancel button
                    Button(action: { viewModel.cancelReconnection() }) {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 100, height: 34)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Retry button (only shown on failure)
                    if viewModel.reconnectionFailed {
                        Button(action: { viewModel.retryReconnection() }) {
                            Text("Retry")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 34)
                                .background(Color.axAccentBlue)
                                .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AXSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .fill(Color.axBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            )
            .frame(maxWidth: 380)
        }
    }
    
    // MARK: - Animation State
    
    @State private var spinAngle: Double = 0
    
    init(viewModel: ServerConnectionViewModel) {
        self.viewModel = viewModel
    }
    
    var animatedBody: some View {
        body
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            }
    }
}

// MARK: - ReconnectionOverlayView with Animation

/// Wrapper that adds the spinning animation for the overlay icon
struct AnimatedReconnectionOverlayView: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var spinAngle: Double = 0
    
    var body: some View {
        ReconnectionOverlayView(viewModel: viewModel)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            }
    }
}
