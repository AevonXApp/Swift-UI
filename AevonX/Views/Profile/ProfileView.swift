//
//  ProfileView.swift
//  AevonX
//
//  User Profile - Login/Signup, Account settings, Subscription
//

import SwiftUI
import Combine
import AevonXCore

enum SubscriptionTier: String {
    case free = "Free"
    case pro = "Pro"
    case team = "Team"
    case enterprise = "Enterprise"
    
    var color: Color {
        switch self {
        case .free: return .axTextMuted
        case .pro: return .axAccentBlue
        case .team: return .axAccentGreen
        case .enterprise: return .axWarning
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["3 Servers", "Basic Monitoring", "Email Support"]
        case .pro:
            return ["Unlimited Servers", "Advanced Monitoring", "Priority Support", "SSH Key Management"]
        case .team:
            return ["Everything in Pro", "Team Collaboration", "Shared Credentials", "Audit Logs"]
        case .enterprise:
            return ["Everything in Team", "SSO Integration", "Dedicated Support", "Custom SLA"]
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var vaultViewModel = VaultStatusViewModel()
    @State private var subscription: SubscriptionTier = .pro
    @State private var selectedTab = 0
    @State private var showVaultSetup = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Profile")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
            }
            .padding(AXSpacing.xl)
            
            Divider()
                .background(Color.axBorder)
            
            if authViewModel.isAuthenticated {
                LoggedInView(
                    vaultViewModel: vaultViewModel,
                    subscription: $subscription,
                    selectedTab: $selectedTab,
                    showVaultSetup: $showVaultSetup
                )
                .sheet(isPresented: $showVaultSetup) {
                    VaultSetupView()
                }
            } else {
                LoginView()
            }
        }
        .background(Color.axBackground)
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            Task {
                await vaultViewModel.checkVaultStatus()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                Task {
                    await vaultViewModel.checkVaultStatus()
                }
            }
        }
    }
}

struct LoggedInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var vaultViewModel: VaultStatusViewModel
    @Binding var subscription: SubscriptionTier
    @Binding var selectedTab: Int
    @Binding var showVaultSetup: Bool
    
    // User info from auth view model
    private var userName: String {
        authViewModel.currentUser?.name ?? "User"
    }
    
    private var userEmail: String {
        authViewModel.currentUser?.email ?? ""
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Profile Sidebar
            VStack(spacing: AXSpacing.xl) {
                // Avatar & Info
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.axAccentBlue.opacity(0.3), .axAccentGreen.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text(String(userName.prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.axTextPrimary)
                    }
                    
                    VStack(spacing: AXSpacing.xxs) {
                        Text(userName)
                            .font(AXTypography.title2)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(userEmail)
                            .font(AXTypography.callout)
                            .foregroundColor(.axTextSecondary)
                        
                        HStack(spacing: AXSpacing.xs) {
                            Circle()
                                .fill(subscription.color)
                                .frame(width: 6, height: 6)
                            
                            Text(subscription.rawValue)
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(subscription.color)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxxs)
                                .background(subscription.color.opacity(0.15))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
                .padding(.top, AXSpacing.xl)
                
                Divider()
                    .background(Color.axBorder)
                
                // Navigation
                VStack(spacing: AXSpacing.xs) {
                    ProfileTabButton(
                        icon: "person",
                        title: "Account",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    ProfileTabButton(
                        icon: "creditcard",
                        title: "Subscription",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    ProfileTabButton(
                        icon: "key",
                        title: "API Keys",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    ProfileTabButton(
                        icon: "clock.arrow.circlepath",
                        title: "Activity",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                    
                    // Encryption Vault Button
                    ProfileTabButton(
                        icon: vaultViewModel.isVaultInitialized ? "lock.shield.fill" : "lock.shield",
                        title: "Encryption",
                        isSelected: selectedTab == 4,
                        action: { 
                            if !vaultViewModel.isVaultInitialized {
                                showVaultSetup = true
                            } else {
                                selectedTab = 4
                            }
                        }
                    )
                    .overlay(
                        HStack {
                            Spacer()
                            if !vaultViewModel.isVaultInitialized {
                                Circle()
                                    .fill(Color.axWarning)
                                    .frame(width: 8, height: 8)
                                    .padding(.trailing, AXSpacing.md)
                            }
                        }
                    )
                }
                
                Spacer()
                
                // Sign Out
                Button(action: {
                    Task {
                        await authViewModel.logout()
                    }
                }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 16))
                        
                        Text("Sign Out")
                            .font(AXTypography.body)
                    }
                    .foregroundColor(.axError)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, AXSpacing.lg)
            }
            .frame(width: 240)
            .background(Color.axBackgroundSecondary)
            
            Divider()
                .background(Color.axBorder)
            
            // Content
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    switch selectedTab {
                    case 0:
                        AccountTab()
                    case 1:
                        SubscriptionTab(subscription: $subscription)
                            .environmentObject(authViewModel)
                    case 2:
                        APIKeysTab()
                    case 3:
                        ActivityTab()
                    case 4:
                        EncryptionTab(vaultViewModel: vaultViewModel, showVaultSetup: $showVaultSetup)
                    default:
                        AccountTab()
                    }
                }
                .padding(AXSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.axBackground)
        }
    }
}

struct ProfileTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(AXTypography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
                
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile Tabs

struct AccountTab: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var isEditing = false
    
    init() {
        // Initial values will be set in onAppear to match current user
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSection(title: "Profile Information", icon: "person") {
                VStack(spacing: AXSpacing.md) {
                    HStack {
                        Text("Full Name")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        if isEditing {
                            TextField("", text: $userName)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .frame(width: 200)
                                .textFieldStyle(PlainTextFieldStyle())
                        } else {
                            Text(userName)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    
                    HStack {
                        Text("Email")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        if isEditing {
                            TextField("", text: $userEmail)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .frame(width: 200)
                                .textFieldStyle(PlainTextFieldStyle())
                        } else {
                            Text(userEmail)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    HStack {
                        Spacer()
                        
                        if isEditing {
                            Button(action: { isEditing = false }) {
                                Text("Cancel")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextSecondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { isEditing = false }) {                                
                                Text("Save")
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axBackground)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(Color.axAccentBlue)
                                    .cornerRadius(AXCornerRadius.md)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: { isEditing = true }) {
                                Text("Edit Profile")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            SettingsSection(title: "Security", icon: "lock.shield") {
                VStack(spacing: AXSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                            Text("Password")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                            
                            Text("Last changed 3 months ago")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Change")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axAccentBlue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                            Text("Two-Factor Authentication")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                            
                            Text("Enabled via Authenticator app")
                                .font(AXTypography.caption)
                                .foregroundColor(.axSuccess)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Manage")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axAccentBlue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            SettingsSection(title: "Sessions", icon: "desktopcomputer") {
                VStack(spacing: AXSpacing.md) {
                    SessionRow(device: "MacBook Pro", location: "Current Session", isCurrent: true)
                    SessionRow(device: "iPhone 15 Pro", location: "San Francisco, CA", isCurrent: false)
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    Button(action: {}) {
                        Text("Sign Out All Devices")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            userName = authViewModel.currentUser?.name ?? ""
            userEmail = authViewModel.currentUser?.email ?? ""
        }
    }
}

struct SessionRow: View {
    let device: String
    let location: String
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            Image(systemName: device.contains("iPhone") ? "iphone" : "laptopcomputer")
                .font(.system(size: 20))
                .foregroundColor(.axTextSecondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(device)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                    
                    if isCurrent {
                        Text("Current")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axSuccess)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axSuccess.opacity(0.15))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                }
                
                Text(location)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            if !isCurrent {
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct SubscriptionTab: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var subscription: SubscriptionTier
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Trial Status Banner
            if let trialRemainingDays = authViewModel.trialRemainingDays, trialRemainingDays > 0 {
                TrialBanner(remainingDays: trialRemainingDays, isExpired: false)
            } else if let trialExpired = authViewModel.trialExpired, trialExpired {
                TrialBanner(remainingDays: 0, isExpired: true)
            }
            
            // Current Plan
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                            Text("Current Plan")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                            
                            HStack(spacing: AXSpacing.sm) {
                                Text(subscription.rawValue)
                                    .font(AXTypography.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(subscription.color)
                                
                                if authViewModel.trialRemainingDays != nil {
                                    Text("TRIAL")
                                        .font(AXTypography.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, AXSpacing.xs)
                                        .padding(.vertical, AXSpacing.xxxs)
                                        .background(Color.axAccentBlue.opacity(0.15))
                                        .cornerRadius(AXCornerRadius.sm)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if subscription != .enterprise {
                            Button(action: {}) {
                                Text("Upgrade")
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axBackground)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(Color.axAccentBlue)
                                    .cornerRadius(AXCornerRadius.md)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Divider()
                        .background(Color.axBorder)
                    
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        ForEach(subscription.features, id: \.self) { feature in
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.axSuccess)
                                
                                Text(feature)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                            }
                        }
                    }
                    
                    if subscription != .free {
                        HStack {
                            Text("Renews on January 15, 2025")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Manage Subscription")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            // Available Plans
            Text("Available Plans")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AXSpacing.lg),
                GridItem(.flexible(), spacing: AXSpacing.lg)
            ], spacing: AXSpacing.lg) {
                ForEach([SubscriptionTier.free, .pro, .team, .enterprise], id: \.self) { tier in
                    if tier != subscription {
                        PlanCard(tier: tier)
                    }
                }
            }
        }
    }
}

struct TrialBanner: View {
    let remainingDays: Int?
    let isExpired: Bool?
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: isExpired == true ? "exclamationmark.triangle.fill" : "clock.fill")
                .font(.system(size: 20))
                .foregroundColor(isExpired == true ? .axError : .axAccentBlue)
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(isExpired == true ? "Trial Expired" : "Free Trial Active")
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                
                Text(isExpired == true 
                     ? "Upgrade to continue using all features" 
                     : "\(remainingDays ?? 0) days remaining in your free trial")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Upgrade Now")
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(isExpired == true ? Color.axError : Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill((isExpired == true ? Color.axError : Color.axAccentBlue).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(isExpired == true ? Color.axError.opacity(0.3) : Color.axAccentBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PlanCard: View {
    let tier: SubscriptionTier
    
    var price: String {
        switch tier {
        case .free: return "$0"
        case .pro: return "$9"
        case .team: return "$29"
        case .enterprise: return "Custom"
        }
    }
    
    var period: String {
        tier == .enterprise ? "" : "/month"
    }
    
    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Text(tier.rawValue)
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(tier.color)
                    
                    Spacer()
                }
                
                HStack(alignment: .lastTextBaseline, spacing: AXSpacing.xs) {
                    Text(price)
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(period)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                
                Divider()
                    .background(Color.axBorder)
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    ForEach(tier.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8))
                                .foregroundColor(.axSuccess)
                            
                            Text(feature)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
                
                Button(action: {}) {
                    Text(tier == .enterprise ? "Contact Sales" : "Choose Plan")
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(tier.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.sm)
                        .background(tier.color.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct APIKeysTab: View {
    @State private var apiKeys: [(name: String, key: String, created: Date)] = [
        ("Development", "ax_dev_••••••••••••••••", Date().addingTimeInterval(-86400 * 30)),
        ("CI/CD", "ax_ci_••••••••••••••••", Date().addingTimeInterval(-86400 * 7))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            HStack {
                Text("API Keys")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "plus")
                        Text("New Key")
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(apiKeys.indices, id: \.self) { index in
                        let key = apiKeys[index]
                        HStack {
                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text(key.name)
                                    .font(AXTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axTextPrimary)
                                
                                Text(key.key)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                                    .monospaced()
                            }
                            
                            Spacer()
                            
                            Text("Created \(timeAgo(key.created))")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            
                            Button(action: {}) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextSecondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {}) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axError)
                                    .frame(width: 28, height: 28)
                                    .background(Color.axError.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(AXSpacing.lg)
                        
                        if index < apiKeys.count - 1 {
                            Divider()
                                .background(Color.axBorder)
                                .padding(.leading, AXSpacing.lg)
                        }
                    }
                }
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.axInfo)
                
                Text("Keep your API keys secure. Never share them in public repositories.")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                
                Spacer()
            }
            .padding(.top, AXSpacing.sm)
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 86400 {
            return "today"
        } else if interval < 86400 * 7 {
            return "\(Int(interval / 86400)) days ago"
        } else if interval < 86400 * 30 {
            return "\(Int(interval / (86400 * 7))) weeks ago"
        } else {
            return "\(Int(interval / (86400 * 30))) months ago"
        }
    }
}

struct ActivityTab: View {
    let activities = [
        (icon: "server.rack", color: Color.axAccentBlue, title: "Connected to Production Web", time: "5 minutes ago"),
        (icon: "arrow.up.doc", color: Color.axSuccess, title: "Deployed api.aevonx.io", time: "1 hour ago"),
        (icon: "key", color: Color.axWarning, title: "Rotated SSH keys", time: "3 hours ago"),
        (icon: "gearshape", color: Color.axTextSecondary, title: "Updated Nginx configuration", time: "Yesterday"),
        (icon: "person.badge.plus", color: Color.axAccentGreen, title: "Added team member", time: "2 days ago"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Recent Activity")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(activities.indices, id: \.self) { index in
                        let activity = activities[index]
                        HStack(spacing: AXSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(activity.color.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: activity.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(activity.color)
                            }
                            
                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text(activity.title)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                
                                Text(activity.time)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                            }
                            
                            Spacer()
                        }
                        .padding(AXSpacing.lg)
                        
                        if index < activities.count - 1 {
                            Divider()
                                .background(Color.axBorder)
                                .padding(.leading, AXSpacing.lg + 36 + 12)
                        }
                    }
                }
            }
        }
    }
}

// Legacy LoginView placeholder - the real implementation is in LoginView.swift
// This exists to prevent compilation errors in previews
struct LegacyLoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: AXSpacing.xxl) {
            Spacer()
            
            // Logo
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.axAccentBlue.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.axAccentBlue)
                }
                
                Text("AevonX")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(isSignUp ? "Create your account" : "Sign in to your account")
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextSecondary)
            }
            
            // Form
            VStack(spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Email")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("", text: $email)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Password")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    SecureField("", text: $password)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Button(action: { isLoggedIn = true }) {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .frame(maxWidth: 300)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, AXSpacing.md)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: 300)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Encryption Tab

struct EncryptionTab: View {
    @ObservedObject var vaultViewModel: VaultStatusViewModel
    @Binding var showVaultSetup: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Recovery Key Management Section
            HStack {
                Text("Recovery Key")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                if vaultViewModel.isVaultInitialized {
                    Button(action: { showVaultSetup = true }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "key.viewfinder")
                            Text("View Recovery Key")
                        }
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Recovery Key Status Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.md) {
                        Image(systemName: vaultViewModel.isVaultInitialized ? "key.fill" : "key.slash")
                            .font(.system(size: 24))
                            .foregroundColor(vaultViewModel.isVaultInitialized ? .axSuccess : .axWarning)
                        
                        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                            Text(vaultViewModel.isVaultInitialized ? "Recovery Key Configured" : "Recovery Key Not Set Up")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                            
                            Text(vaultViewModel.isVaultInitialized ? 
                                 "Your zero-knowledge encryption is active. Your data is secured with your Recovery Key." :
                                 "Set up your Recovery Key to enable zero-knowledge encryption for your server data.")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    if !vaultViewModel.isVaultInitialized {
                        Button(action: { showVaultSetup = true }) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("Set Up Recovery Key")
                            }
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, AXSpacing.sm)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
                .background(Color.axBorder)
            
            // Encryption Vault Section
            HStack {
                Text("Encryption Vault")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                if vaultViewModel.isVaultInitialized {
                    HStack(spacing: AXSpacing.xs) {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 8, height: 8)
                        
                        Text("Active")
                            .font(AXTypography.caption)
                            .foregroundColor(.axSuccess)
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(Color.axSuccess.opacity(0.15))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
            
            if vaultViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(AXSpacing.xl)
            } else if vaultViewModel.isVaultInitialized {
                // Vault is initialized - show status
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack(spacing: AXSpacing.md) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.axSuccess)
                            
                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text("Zero-Knowledge Encryption Active")
                                    .font(AXTypography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextPrimary)
                                
                                Text("Your server credentials are encrypted and can only be accessed by you.")
                                    .font(AXTypography.callout)
                                    .foregroundColor(.axTextSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            EncryptionFeatureRow(
                                icon: "key.fill",
                                title: "Master Encryption Key",
                                description: "Stored securely in your Mac's Keychain"
                            )
                            
                            EncryptionFeatureRow(
                                icon: "server.rack",
                                title: "Encrypted Server Data",
                                description: "All server credentials encrypted with AES-256-GCM"
                            )
                            
                            EncryptionFeatureRow(
                                icon: "arrow.left.arrow.right",
                                title: "Secure Communication",
                                description: "ECDH perfect forward secrecy for all sessions"
                            )
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // Show warning about irreversible action
                            }) {
                                Text("Delete Vault")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axError)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Warning note
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundColor(.axWarning)
                    
                    Text("Remember: If you lose your Privacy Password or this Mac, your encrypted data cannot be recovered.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                }
            } else {
                // Vault not initialized or Recovery Required
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack(spacing: AXSpacing.md) {
                            Image(systemName: vaultViewModel.state == .recoveryRequired ? "lock.rotation" : "lock.open")
                                .font(.system(size: 32))
                                .foregroundColor(vaultViewModel.state == .recoveryRequired ? .axAccentBlue : .axWarning)
                            
                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text(vaultViewModel.state == .recoveryRequired ? "Recovery Key Required" : "Encryption Not Set Up")
                                    .font(AXTypography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextPrimary)
                                
                                Text(vaultViewModel.state == .recoveryRequired ? "Your account has encryption enabled, but this Mac needs your Recovery Key to access your data." : "Your server credentials are not encrypted. Set up zero-knowledge encryption to secure your data.")
                                    .font(AXTypography.callout)
                                    .foregroundColor(.axTextSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        Button(action: { showVaultSetup = true }) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: vaultViewModel.state == .recoveryRequired ? "key.fill" : "lock.shield")
                                Text(vaultViewModel.state == .recoveryRequired ? "Unlock with Recovery Key" : "Set Up Encryption")
                            }
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if vaultViewModel.state == .recoveryRequired {
                            Text("This is required once per device. AevonX uses zero-knowledge architecture to ensure only you can access your keys.")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

struct EncryptionFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.axAccentBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                
                Text(description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
        }
    }
}


#Preview {
    ProfileView()
        .background(Color.axBackground)
}
