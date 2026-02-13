//
//  AddServerComponents.swift
//  AevonX
//

import SwiftUI
import AevonXCore

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
        case .requestingCAT: return "lock.shield.fill"
        case .decryptingCAT: return "lock.open.fill"
        case .validatingCAT: return "shield.checkered"
        case .authenticating: return "person.badge.key.fill"
        case .decrypting: return "key.horizontal.fill"
        case .verifyingHostKey: return "shield.checkered"
        case .establishingSSH: return "wifi"
        case .testing: return "bolt.fill"
        case .complete: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
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
