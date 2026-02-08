//
//  AddServerView.swift
//  AevonX
//
//  Premium server addition interface with glassmorphism and micro-animations
//

import SwiftUI
import AevonXCore
import Combine

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddServerViewModel()
    @State private var formProgress: CGFloat = 0
    @State private var showContent = false
    
    var onSave: (AddServerRequest) -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.axBackground,
                    Color.axBackgroundSecondary.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle animated accent glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 60)
            
            VStack(spacing: 0) {
                // Premium Header
                headerSection
                    .padding(.bottom, AXSpacing.lg)
                
                // Form Content with Transitions
                VStack {
                    ZStack {
                        switch viewModel.currentStep {
                        case .identity:
                            serverIdentityCard
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .connection:
                            connectionDetailsCard
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .authentication:
                            authenticationCard
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .verify:
                            connectionTestCard
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    
                    Spacer()
                    
                    // Wizard Navigation
                    HStack(spacing: AXSpacing.md) {
                        if !viewModel.isFirstStep {
                            AXPrimaryButton(title: "Back", icon: "chevron.left", action: {
                                withAnimation { viewModel.prevStep() }
                            }, style: .secondary)
                        } else {
                            AXPrimaryButton(title: "Cancel", icon: nil, action: {
                                dismiss()
                            }, style: .secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.isLastStep {
                            AXPrimaryButton(
                                title: "Save Server",
                                icon: "checkmark.circle.fill",
                                action: {
                                    if let request = viewModel.buildRequest() {
                                        onSave(request)
                                        dismiss()
                                    }
                                },
                                isDisabled: !viewModel.isValid
                            )
                        } else {
                            AXPrimaryButton(
                                title: "Next",
                                icon: "chevron.right",
                                action: {
                                    withAnimation { viewModel.nextStep() }
                                },
                                isDisabled: !viewModel.isCurrentStepValid
                            )
                        }
                    }
                    .padding(AXSpacing.xl)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
        .onChange(of: viewModel.name) { _, _ in updateProgress() }
        .onChange(of: viewModel.host) { _, _ in updateProgress() }
        .onChange(of: viewModel.username) { _, _ in updateProgress() }
        .onChange(of: viewModel.password) { _, _ in updateProgress() }
        .onChange(of: viewModel.privateKey) { _, _ in updateProgress() }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AXSpacing.md) {
            ZStack {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.axSurface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Server icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.axAccentBlue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.axAccentBlue, Color.axAccentGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.lg)
            
            VStack(spacing: AXSpacing.xs) {
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(subtitleForStep(viewModel.currentStep))
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            
            // Progress indicator (Wizard Steps)
            HStack(spacing: AXSpacing.sm) {
                ForEach(AddServerViewModel.Step.allCases, id: \.self) { step in
                    stepIndicator(for: step)
                }
            }
            .padding(.top, AXSpacing.sm)
        }
    }
    
    private func subtitleForStep(_ step: AddServerViewModel.Step) -> String {
        switch step {
        case .identity: return "Define how your server appears in the fleet"
        case .connection: return "Specify the network address and port"
        case .authentication: return "How should we securely access the system?"
        case .verify: return "Let's test the connection before saving"
        }
    }
    
    private func stepIndicator(for step: AddServerViewModel.Step) -> some View {
        let isCurrent = viewModel.currentStep == step
        let isCompleted = viewModel.currentStep.rawValue > step.rawValue
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(isCurrent || isCompleted ? Color.axAccentBlue : Color.axBorder)
            .frame(width: isCurrent ? 32 : 12, height: 4)
            .animation(.spring(response: 0.3), value: viewModel.currentStep)
    }
    
    // MARK: - Server Identity Card
    
    private var serverIdentityCard: some View {
        GlassCard(icon: "tag.fill", title: "Server Identity", iconColor: .axAccentBlue) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: "Server Name",
                    text: $viewModel.name,
                    placeholder: "My Production Server",
                    icon: "text.cursor"
                )
                
                // Icon Picker
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "app.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text("Icon")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(ServerIcon.allCases) { icon in
                                Button {
                                    viewModel.selectedIcon = icon
                                } label: {
                                    Image(systemName: icon.rawValue)
                                        .font(.system(size: 18))
                                        .foregroundColor(viewModel.selectedIcon == icon ? .white : .axTextSecondary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .fill(viewModel.selectedIcon == icon ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Color Picker
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text("Color")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    HStack(spacing: AXSpacing.sm) {
                        ForEach(ServerColor.allCases) { color in
                            Button {
                                viewModel.selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color.rawValue))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: viewModel.selectedColor == color ? 2 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                    .overlay {
                                        if viewModel.selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                PremiumTextField(
                    title: "Tags",
                    text: $viewModel.tagsText,
                    placeholder: "production, web, database",
                    icon: "tag",
                    isOptional: true
                )
            }
        }
    }
    
    // MARK: - Connection Details Card
    
    private var connectionDetailsCard: some View {
        GlassCard(icon: "network", title: "Connection Details", iconColor: .axAccentGreen) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: "Host",
                    text: $viewModel.host,
                    placeholder: "server.example.com",
                    icon: "globe"
                )
                
                HStack(spacing: AXSpacing.md) {
                    PremiumTextField(
                        title: "Port",
                        text: Binding(
                            get: { String(viewModel.port) },
                            set: { viewModel.port = Int($0) ?? 22 }
                        ),
                        placeholder: "22",
                        icon: "number"
                    )
                    .frame(maxWidth: 100)
                    
                    PremiumTextField(
                        title: "Username",
                        text: $viewModel.username,
                        placeholder: "root",
                        icon: "person"
                    )
                }
            }
        }
    }
    
    // MARK: - Authentication Card
    
    private var authenticationCard: some View {
        GlassCard(icon: "key.fill", title: "Authentication", iconColor: .orange) {
            VStack(spacing: AXSpacing.lg) {
                // Auth Type Selector
                AuthTypePicker(selection: $viewModel.authType)
                
                // Auth Fields
                if viewModel.authType == .password {
                    PremiumSecureField(
                        title: "Password",
                        text: $viewModel.password,
                        placeholder: "Enter SSH password",
                        icon: "lock.fill"
                    )
                } else {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextMuted)
                            Text("Private Key")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                        
                        TextEditor(text: $viewModel.privateKey)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100, maxHeight: 150)
                            .padding(AXSpacing.md)
                            .background(Color.axBackgroundTertiary)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if viewModel.privateKey.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("Paste your private key here...")
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(.axTextMuted)
                                                    .padding(.top, AXSpacing.md)
                                                    .padding(.leading, AXSpacing.md + 5)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .allowsHitTesting(false)
                            )
                    }
                    
                    PremiumSecureField(
                        title: "Key Passphrase",
                        text: $viewModel.keyPassphrase,
                        placeholder: "Optional passphrase",
                        icon: "lock.shield",
                        isOptional: true
                    )
                }
            }
        }
    }
    
    // MARK: - Connection Test Card
    
    private var connectionTestCard: some View {
        GlassCard(icon: "wifi", title: "Connection Test", iconColor: .purple) {
            VStack(spacing: AXSpacing.md) {
                // Test Button
                Button {
                    Task {
                        await viewModel.testConnection()
                    }
                } label: {
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text(viewModel.isTesting ? "Testing..." : "Test Connection")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.md)
                    .background(
                        Group {
                            if viewModel.canTest {
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.axTextMuted
                            }
                        }
                    )
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isTesting || !viewModel.canTest)
                
                // Progress
                if let progress = viewModel.connectionProgress {
                    PremiumProgressView(progress: progress)
                }
                
                // Result
                if let result = viewModel.testResult {
                    PremiumResultView(result: result)
                }
            }
        }
    }
}

// MARK: - Glass Card Component

struct GlassCard<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
            }
            
            content
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(Color.axGlassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Premium Text Field

struct PremiumTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String = ""
    var isOptional: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xxs) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                if isOptional {
                    Text("(optional)")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextMuted.opacity(0.6))
                }
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(.axTextPrimary)
                .focused($isFocused)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(isFocused ? Color.axAccentBlue : Color.axBorder, lineWidth: isFocused ? 1.5 : 1)
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Premium Secure Field

struct PremiumSecureField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String = ""
    var isOptional: Bool = false
    @FocusState private var isFocused: Bool
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xxs) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                if isOptional {
                    Text("(optional)")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextMuted.opacity(0.6))
                }
            }
            
            HStack {
                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.axTextPrimary)
                .focused($isFocused)
                
                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isFocused ? Color.axAccentBlue : Color.axBorder, lineWidth: isFocused ? 1.5 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Auth Type Picker

struct AuthTypePicker: View {
    @Binding var selection: AuthenticationType
    
    var body: some View {
        HStack(spacing: 0) {
            authOption(type: .password, icon: "lock.fill", label: "Password")
            authOption(type: .privateKey, icon: "key.fill", label: "Private Key")
        }
        .background(Color.axBackgroundTertiary)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }
    
    private func authOption(type: AuthenticationType, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selection = type
            }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selection == type ? .white : .axTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(
                Group {
                    if selection == type {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentBlue)
                            .padding(3)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Progress View

struct PremiumProgressView: View {
    let progress: ConnectionProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: stageIcon)
                    .font(.system(size: 12))
                    .foregroundColor(.axAccentBlue)
                
                Text(progress.message)
                    .font(.system(size: 13))
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Text("\(Int(progress.percentComplete * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axBackgroundTertiary)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.axAccentBlue, Color.axAccentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress.percentComplete, height: 4)
                        .animation(.spring(response: 0.3), value: progress.percentComplete)
                }
            }
            .frame(height: 4)
        }
        .padding(AXSpacing.md)
        .background(Color.axAccentBlue.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
    }
    
    private var stageIcon: String {
        switch progress.stage {
        case .requestingCAT:
            return "lock.shield.fill"
        case .decryptingCAT:
            return "lock.open.fill"
        case .validatingCAT:
            return "shield.checkered"
        case .authenticating:
            return "person.badge.key.fill"
        case .decrypting:
            return "key.horizontal.fill"
        case .verifyingHostKey:
            return "shield.checkered"
        case .establishingSSH:
            return "wifi"
        case .testing:
            return "bolt.fill"
        case .complete:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}

extension AddServerView {
    private func updateProgress() {
        var completedFields = 0
        let totalRequired = 5
        
        if !viewModel.name.isEmpty { completedFields += 1 }
        if !viewModel.host.isEmpty { completedFields += 1 }
        if !viewModel.username.isEmpty { completedFields += 1 }
        
        if viewModel.authType == .password {
            if !viewModel.password.isEmpty { completedFields += 1 }
        } else {
            if !viewModel.privateKey.isEmpty { completedFields += 1 }
        }
        
        // Count connectivity as the 5th step if verified
        if viewModel.testResult?.success == true {
            completedFields += 1
        }
        
        withAnimation(.spring()) {
            formProgress = CGFloat(completedFields) / CGFloat(totalRequired)
        }
    }
}

// MARK: - Premium Result View

struct PremiumResultView: View {
    let result: ConnectionTestResult
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(result.success ? Color.axSuccess.opacity(0.2) : Color.axError.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: result.success ? "checkmark" : "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(result.success ? .axSuccess : .axError)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(result.success ? "Connection Successful" : "Connection Failed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                
                Text(result.message)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Latency badge
            if let latency = result.latencyMs {
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", latency))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.axAccentGreen)
                    Text("ms")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axAccentGreen.opacity(0.15))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
        .padding(AXSpacing.md)
        .background(result.success ? Color.axSuccess.opacity(0.08) : Color.axError.opacity(0.08))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(result.success ? Color.axSuccess.opacity(0.3) : Color.axError.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - View Model

@MainActor
class AddServerViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case identity = 0
        case connection = 1
        case authentication = 2
        case verify = 3
        
        var title: String {
            switch self {
            case .identity: return "Identity"
            case .connection: return "Connection"
            case .authentication: return "Authentication"
            case .verify: return "Verify"
            }
        }
    }
    
    @Published var currentStep: Step = .identity
    @Published var name = ""
    @Published var host = ""
    @Published var port = 22
    @Published var username = ""
    @Published var authType: AuthenticationType = .password
    @Published var password = ""
    @Published var privateKey = ""
    @Published var keyPassphrase = ""
    @Published var tagsText = ""
    @Published var notes = ""
    
    // Icon and Color selection (from AevonXCore)
    @Published var selectedIcon: ServerIcon = .serverRack
    @Published var selectedColor: ServerColor = .blue
    
    @Published var isTesting = false
    @Published var testResult: ConnectionTestResult?
    @Published var connectionProgress: ConnectionProgress?
    
    @Published var showError = false
    @Published var errorMessage: String?
    
    var isFirstStep: Bool { currentStep == .identity }
    var isLastStep: Bool { currentStep == .verify }
    
    func nextStep() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring()) {
                currentStep = next
            }
        }
    }
    
    func prevStep() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring()) {
                currentStep = prev
            }
        }
    }
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .identity:
            return !name.isEmpty
        case .connection:
            return !host.isEmpty && !username.isEmpty
        case .authentication:
            return authType == .password ? !password.isEmpty : !privateKey.isEmpty
        case .verify:
            return true
        }
    }
    
    var isValid: Bool {
        !name.isEmpty &&
        !host.isEmpty &&
        !username.isEmpty &&
        (authType == .password ? !password.isEmpty : !privateKey.isEmpty)
    }
    
    var canTest: Bool {
        !host.isEmpty && !username.isEmpty &&
        (authType == .password ? !password.isEmpty : !privateKey.isEmpty)
    }
    
    func buildRequest() -> AddServerRequest? {
        guard isValid else { return nil }
        
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return AddServerRequest(
            name: name,
            host: host,
            port: port,
            username: username,
            authType: authType,
            password: authType == .password ? password : nil,
            privateKey: authType == .privateKey ? privateKey : nil,
            keyPassphrase: authType == .privateKey && !keyPassphrase.isEmpty ? keyPassphrase : nil,
            tags: tags,
            notes: notes.isEmpty ? nil : notes,
            iconName: selectedIcon.rawValue,
            customColor: selectedColor.rawValue
        )
    }
    
    func testConnection() async {
        isTesting = true
        testResult = nil
        connectionProgress = nil
        
        defer { isTesting = false }
        
        guard let request = buildRequest() else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        do {
            let serverData = request.toEncryptedServerData()
            
            try await BiometricAuthManager.shared.authenticateIfNeeded(
                reason: "Test connection to \(request.host)"
            )
            
            let encryptedPayload = try await SplitKeyEncryptionService.shared.encryptServer(serverData)
            
            let serverId = "test-\(UUID().uuidString)"
            await SSHService.shared.setProgressHandler(for: serverId) { [weak self] stage, progress in
                guard let self = self else { return }
                Task { @MainActor in
                    self.connectionProgress = ConnectionProgress(
                        stage: stage,
                        message: stage.rawValue,
                        percentComplete: progress
                    )
                }
            }
            
            let result = await SSHService.shared.testConnection(
                to: encryptedPayload,
                host: request.host,
                port: request.port,
                serverId: serverId
            )
            
            testResult = result
            
        } catch {
            errorMessage = "Connection test failed: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Legacy Components (kept for compatibility)


struct AXSecureField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    
    var body: some View {
        PremiumSecureField(title: title, text: $text, placeholder: placeholder)
    }
}

struct ConnectionResultView: View {
    let result: ConnectionTestResult
    
    var body: some View {
        PremiumResultView(result: result)
    }
}

struct ConnectionProgressView: View {
    let progress: ConnectionProgress
    
    var body: some View {
        PremiumProgressView(progress: progress)
    }
}

#Preview {
    AddServerView { _ in }
}
