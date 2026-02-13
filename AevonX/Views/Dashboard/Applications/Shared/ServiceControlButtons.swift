//
//  ServiceControlButtons.swift
//  AevonX
//
//  Unified service control buttons for all service engines
//  Provides Start/Stop/Restart functionality with consistent UI
//

import SwiftUI
import AevonXCore

/// Unified service control buttons (Start, Stop, Restart)
struct ServiceControlButtons: View {
    let application: ApplicationInstance
    let onControl: (ServiceAction) -> Void

    enum ServiceAction: String {
        case start = "start"
        case stop = "stop"
        case restart = "restart"
    }

    var body: some View {
        VStack(spacing: AXSpacing.md) {
            Divider()

            // Status Indicator
            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(application.isRunning ? Color.axSuccess : Color.axError)
                    .frame(width: 6, height: 6)

                Text(application.isRunning ? "Running" : "Stopped")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextSecondary)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.sm)

            // Control Buttons
            HStack(spacing: AXSpacing.sm) {
                UnifiedServiceControlButtonInner(
                    icon: "play.fill",
                    color: .axSuccess,
                    isEnabled: !application.isRunning,
                    action: { onControl(.start) }
                )

                UnifiedServiceControlButtonInner(
                    icon: "stop.fill",
                    color: .axError,
                    isEnabled: application.isRunning,
                    action: { onControl(.stop) }
                )

                UnifiedServiceControlButtonInner(
                    icon: "arrow.clockwise",
                    color: .axAccentBlue,
                    isEnabled: true,
                    action: { onControl(.restart) }
                )
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
    }
}

/// Individual service control button
private struct UnifiedServiceControlButtonInner: View {
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isEnabled ? color : .axTextMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isEnabled ? color.opacity(0.1) : Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(isEnabled ? color.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ServiceControlButtons(
            application: ApplicationInstance(
                name: "MySQL",
                type: .mysql,
                version: "8.0.35",
                isRunning: true
            ),
            onControl: { action in
                print("Control action: \(action.rawValue)")
            }
        )
        .frame(width: 260)
        .background(Color.axSurface.opacity(0.4))

        ServiceControlButtons(
            application: ApplicationInstance(
                name: "PostgreSQL",
                type: .postgresql,
                version: "15.3",
                isRunning: false
            ),
            onControl: { action in
                print("Control action: \(action.rawValue)")
            }
        )
        .frame(width: 260)
        .background(Color.axSurface.opacity(0.4))
    }
    .padding()
    .background(Color.axBackground)
}
