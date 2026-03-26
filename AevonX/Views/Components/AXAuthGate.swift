//
//  AXAuthGate.swift
//  AevonX
//
//  ViewModifier for wrapping actions with biometric/password auth gate
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Auth Gate Modifier

struct AXAuthGateModifier: ViewModifier {
    @EnvironmentObject var settings: AppSettingsManager
    let settingKey: KeyPath<AppSettingsManager, Bool>
    let reason: String
    let onAuthenticated: () -> Void

    @State private var isAuthenticating = false

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                performGatedAction()
            }
    }

    private func performGatedAction() {
        let requireAuth = settings[keyPath: settingKey]
        guard requireAuth else {
            onAuthenticated()
            return
        }

        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            do {
                try await BiometricAuthManager.shared.authenticateIfNeeded(reason: reason)
                await MainActor.run {
                    onAuthenticated()
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Wraps a tap action with an auth gate that checks the given setting
    func authGated(
        setting: KeyPath<AppSettingsManager, Bool>,
        reason: String,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(AXAuthGateModifier(
            settingKey: setting,
            reason: reason,
            onAuthenticated: action
        ))
    }
}

// MARK: - Standalone Auth Gate Helper

/// Performs an action after biometric authentication if required
@MainActor
struct AuthGate {
    static func perform(
        settings: AppSettingsManager,
        check settingKey: KeyPath<AppSettingsManager, Bool>,
        reason: String,
        action: @escaping () -> Void
    ) {
        let requireAuth = settings[keyPath: settingKey]
        guard requireAuth else {
            action()
            return
        }

        Task {
            do {
                try await BiometricAuthManager.shared.authenticateIfNeeded(reason: reason)
                await MainActor.run { action() }
            } catch {
                // Auth failed or cancelled — do nothing
            }
        }
    }
}
