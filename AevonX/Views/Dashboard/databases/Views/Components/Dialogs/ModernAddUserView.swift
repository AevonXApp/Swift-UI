//
//  ModernAddUserView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct ModernAddUserView: View {
    @Environment(\.dismiss) private var dismiss
    let accentColor: Color
    let onSave: (String, String, String) -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var host = "%"
    @State private var showPassword = false
    @State private var isSubmitting = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
            Divider()
            footer
        }
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }
    
    private var header: some View {
        HStack {
            Text(L10n.Database.addDatabaseUser)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }
    
    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Username
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text(L10n.Field.username)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    TextField(L10n.Field.username, text: $username)
                        .textFieldStyle(.plain)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                }
                
                // Password
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text(L10n.Field.password)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    HStack {
                        if showPassword {
                            TextField(L10n.Field.password, text: $password)
                        } else {
                            SecureField(L10n.Field.password, text: $password)
                        }
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.axTextSecondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            password = generatePassword()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                }
                
                // Host
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text(L10n.Field.host)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    TextField("%", text: $host)
                        .textFieldStyle(.plain)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                    Text(L10n.Database.useForAnyHostOrLocalhostForLocalAccessOnly)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(AXSpacing.xl)
        }
    }
    
    private var footer: some View {
        HStack {
            Button(L10n.Button.cancel) { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.axTextSecondary)
            Spacer()
            Button {
                isSubmitting = true
                onSave(username, password, host)
                dismiss()
            } label: {
                Text(L10n.Database.createUser)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .background(isFormValid ? accentColor : Color.axTextMuted)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isSubmitting)
        }
        .padding(AXSpacing.xl)
    }
    
    private var isFormValid: Bool {
        let validUsername = !username.isEmpty && username.range(of: #"^[a-zA-Z0-9_][a-zA-Z0-9_\-.]*$"#, options: .regularExpression) != nil
        let validPassword = password.count >= 8
        let validHost = !host.isEmpty
        return validUsername && validPassword && validHost
    }
    
    private func generatePassword() -> String {
        // Use only safe characters that won't break shell interpolation or SQL quoting.
        // Excludes: & ! $ ' " ` ( ) which cause shell metacharacter or SQL injection issues.
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#%^_+-="
        return String((0..<20).map { _ in chars.randomElement()! })
    }
}
