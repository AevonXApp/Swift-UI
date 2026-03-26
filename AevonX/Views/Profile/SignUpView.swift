//
//  SignUpView.swift
//  AevonX
//
//  Dedicated Sign Up page — premium 3-section registration form,
//  real-time username validation, password strength indicator.
//

import SwiftUI
import AevonXCoreBridge

struct SignUpView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    let onSwitchToLogin: () -> Void

    // Form fields
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var usernameStatus: UsernameStatus = .idle

    // Animations
    @State private var logoScale: CGFloat = 0.5
    @State private var cardOffset: CGFloat = 24
    @State private var cardOpacity: Double = 0

    enum UsernameStatus {
        case idle, checking, valid, invalid(String)
    }

    var body: some View {
        ZStack {
            backgroundView

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 30)

                    // Header — App Icon
                    headerView
                        .padding(.bottom, AXSpacing.lg)

                    // Registration Card
                    VStack(spacing: AXSpacing.lg) {
                        // Error
                        if let error = viewModel.errorMessage {
                            AuthBanner(message: error, type: .error)
                        }

                        // Progress Steps
                        stepIndicator

                        // ── Section 1: Identity ──
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            sectionTitle("IDENTITY")

                            AuthFormField(label: L10n.Field.fullName, icon: "person.fill", text: $name)

                            // Username with live validation
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text(L10n.Field.username)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)

                                HStack(spacing: AXSpacing.sm) {
                                    Image(systemName: "at")
                                        .font(.system(size: 13))
                                        .foregroundColor(.axTextSecondary)
                                        .frame(width: 16)

                                    TextField("", text: $username)
                                        .font(AXTypography.body)
                                        .foregroundColor(.axTextPrimary)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .onChange(of: username) { _, newValue in
                                            // Filter: only ASCII alphanumeric + underscore
                                            let filtered = String(newValue.unicodeScalars.filter { s in
                                                (s.value >= 0x30 && s.value <= 0x39) || // 0-9
                                                (s.value >= 0x41 && s.value <= 0x5A) || // A-Z
                                                (s.value >= 0x61 && s.value <= 0x7A) || // a-z
                                                s.value == 0x5F                          // _
                                            })
                                            if filtered != newValue { username = filtered; return }
                                            validateUsername(filtered)
                                        }

                                    usernameStatusIcon
                                }
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm + 2)
                                .background(Color.axBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(usernameBorderColor, lineWidth: 1)
                                )
                                .cornerRadius(AXCornerRadius.md)

                                if case .invalid(let msg) = usernameStatus {
                                    Text(msg)
                                        .font(.system(size: 10))
                                        .foregroundColor(.axError)
                                        .transition(.opacity)
                                }
                            }
                        }

                        sectionDivider

                        // ── Section 2: Contact ──
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            sectionTitle("CONTACT")
                            AuthFormField(label: "Email Address", icon: "envelope.fill", text: $email, asciiOnly: true)
                        }

                        sectionDivider

                        // ── Section 3: Security ──
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            sectionTitle("SECURITY")

                            AuthFormField(label: L10n.Field.password, icon: "lock.fill", text: $password, isSecure: true, asciiOnly: true)
                            AuthFormField(label: "Confirm Password", icon: "lock.rotation", text: $confirmPassword, isSecure: true, asciiOnly: true)

                            if !password.isEmpty {
                                PasswordStrengthBar(password: password)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)

                        // Create Account Button
                        AuthPrimaryButton(
                            title: L10n.Auth.createAccount,
                            icon: "person.badge.plus",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.register(
                                    name: name,
                                    username: username,
                                    email: email,
                                    password: password,
                                    passwordConfirmation: confirmPassword
                                )
                            }
                        }

                        // Switch to Sign In
                        Button(L10n.Auth.hasAccountSignIn) {
                            onSwitchToLogin()
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isLoading)
                    }
                    .padding(AXSpacing.xl)
                    .background(AuthCardBackground())
                    .frame(maxWidth: 420)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)

                    Spacer(minLength: 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { logoScale = 1.0 }
            withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                cardOffset = 0
                cardOpacity = 1.0
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color.axBackground.ignoresSafeArea()
            RadialGradient(
                colors: [Color.axAccentBlue.opacity(0.06), Color.clear],
                center: .top, startRadius: 100, endRadius: 500
            ).ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.axAccentBlue.opacity(0.35), radius: 20, y: 8)
                .scaleEffect(logoScale)

            Text(L10n.App.name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)

            Text(L10n.Auth.createAccount)
                .font(AXTypography.callout)
                .foregroundColor(.axTextSecondary)
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: AXSpacing.xs) {
            stepDot(filled: !name.isEmpty || !username.isEmpty, label: "1")
            stepLine
            stepDot(filled: !email.isEmpty, label: "2")
            stepLine
            stepDot(filled: !password.isEmpty && !confirmPassword.isEmpty, label: "3")
        }
    }

    private func stepDot(filled: Bool, label: String) -> some View {
        ZStack {
            Circle()
                .fill(filled ? Color.axAccentBlue : Color.axBorder.opacity(0.3))
                .frame(width: 24, height: 24)

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(filled ? .white : .axTextSecondary)
        }
        .animation(.easeInOut(duration: 0.3), value: filled)
    }

    private var stepLine: some View {
        Rectangle()
            .fill(Color.axBorder.opacity(0.2))
            .frame(height: 1)
    }

    // MARK: - Section Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.axTextSecondary)
            .tracking(1.2)
    }

    private var sectionDivider: some View {
        Divider()
            .background(Color.axBorder.opacity(0.2))
    }

    // MARK: - Username Validation

    @ViewBuilder
    private var usernameStatusIcon: some View {
        switch usernameStatus {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView().scaleEffect(0.6)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.axSuccess)
                .font(.system(size: 14))
                .transition(.scale.combined(with: .opacity))
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.axError)
                .font(.system(size: 14))
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var usernameBorderColor: Color {
        switch usernameStatus {
        case .valid: return .axSuccess.opacity(0.5)
        case .invalid: return .axError.opacity(0.5)
        default: return .axBorder
        }
    }

    private func validateUsername(_ value: String) {
        guard !value.isEmpty else {
            withAnimation { usernameStatus = .idle }
            return
        }
        withAnimation { usernameStatus = .checking }

        let result = APIBridge.shared.validateUsername(value)
        if let data = result.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let inner = json["data"] as? [String: Any] {
            let isValid = inner["valid"] as? Bool ?? false
            let error = inner["error"] as? String ?? ""
            withAnimation(.easeInOut(duration: 0.2)) {
                usernameStatus = isValid ? .valid : .invalid(error)
            }
        } else {
            withAnimation { usernameStatus = .idle }
        }
    }
}

// MARK: - Password Strength Bar

struct PasswordStrengthBar: View {
    let password: String

    private static let allowedSymbols = CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:,.<>?/~`")

    // Each requirement maps to Go Core validatePasswordStrength
    private var hasUppercase: Bool { password.unicodeScalars.contains { $0.value >= 0x41 && $0.value <= 0x5A } }
    private var hasLowercase: Bool { password.unicodeScalars.contains { $0.value >= 0x61 && $0.value <= 0x7A } }
    private var hasDigit: Bool { password.unicodeScalars.contains { $0.value >= 0x30 && $0.value <= 0x39 } }
    private var hasSymbol: Bool { password.unicodeScalars.contains { Self.allowedSymbols.contains($0) } }
    private var hasMinLength: Bool { password.count >= 8 }
    private var isASCIIOnly: Bool {
        password.unicodeScalars.allSatisfy { scalar in
            (scalar.value >= 0x21 && scalar.value <= 0x7E) // printable ASCII only
        }
    }

    private var passedCount: Int {
        [hasUppercase, hasLowercase, hasDigit, hasSymbol, hasMinLength, isASCIIOnly].filter { $0 }.count
    }

    private var strengthColor: Color {
        switch passedCount {
        case 0...2: return .axError
        case 3...4: return .axWarning
        case 5: return .axSuccess.opacity(0.8)
        default: return .axSuccess
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axBorder.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(strengthColor)
                        .frame(width: geo.size.width * CGFloat(passedCount) / 6.0)
                        .animation(.easeInOut(duration: 0.3), value: passedCount)
                }
            }
            .frame(height: 3)

            // Requirements checklist
            VStack(alignment: .leading, spacing: 2) {
                requirementRow("At least 8 characters", met: hasMinLength)
                requirementRow("Uppercase letter (A-Z)", met: hasUppercase)
                requirementRow("Lowercase letter (a-z)", met: hasLowercase)
                requirementRow("Number (0-9)", met: hasDigit)
                requirementRow("Symbol (!@#$%^&*...)", met: hasSymbol)
                if !isASCIIOnly {
                    requirementRow("English characters only", met: false)
                }
            }
        }
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 9))
                .foregroundColor(met ? .axSuccess : .axTextSecondary.opacity(0.5))
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(met ? .axSuccess : .axTextSecondary.opacity(0.7))
        }
    }
}
