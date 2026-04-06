//
//  MoveToApplicationsView.swift
//  AevonX
//
//  Full-screen prompt to move app to /Applications — shown on first launch from DMG or Downloads
//

import SwiftUI

struct MoveToApplicationsView: View {
    @ObservedObject private var locationService = AppLocationService.shared
    @State private var iconFloat: Bool = false
    @State private var glowPulse: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var orb1Offset: CGSize = .init(width: -80, height: -100)
    @State private var orb2Offset: CGSize = .init(width: 100, height: 80)

    var body: some View {
        ZStack {
            Color.axBackground.edgesIgnoringSafeArea(.all)

            // Ambient gradient orbs
            ambientOrbs

            VStack(spacing: 0) {
                Spacer()
                iconSection
                textSection
                    .padding(.top, 36)
                actionSection
                    .padding(.top, 40)
                Spacer()
                footerSection
                    .padding(.bottom, AXSpacing.xxl)
            }
            .frame(maxWidth: 480)
            .padding(.horizontal, AXSpacing.xxxxl)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .onAppear {
            // Orb drift
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                orb1Offset = CGSize(width: -40, height: -60)
                orb2Offset = CGSize(width: 60, height: 50)
            }
            // Icon float
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                iconFloat = true
            }
            // Glow pulse
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            // Content entrance
            withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }

    // MARK: - Ambient Orbs

    private var ambientOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(0.15), Color.clear],
                        center: .center, startRadius: 0, endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(orb1Offset)
                .blur(radius: 60)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "7C6AFF").opacity(0.1), Color.clear],
                        center: .center, startRadius: 0, endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(orb2Offset)
                .blur(radius: 50)
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(Color.axAccentBlue.opacity(glowPulse ? 0.08 : 0.2), lineWidth: 1.5)
                .frame(width: glowPulse ? 160 : 130, height: glowPulse ? 160 : 130)

            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(glowPulse ? 0.15 : 0.08), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            // Deep shadow
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.3))
                .frame(width: 92, height: 92)
                .offset(y: 8)
                .blur(radius: 16)

            // Mid glow shadow
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.axAccentBlue.opacity(0.12))
                .frame(width: 88, height: 88)
                .offset(y: 4)
                .blur(radius: 10)

            // Main icon card
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .axAccentBlue.opacity(0.4), radius: 20, y: 8)

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
            .offset(y: iconFloat ? -4 : 4)
        }
    }

    // MARK: - Text

    private var textSection: some View {
        VStack(spacing: AXSpacing.lg) {
            Text(L10n.Update.moveTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "e2e8f0")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(L10n.Update.moveDescription)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 380)

            if locationService.isRunningFromDMG {
                dmgWarning
            }

            // Feature chips
            HStack(spacing: 10) {
                moveChip(icon: "arrow.down.app.fill", label: "Auto Updates", color: .axAccentBlue)
                moveChip(icon: "power", label: "Launch at Login", color: Color(hex: "4ade80"))
                moveChip(icon: "shield.checkered", label: "Gatekeeper", color: Color(hex: "a78bfa"))
            }
            .padding(.top, AXSpacing.sm)
        }
    }

    private var dmgWarning: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(.axWarning)

            Text(L10n.Update.moveDMGWarning)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.axWarning.opacity(0.9))
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.axWarning.opacity(0.08))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axWarning.opacity(0.2), lineWidth: 1)
        )
    }

    private func moveChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: AXSpacing.md) {
            // Primary: Move to Applications
            Button(action: { locationService.moveToApplications() }) {
                HStack(spacing: 10) {
                    Text(L10n.Update.moveButton)
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: 320)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.axAccentBlue, Color(hex: "22d3ee")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.axAccentBlue.opacity(0.35), radius: 16, y: 6)
            }
            .buttonStyle(.plain)

            // Secondary: Keep Current Location (hidden when running from DMG)
            if !locationService.isRunningFromDMG {
                Button(action: { locationService.dismissPrompt() }) {
                    Text(L10n.Update.moveKeep)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text(L10n.Update.moveFooter)
            .font(.system(size: 10))
            .foregroundColor(Color.white.opacity(0.15))
            .multilineTextAlignment(.center)
    }
}
