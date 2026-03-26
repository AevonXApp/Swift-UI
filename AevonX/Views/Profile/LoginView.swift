//
//  LoginView.swift
//  AevonX
//
//  Sign In page — app icon, glassmorphism card,
//  email/username login, forgot password flow.
//  Navigates to SignUpView for registration.
//

import SwiftUI
import AevonXCoreBridge

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var showSignUp = false

    var body: some View {
        if showSignUp {
            SignUpView(onSwitchToLogin: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSignUp = false
                    viewModel.errorMessage = nil
                }
            })
            .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            SignInContent(onSwitchToSignUp: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSignUp = true
                    viewModel.errorMessage = nil
                }
            })
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }
}

// MARK: - Sign In Content (embedded in LoginView)

private struct SignInContent: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    let onSwitchToSignUp: () -> Void

    @State private var loginField = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var forgotEmail = ""
    @State private var forgotSuccess: String?

    @State private var logoScale: CGFloat = 0.5
    @State private var cardOffset: CGFloat = 24
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            ZStack {
                Color.axBackground.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.axAccentBlue.opacity(0.06), Color.clear],
                    center: .top, startRadius: 100, endRadius: 500
                ).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                // Header
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

                    Text(showForgotPassword ? "Reset your password" : "Sign in to your account")
                        .font(AXTypography.callout)
                        .foregroundColor(.axTextSecondary)
                }
                .padding(.bottom, AXSpacing.xl)

                // Card
                VStack(spacing: AXSpacing.lg) {
                    if let error = viewModel.errorMessage {
                        AuthBanner(message: error, type: .error)
                    }

                    if let msg = forgotSuccess {
                        AuthBanner(message: msg, type: .success)
                    }

                    if showForgotPassword {
                        AuthFormField(label: "Email Address", icon: "envelope.fill", text: $forgotEmail, asciiOnly: true)

                        Text(L10n.Auth.resetPasswordInfo)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .multilineTextAlignment(.center)

                        AuthPrimaryButton(title: L10n.Auth.sendResetLink, icon: "paperplane.fill", isLoading: viewModel.isLoading) {
                            Task {
                                await viewModel.forgotPassword(email: forgotEmail)
                                if viewModel.errorMessage == nil {
                                    forgotSuccess = "Reset link sent to your email."
                                }
                            }
                        }

                        Button(L10n.Auth.backToSignIn) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showForgotPassword = false
                                viewModel.errorMessage = nil
                                forgotSuccess = nil
                            }
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                        .buttonStyle(PlainButtonStyle())

                    } else {
                        AuthFormField(label: "Email or Username", icon: "person.fill", text: $loginField, asciiOnly: true)
                        AuthFormField(label: "Password", icon: "lock.fill", text: $password, isSecure: true, asciiOnly: true)

                        AuthPrimaryButton(title: L10n.Auth.signIn, icon: "arrow.right", isLoading: viewModel.isLoading) {
                            Task {
                                await viewModel.login(login: loginField, password: password)
                            }
                        }

                        HStack {
                            Button(L10n.Auth.forgotPassword) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showForgotPassword = true
                                    viewModel.errorMessage = nil
                                }
                            }
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            Button(L10n.Auth.noAccountSignUp) {
                                onSwitchToSignUp()
                            }
                            .font(AXTypography.caption)
                            .foregroundColor(.axAccentBlue)
                            .buttonStyle(PlainButtonStyle())
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(AXSpacing.xl)
                .background(AuthCardBackground())
                .frame(maxWidth: 380)
                .offset(y: cardOffset)
                .opacity(cardOpacity)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { logoScale = 1.0 }
            withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                cardOffset = 0
                cardOpacity = 1.0
            }
        }
    }
}

// MARK: - Shared Auth Components

struct AuthFormField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var asciiOnly: Bool = false

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 16)

                if isSecure && !showPassword {
                    SecureField("", text: $text)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(PlainTextFieldStyle())
                } else {
                    TextField("", text: $text)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(PlainTextFieldStyle())
                }

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.axTextSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm + 2)
            .background(Color.axBackground.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.md)
        }
        .onChange(of: text) { _, newValue in
            if asciiOnly {
                let filtered = String(newValue.unicodeScalars.filter { $0.value >= 0x21 && $0.value <= 0x7E })
                if filtered != newValue { text = filtered }
            }
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: AXSpacing.sm) {
                        Text(title).fontWeight(.semibold)
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
            .font(AXTypography.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(
                LinearGradient(
                    colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(AXCornerRadius.md)
            .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

struct AuthCardBackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.xl).fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: AXCornerRadius.xl).fill(Color.axSurface.opacity(0.55))
            RoundedRectangle(cornerRadius: AXCornerRadius.xl).stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        }
    }
}

struct AuthBanner: View {
    let message: String
    let type: BannerType

    enum BannerType {
        case error, success
        var icon: String {
            switch self { case .error: return "exclamationmark.triangle.fill"; case .success: return "checkmark.circle.fill" }
        }
        var color: Color {
            switch self { case .error: return .axError; case .success: return .axSuccess }
        }
    }

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: type.icon).foregroundColor(type.color).font(.system(size: 13))
            Text(message).font(AXTypography.caption).foregroundColor(type.color).lineLimit(3)
            Spacer()
        }
        .padding(AXSpacing.md)
        .background(type.color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(type.color.opacity(0.2), lineWidth: 1))
        .cornerRadius(AXCornerRadius.md)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct TrialStatusBanner: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        Group {
            switch viewModel.trialStatus {
            case .eligible:
                trialRow(icon: "gift.fill", color: .axSuccess, title: "Free Trial Available", subtitle: "Start your free trial today")
            case .used:
                trialRow(icon: "exclamationmark.circle.fill", color: .axWarning, title: "Trial Not Available", subtitle: "This device has already been used for a trial")
            case .unknown:
                HStack(spacing: AXSpacing.sm) {
                    ProgressView().scaleEffect(0.7)
                    Text(L10n.Auth.checkingTrial).font(AXTypography.caption).foregroundColor(.axTextSecondary)
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
            @unknown default: EmptyView()
            }
        }
    }

    private func trialRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AXTypography.subheadline).fontWeight(.semibold).foregroundColor(color)
                Text(subtitle).font(AXTypography.caption).foregroundColor(.axTextSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.2), lineWidth: 1))
        .cornerRadius(AXCornerRadius.md)
    }
}

#Preview {
    LoginView()
        .background(Color.axBackground)
}
