//
//  SidebarView.swift
//  AevonX
//
//  Premium sidebar with app icon branding and polished micro-animations	
//

import SwiftUI
import AevonXCoreBridge

enum NavigationItem: String, CaseIterable, Identifiable {
    case remoteFleet = "Remote Fleet"
    case userProfile = "User Profile"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .remoteFleet: return "server.rack"
        case .userProfile: return "person.crop.circle"
        case .settings: return "gearshape.2"
        }
    }
    
    var shortcut: String {
        switch self {
        case .remoteFleet: return "⌘1"
        case .userProfile: return "⌘2"
        case .settings: return "⌘,"
        }
    }
    
    var subtitle: String {
        switch self {
        case .remoteFleet: return "Manage servers"
        case .userProfile: return "Account & API"
        case .settings: return "Preferences"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem
    @Binding var selectedServer: Server?
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var isLogoHovered = true
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var currentPlanLabel: String {
        if let remaining = authViewModel.trialRemainingDays, remaining > 0 {
            return "Trial"
        }
        return authViewModel.currentUser?.plan?.capitalized ?? "Free"
    }
    
    private var planBadgeColor: Color {
        if isTrialActive { return .axAccentGreen }
        switch currentPlanLabel.lowercased() {
        case "pro": return .axAccentBlue
        case "team": return .axAccentGreen
        case "enterprise": return .orange
        default: return .axTextMuted
        }
    }
    
    private var isTrialActive: Bool {
        if let remaining = authViewModel.trialRemainingDays, remaining > 0 {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── App Branding ───────────────────────────────────
            brandingHeader
            
            // ─── Navigation ─────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: AXSpacing.xxs) {
                    sectionHeader("NAVIGATION")
                    
                    ForEach(NavigationItem.allCases) { item in
                        SidebarNavItem(
                            item: item,
                            isSelected: selectedItem == item,
                            action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedItem = item
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.top, AXSpacing.md)
            }
            
            Spacer()
            
            // ─── Subscription / Trial Info ──────────────────────
            if authViewModel.isAuthenticated {
                subscriptionSection
            }
            
            // ─── Footer ────────────────────────────────────────
            footerStatus
        }
        .frame(width: 240)
        .background(sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.axAccentBlue.opacity(0.15), Color.axAccentBlue.opacity(0.02), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)
        }
        .onAppear { }
    }
    
    // MARK: - Branding Header
    
    private var brandingHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                // App Icon
                ZStack {
                    // Subtle glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.axAccentBlue.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 22,
                                endRadius: 36
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    #if os(macOS)
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, y: 1)
                    #endif
                }

                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AevonX")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 4) {
                        Text("v\(appVersion)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axAccentBlue.opacity(0.8))
                        
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.axTextMuted)
                        
                        Text(currentPlanLabel)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(planBadgeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(planBadgeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.lg + 4)
            .onHover { isLogoHovered = $0 }
            
            // Accent line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.axAccentBlue.opacity(0.4), Color.axAccentBlue.opacity(0.6), Color.axAccentBlue.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.lg)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.axTextMuted)
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.top, AXSpacing.sm)
        .padding(.bottom, AXSpacing.xxs)
    }
    
    // MARK: - Subscription / Trial Section
    
    private var subscriptionSection: some View {
        VStack(spacing: AXSpacing.sm) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.axBorder.opacity(0.5), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.lg)
            
            VStack(spacing: AXSpacing.sm) {
                if isTrialActive {
                    // Trial active — show countdown
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 13))
                            .foregroundColor(.axAccentGreen)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Trial Active")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextPrimary)
                            
                            Text("\(authViewModel.trialRemainingDays ?? 0) days remaining")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.axAccentGreen)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    
                    // Renew button
                    Button(action: { NSWorkspace.shared.open(AevonXCoreBridge.AppURLs.pricing) }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Renew")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xs)
                        .background(
                            LinearGradient(
                                colors: [.axAccentBlue, .axAccentGreen],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, AXSpacing.lg)
                    
                } else if authViewModel.trialExpired == true {
                    // Trial expired
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 13))
                            .foregroundColor(.axWarning)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Trial Expired")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextPrimary)
                            
                            Text("Upgrade to continue")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.axWarning)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    
                    Button(action: { NSWorkspace.shared.open(AevonXCoreBridge.AppURLs.pricing) }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Upgrade Now")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xs)
                        .background(
                            LinearGradient(
                                colors: [.axWarning, .axAccentBlue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, AXSpacing.lg)
                    
                } else if currentPlanLabel.lowercased() == "free" {
                    // Free plan — no trial
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.axTextMuted)
                        
                        Text("Free Plan")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    
                    Button(action: { NSWorkspace.shared.open(AevonXCoreBridge.AppURLs.pricing) }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Upgrade")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xs)
                        .background(
                            LinearGradient(
                                colors: [.axAccentBlue, .axAccentGreen],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, AXSpacing.lg)
                }
            }
            .padding(.vertical, AXSpacing.sm)
        }
    }
    
    // MARK: - Footer Status
    
    private var footerStatus: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.axBorder.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.lg)
            
            HStack(spacing: AXSpacing.sm) {
                // Status dot with pulse
                ZStack {
                    Circle()
                        .fill(Color.axSuccess.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .scaleEffect(1.0)
                    
                    Circle()
                        .fill(Color.axSuccess)
                        .frame(width: 6, height: 6)
                        .shadow(color: .axSuccess.opacity(0.5), radius: 3)
                }
                
                Text("Connected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                
                Spacer()
                
                Text("v\(appVersion)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.axSurface.opacity(0.5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md + 2)
        }
    }
    
    // MARK: - Background
    
    private var sidebarBackground: some View {
        ZStack {
            Color.axBackgroundSecondary
            
            // Ambient glow from top
            RadialGradient(
                colors: [
                    Color.axAccentBlue.opacity(0.03),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 300
            )
            
            // Dark vignette at bottom
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Navigation Item Row

private struct SidebarNavItem: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : (isHovered ? Color.axSurface : Color.clear))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .axAccentBlue : (isHovered ? .axTextPrimary : .axTextMuted))
                        .symbolEffect(.bounce, value: isSelected)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .axTextPrimary : (isHovered ? .axTextPrimary : .axTextSecondary))
                    
                    Text(item.subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .axAccentBlue.opacity(0.7) : .axTextMuted)
                }
                
                Spacer()
                
                // Shortcut badge
                Text(item.shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .axAccentBlue.opacity(0.8) : .axTextMuted.opacity(0.6))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.axSurface.opacity(isHovered ? 0.6 : 0.3))
                    )
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.sm)
            .background(
                ZStack {
                    // Selection background
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.08) : (isHovered ? Color.axSurfaceHover.opacity(0.3) : .clear))
                    
                    // Selection border glow
                    if isSelected {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
                    }
                }
            )
            // Active indicator bar
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axAccentBlue)
                        .frame(width: 3, height: 20)
                        .shadow(color: .axAccentBlue.opacity(0.5), radius: 4)
                        .offset(x: -2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    SidebarView(
        selectedItem: .constant(.remoteFleet),
        selectedServer: .constant(nil)
    )
    .frame(height: 600)
    .background(Color.axBackground)
}
