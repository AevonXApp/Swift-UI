//
//  SecuritySettingsSection.swift
//  AevonX
//
//  Security settings: app lock, server protection, session
//

import SwiftUI

struct SecuritySettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    @State private var showPasswordSheet = false
    @State private var showClearAllConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Security",
                description: "Authentication & app protection",
                icon: "lock.shield.fill",
                iconColor: .axError
            )

            appLockSection
            serverProtectionSection
            sessionSection
            advancedSection
        }
        .sheet(isPresented: $showPasswordSheet) {
            ChangeLockPasswordSheet()
        }
    }

    // MARK: - Sections

    private var appLockSection: some View {
        SettingsSection(title: "App Lock", icon: "lock.fill") {
            SettingsToggleRow(
                title: "Enable App Lock",
                subtitle: "Require authentication to open AevonX",
                isOn: $settings.appLockEnabled,
                tint: .axAccentGreen
            )

            if settings.appLockEnabled {
                SettingsSegmentedRow(
                    title: "Lock Method",
                    selection: $settings.appLockMethod,
                    options: [
                        (label: "Biometric", value: "biometric"),
                        (label: "Password", value: "password")
                    ]
                )

                SettingsPickerRow(
                    title: "Auto-lock Timeout",
                    subtitle: "Lock after period of inactivity",
                    selection: $settings.autoLockTimeout,
                    options: [
                        (label: "1 minute", value: 1),
                        (label: "5 minutes", value: 5),
                        (label: "15 minutes", value: 15),
                        (label: "30 minutes", value: 30),
                        (label: "1 hour", value: 60),
                        (label: "Never", value: 0)
                    ]
                )

                SettingsToggleRow(
                    title: "Lock on Sleep",
                    subtitle: "Lock app when your Mac sleeps",
                    isOn: $settings.lockOnSleep
                )

                SettingsToggleRow(
                    title: "Lock on Minimize",
                    subtitle: "Lock app when window is minimized",
                    isOn: $settings.lockOnMinimize
                )
            }
        }
    }

    private var serverProtectionSection: some View {
        SettingsSection(title: "Server Protection", icon: "shield.lefthalf.filled") {
            SettingsToggleRow(
                title: "Require Auth on Connect",
                subtitle: "Authenticate before connecting to a server",
                isOn: $settings.requireAuthOnConnect
            )
            SettingsToggleRow(
                title: "Require Auth on Edit",
                subtitle: "Authenticate before editing server credentials",
                isOn: $settings.requireAuthOnEdit
            )
            SettingsToggleRow(
                title: "Require Auth on Delete",
                subtitle: "Authenticate before deleting a server",
                isOn: $settings.requireAuthOnDelete
            )
        }
    }

    private var sessionSection: some View {
        SettingsSection(title: "Session", icon: "clock") {
            SettingsStepperRow(
                title: "Max Failed Attempts",
                subtitle: "Lock out after this many failures",
                value: $settings.maxFailedAttempts,
                range: 3...10
            )
            SettingsToggleRow(
                title: "Clear Clipboard on Exit",
                subtitle: "Remove copied passwords when app closes",
                isOn: $settings.clearClipboardOnExit
            )
        }
    }

    private var advancedSection: some View {
        SettingsSection(title: "Advanced", icon: "exclamationmark.shield") {
            SettingsButtonRow(
                title: "Change Lock Password",
                subtitle: "Set a new password for app lock",
                icon: "key",
                action: { showPasswordSheet = true }
            )
            SettingsButtonRow(
                title: "Clear All Data",
                subtitle: "Remove all stored credentials and history",
                icon: "trash",
                buttonLabel: "Clear...",
                isDestructive: true,
                action: { showClearAllConfirmation = true }
            )
        }
        .overlay {
            if showClearAllConfirmation {
                AXDeleteConfirmation(
                    title: "Clear All Data?",
                    itemName: "All App Data",
                    icon: "trash.fill",
                    warning: "This will remove all stored credentials, server configurations, and settings. This action cannot be undone.",
                    onConfirm: {
                        clearAllData()
                        showClearAllConfirmation = false
                    },
                    onCancel: { showClearAllConfirmation = false }
                )
            }
        }
    }

    // MARK: - Actions

    private func clearAllData() {
        // Reset all settings
        settings.resetToDefaults()

        // Remove lock password from Keychain
        Task {
            await LockPasswordService.shared.removePassword()
        }

        // Clear all UserDefaults (including non-settings keys)
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
    }
}

// MARK: - Change Password Sheet

private struct ChangeLockPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var hasExistingPassword = false
    @State private var isSaving = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            sheetContent
            sheetFooter
        }
        .frame(width: 400, height: hasExistingPassword ? 340 : 280)
        .background(Color.axBackground)
        .task {
            hasExistingPassword = await LockPasswordService.shared.hasPassword()
        }
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(hasExistingPassword ? "Change Lock Password" : "Set Lock Password")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text("Password is stored securely in your Keychain")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private var sheetContent: some View {
        VStack(spacing: AXSpacing.lg) {
            if hasExistingPassword {
                SecureField("Current password", text: $currentPassword)
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
            }

            SecureField("New password", text: $newPassword)
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

            SecureField("Confirm new password", text: $confirmPassword)
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

            if !errorMessage.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                    Text(errorMessage)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                }
            }

            if showSuccess {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentGreen)
                    Text("Password saved successfully")
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentGreen)
                }
            }
        }
        .padding(.horizontal, AXSpacing.xl)
    }

    private var sheetFooter: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.axTextSecondary)

            Button(action: savePassword) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 60)
                } else {
                    Text("Save")
                        .frame(width: 60)
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
            .padding(.vertical, AXSpacing.sm)
            .padding(.horizontal, AXSpacing.lg)
            .background(canSave ? Color.axAccentBlue : Color.axTextMuted)
            .cornerRadius(AXCornerRadius.md)
            .disabled(!canSave || isSaving)
        }
        .padding(AXSpacing.xl)
    }

    private var canSave: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 4
    }

    private func savePassword() {
        errorMessage = ""

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }

        guard newPassword.count >= 4 else {
            errorMessage = "Password must be at least 4 characters"
            return
        }

        isSaving = true

        Task {
            if hasExistingPassword {
                let valid = await LockPasswordService.shared.verify(currentPassword)
                guard valid else {
                    errorMessage = "Current password is incorrect"
                    isSaving = false
                    return
                }
            }

            do {
                try await LockPasswordService.shared.setPassword(newPassword)
                showSuccess = true
                isSaving = false
                try? await Task.sleep(for: .seconds(1))
                dismiss()
            } catch {
                errorMessage = "Failed to save password"
                isSaving = false
            }
        }
    }
}
