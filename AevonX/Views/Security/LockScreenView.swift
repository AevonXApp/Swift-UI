//
//  LockScreenView.swift
//  AevonX
//
//  Full-screen app lock with biometric and password authentication
//

import SwiftUI
import AevonXCoreBridge

struct LockScreenView: View {
    @EnvironmentObject var settings: AppSettingsManager
    @State private var passwordInput: String = ""
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPasswordField = false

    var body: some View {
        ZStack {
            Color.axBackground
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: AXSpacing.xxxl) {
                Spacer()

                lockIcon

                appBranding

                if showPasswordField {
                    passwordSection
                } else {
                    biometricSection
                }

                if showError {
                    errorBanner
                }

                attemptsIndicator

                Spacer()
                Spacer()
            }
            .frame(maxWidth: 360)
        }
        .onAppear {
            attemptBiometricAuth()
        }
    }

    // MARK: - Sub Views

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(Color.axAccentBlue.opacity(0.1))
                .frame(width: 100, height: 100)

            Circle()
                .fill(Color.axAccentBlue.opacity(0.05))
                .frame(width: 80, height: 80)

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundColor(.axAccentBlue)
        }
    }

    private var appBranding: some View {
        VStack(spacing: AXSpacing.sm) {
            Text(L10n.App.name)
                .font(AXTypography.title)
                .foregroundColor(.axTextPrimary)

            Text(L10n.Security.authRequired)
                .font(AXTypography.callout)
                .foregroundColor(.axTextSecondary)
        }
    }

    private var biometricSection: some View {
        VStack(spacing: AXSpacing.lg) {
            if isAuthenticating {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.axAccentBlue)
            } else {
                Button(action: attemptBiometricAuth) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "touchid")
                            .font(.system(size: 18))
                        Text(L10n.Security.unlockBiometrics)
                            .font(AXTypography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }

            Button(action: { showPasswordField = true }) {
                Text(L10n.Security.usePassword)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.xl)
    }

    private var passwordSection: some View {
        VStack(spacing: AXSpacing.lg) {
            SecureField("Enter password", text: $passwordInput)
                .textFieldStyle(.plain)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .onSubmit { attemptPasswordAuth() }

            Button(action: attemptPasswordAuth) {
                Text(L10n.Security.unlock)
                    .font(AXTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(passwordInput.isEmpty ? Color.axTextMuted : Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(passwordInput.isEmpty)

            Button(action: {
                showPasswordField = false
                passwordInput = ""
            }) {
                Text(L10n.Security.useBiometrics)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.xl)
    }

    private var errorBanner: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.axError)

            Text(errorMessage)
                .font(AXTypography.caption)
                .foregroundColor(.axError)
        }
        .padding(AXSpacing.md)
        .background(Color.axError.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
        .padding(.horizontal, AXSpacing.xl)
    }

    private var attemptsIndicator: some View {
        Group {
            if settings.failedAttempts > 0 {
                Text(L10n.Security.attemptsUsed(settings.failedAttempts, settings.maxFailedAttempts))
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
        }
    }

    // MARK: - Auth Actions

    private func attemptBiometricAuth() {
        guard settings.appLockMethod == "biometric" || !showPasswordField else { return }
        isAuthenticating = true
        showError = false

        Task {
            do {
                try await BiometricAuthManager.shared.authenticate(reason: "Unlock AevonX")
                settings.unlock()
            } catch {
                settings.recordFailedAttempt()
                errorMessage = "Authentication failed. Please try again."
                showError = true

                if settings.failedAttempts >= settings.maxFailedAttempts {
                    showPasswordField = true
                }
            }
            isAuthenticating = false
        }
    }

    private func attemptPasswordAuth() {
        isAuthenticating = true
        showError = false

        Task {
            let valid = await LockPasswordService.shared.verify(passwordInput)
            if valid {
                settings.unlock()
                passwordInput = ""
            } else {
                settings.recordFailedAttempt()
                errorMessage = "Invalid password. \(settings.maxFailedAttempts - settings.failedAttempts) attempts remaining."
                showError = true
                passwordInput = ""
            }
            isAuthenticating = false
        }
    }
}
