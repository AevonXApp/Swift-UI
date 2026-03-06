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
    @State private var selectedTab = 0
    @State private var showVaultSetup = false
    
    // Derived from real user data
    private var currentPlan: SubscriptionTier {
        switch authViewModel.currentUser?.plan?.lowercased() {
        case "pro":        return .pro
        case "enterprise": return .enterprise
        default:           return .free
        }
    }
    
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
                    subscription: currentPlan,
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
    let subscription: SubscriptionTier   // read-only, derived from real user plan
    @Binding var selectedTab: Int
    @Binding var showVaultSetup: Bool
    
    // User info from auth view model
    private var userName: String {
        authViewModel.currentUser?.name ?? "User"
    }
    
    private var userEmail: String {
        authViewModel.currentUser?.email ?? ""
    }
    
    private var avatarFallback: some View {
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
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Profile Sidebar
            VStack(spacing: AXSpacing.xl) {
                // Avatar & Info
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        if let urlString = authViewModel.currentUser?.avatarUrl,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                case .failure, .empty:
                                    avatarFallback
                                @unknown default:
                                    avatarFallback
                                }
                            }
                        } else {
                            avatarFallback
                        }
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
                        
                        // Upgrade button — visible only on Free plan
                        if subscription == .free {
                            Button(action: { NSWorkspace.shared.open(AppURLs.pricing) }) {
                                Text("Upgrade")
                                    .font(AXTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, AXSpacing.xxs)
                                    .background(
                                        LinearGradient(
                                            colors: [.axAccentBlue, .axAccentGreen],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, AXSpacing.xl)
                
                Divider()
                    .background(Color.axBorder)
                
                // Navigation
                VStack(spacing: AXSpacing.xs) {
                    AXSidebarTabRow(
                        icon: "person",
                        title: "Account",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    AXSidebarTabRow(
                        icon: "clock.arrow.circlepath",
                        title: "Activity",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    AXSidebarTabRow(
                        icon: vaultViewModel.isVaultInitialized ? "lock.shield.fill" : "lock.shield",
                        title: "Encryption",
                        isSelected: selectedTab == 2,
                        action: { 
                            if !vaultViewModel.isVaultInitialized {
                                showVaultSetup = true
                            } else {
                                selectedTab = 2
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
                            .font(.system(size: 15, weight: .semibold))
                        
                        Text("Sign Out")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(Color.axError)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axError.opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, AXSpacing.lg)
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
                        ActivityTab()
                    case 2:
                        EncryptionTab(vaultViewModel: vaultViewModel, showVaultSetup: $showVaultSetup)
                    default:
                        AccountTab()
                    }
                }
                .padding(AXSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .id(selectedTab)          // Reset scroll to top on every tab switch
            .background(Color.axBackground)
        }
    }
}


// MARK: - Account Tab (Real Data)

struct AccountTab: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileAPI = ProfileAPIService.shared
    
    // Profile edit state
    @State private var editName = ""
    @State private var isEditing = false
    @State private var isSavingProfile = false
    @State private var profileError: String?
    
    // Password state
    @State private var showChangePassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChangingPassword = false
    @State private var passwordError: String?
    @State private var passwordSuccess = false
    
    // Sessions state
    @State private var sessions: [UserSession] = []
    @State private var isLoadingSessions = false
    @State private var sessionError: String?
    @State private var isDeletingSession = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            
            // ── Profile Information ──────────────────────────────────────────
            SettingsSection(title: "Profile Information", icon: "person") {
                VStack(spacing: AXSpacing.md) {
                    HStack {
                        Text("Full Name")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                        if isEditing {
                            TextField("Your name", text: $editName)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .frame(width: 200)
                                .textFieldStyle(PlainTextFieldStyle())
                        } else {
                            Text(authViewModel.currentUser?.name ?? "—")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    
                    HStack {
                        Text("Email")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                        Text(authViewModel.currentUser?.email ?? "—")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    if let err = profileError {
                        Text(err)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                    }
                    
                    Divider().background(Color.axBorder)
                    
                    HStack {
                        Spacer()
                        if isEditing {
                            Button("Cancel") {
                                isEditing = false
                                profileError = nil
                                editName = authViewModel.currentUser?.name ?? ""
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.axTextSecondary)
                            .font(AXTypography.subheadline)
                            
                            Button(action: saveProfile) {
                                if isSavingProfile {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Text("Save")
                                        .font(AXTypography.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.axBackground)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.sm)
                                        .background(Color.axAccentBlue)
                                        .cornerRadius(AXCornerRadius.md)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isSavingProfile || editName.trimmingCharacters(in: .whitespaces).isEmpty)
                        } else {
                            Button("Edit Profile") { isEditing = true }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(.axAccentBlue)
                                .font(AXTypography.subheadline)
                        }
                    }
                }
            }
            
            // ── Security ────────────────────────────────────────────────────
            SettingsSection(title: "Security", icon: "lock.shield") {
                VStack(spacing: AXSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                            Text("Password")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                            Text("Change your account password")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                        Spacer()
                        Button("Change") { showChangePassword = true }
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                            .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isLoading: $isChangingPassword,
                    errorMessage: $passwordError,
                    onSave: changePassword,
                    onCancel: { showChangePassword = false }
                )
            }
            
            // ── Sessions ────────────────────────────────────────────────────
            SettingsSection(title: "Active Sessions", icon: "desktopcomputer") {
                VStack(spacing: AXSpacing.md) {
                    if isLoadingSessions {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    } else if let err = sessionError {
                        Text(err).font(AXTypography.caption).foregroundColor(.axError)
                    } else if sessions.isEmpty {
                        Text("No sessions found")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    } else {
                        ForEach(sessions) { session in
                            SessionRow(
                                session: session,
                                onDelete: { deleteSession(id: session.id) }
                            )
                        }
                    }
                    
                    if !sessions.isEmpty {
                        Divider().background(Color.axBorder)
                        Button(action: signOutAllDevices) {
                            Text("Sign Out All Devices")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axError)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isDeletingSession)
                    }
                }
            }
        }
        .onAppear {
            editName = authViewModel.currentUser?.name ?? ""
            loadSessions()
        }
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        guard !editName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSavingProfile = true
        profileError = nil
        Task {
            do {
                try await profileAPI.updateProfile(name: editName)
                await authViewModel.checkAuthStatus()
                isEditing = false
            } catch {
                profileError = error.localizedDescription
            }
            isSavingProfile = false
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            passwordError = "Passwords do not match"
            return
        }
        isChangingPassword = true
        passwordError = nil
        Task {
            do {
                try await profileAPI.changePassword(current: currentPassword, new: newPassword)
                passwordSuccess = true
                showChangePassword = false
                currentPassword = ""; newPassword = ""; confirmPassword = ""
            } catch {
                passwordError = error.localizedDescription
            }
            isChangingPassword = false
        }
    }
    
    private func loadSessions() {
        isLoadingSessions = true
        Task {
            do {
                sessions = try await profileAPI.fetchSessions()
            } catch {
                sessionError = "Failed to load sessions"
            }
            isLoadingSessions = false
        }
    }
    
    private func deleteSession(id: Int) {
        isDeletingSession = true
        Task {
            do {
                try await profileAPI.deleteSession(id: id)
                sessions.removeAll { $0.id == id }
            } catch {
                sessionError = error.localizedDescription
            }
            isDeletingSession = false
        }
    }
    
    private func signOutAllDevices() {
        isDeletingSession = true
        Task {
            do {
                try await profileAPI.deleteAllSessions()
                sessions = sessions.filter { $0.isCurrent }
            } catch {
                sessionError = error.localizedDescription
            }
            isDeletingSession = false
        }
    }
}

// MARK: - Session Row (Real Data)

struct SessionRow: View {
    let session: UserSession
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: session.deviceIcon)
                .font(.system(size: 20))
                .foregroundColor(.axTextSecondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(session.name)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                    
                    if session.isCurrent {
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
                
                Text("Last active \(session.lastUsedLabel)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            if !session.isCurrent {
                Button(action: onDelete) {
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
    let subscription: SubscriptionTier   // Driven from real user.plan
    
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
                            Button(action: openUpgradePage) {
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
                            Spacer()
                            Button(action: openManageSubscription) {
                                Text("Manage Subscription")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private func openUpgradePage() {
        NSWorkspace.shared.open(AppURLs.pricing)
    }
    
    private func openManageSubscription() {
        NSWorkspace.shared.open(AppURLs.subscription)
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Change Password")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SecureField("Current Password", text: $currentPassword)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                
                SecureField("Confirm New Password", text: $confirmPassword)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
            }
            
            if let err = errorMessage {
                Text(err)
                    .font(AXTypography.caption)
                    .foregroundColor(.axError)
            }
            
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.axTextSecondary)
                
                Button(action: onSave) {
                    if isLoading {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text("Save")
                            .fontWeight(.medium)
                            .foregroundColor(.axBackground)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400)
        .background(Color.axBackground)
    }
}

// MARK: - Trial Banner

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

// MARK: - API Keys Tab (Stub — no developer API)

struct APIKeysTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            AXCard {
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.axInfo)
                    Text("API Keys are not available. AevonX does not offer a public developer API at this time.")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                }
            }
        }
    }
}

// MARK: - Activity Tab (Real Data)

struct ActivityTab: View {
    @StateObject private var profileAPI = ProfileAPIService.shared
    @State private var activities: [ActivityLogEntry] = []
    @State private var isLoading = true
    @State private var loadError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Recent Activity")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            if isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let err = loadError {
                Text(err).font(AXTypography.caption).foregroundColor(.axError)
            } else if activities.isEmpty {
                Text("No activity recorded yet.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextMuted)
            } else {
                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                            HStack(spacing: AXSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(activityColor(activity.color).opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: activity.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(activityColor(activity.color))
                                }
                                
                                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                    Text(activity.description)
                                        .font(AXTypography.body)
                                        .foregroundColor(.axTextPrimary)
                                    
                                    if let context = activity.context {
                                        Text(context)
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(timeAgo(activity.createdAt))
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
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
        .onAppear { loadActivity() }
    }
    
    private func loadActivity() {
        isLoading = true
        Task {
            do {
                activities = try await profileAPI.fetchActivity(limit: 30)
            } catch {
                loadError = "Failed to load activity"
            }
            isLoading = false
        }
    }
    
    private func activityColor(_ colorName: String) -> Color {
        switch colorName {
        case "green":  return .axSuccess
        case "blue":   return .axAccentBlue
        case "purple": return .axAccentBlue
        case "red":    return .axError
        case "orange": return .axWarning
        case "yellow": return .axWarning
        default:       return .axTextMuted
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        AXFormatter.formatTimeAgo(date)
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
    @State private var showBackupKey = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Encryption Key Status Section
            HStack {
                Text("Encryption Key")
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
                // Active encryption - show status and actions
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
                                
                                Text("Your server credentials are encrypted with your personal encryption key. Only you can access them.")
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
                                title: "Encryption Key",
                                description: "Stored securely in your Mac's Keychain with biometric protection"
                            )
                            
                            EncryptionFeatureRow(
                                icon: "server.rack",
                                title: "Encrypted Server Data",
                                description: "All server credentials encrypted with AES-256-GCM"
                            )
                            
                            EncryptionFeatureRow(
                                icon: "eye.slash.fill",
                                title: "Zero-Knowledge Architecture",
                                description: "The server never sees your encryption key or decrypted data"
                            )
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        // Action rows
                        VStack(spacing: AXSpacing.sm) {
                            Button(action: { showBackupKey = true }) {
                                HStack(spacing: AXSpacing.md) {
                                    Image(systemName: "key.viewfinder")
                                        .font(.system(size: 18))
                                        .foregroundColor(.axAccentBlue)
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Backup Key")
                                            .font(AXTypography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.axTextPrimary)
                                        
                                        Text("View and copy your encryption key (requires biometric)")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.axTextMuted)
                                }
                                .padding(AXSpacing.md)
                                .background(Color.axBackgroundSecondary)
                                .cornerRadius(AXCornerRadius.md)
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
                    
                    Text("If you lose your Encryption Key, your encrypted server data cannot be recovered. Make sure to back it up securely.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                }
            } else {
                // Not initialized or recovery required
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack(spacing: AXSpacing.md) {
                            Image(systemName: vaultViewModel.state == .recoveryRequired ? "lock.rotation" : "lock.open")
                                .font(.system(size: 32))
                                .foregroundColor(vaultViewModel.state == .recoveryRequired ? .axAccentBlue : .axWarning)
                            
                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text(vaultViewModel.state == .recoveryRequired ? "Encryption Key Required" : "Encryption Not Set Up")
                                    .font(AXTypography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextPrimary)
                                
                                Text(vaultViewModel.state == .recoveryRequired ? "Your account has encryption enabled, but this device needs your Encryption Key to access your data." : "Set up encryption to secure your server credentials with zero-knowledge architecture.")
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
                                Text(vaultViewModel.state == .recoveryRequired ? "Enter Encryption Key" : "Set Up Encryption")
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
                            Text("Enter the Encryption Key you saved when first setting up your account. AevonX uses zero-knowledge architecture \u{2014} only you have this key.")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showBackupKey) {
            EncryptionKeyDisplayView()
                .frame(minWidth: 500, minHeight: 400)
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
