//
//  AXDesignSystem.swift
//  AevonX
//
//  Premium Design System Components
//  Glassmorphism, animations, and unified styling
//

import SwiftUI

// MARK: - Glass Card

/// Premium glassmorphic card with subtle blur and gradient border
public struct AXGlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AXSpacing.lg
    var cornerRadius: CGFloat = AXCornerRadius.xl
    var showBorder: Bool = true
    var accentColor: Color = .axAccentBlue
    
    @State private var isHovered = false
    
    public init(
        padding: CGFloat = AXSpacing.lg,
        cornerRadius: CGFloat = AXCornerRadius.xl,
        showBorder: Bool = true,
        accentColor: Color = .axAccentBlue,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.accentColor = accentColor
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.axGlassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: isHovered 
                                ? [accentColor.opacity(0.5), Color.axAccentGreen.opacity(0.3)]
                                : [Color.axGlassBorder, Color.axBorder],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 1.5 : 1
                    )
            )
            .shadow(color: isHovered ? accentColor.opacity(0.15) : .clear, radius: 20, y: 8)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Status Badge with Glow

public struct AXStatusBadge: View {
    public enum Status {
        case online, offline, warning, loading
        
        var color: Color {
            switch self {
            case .online: return .axSuccess
            case .offline: return .axTextMuted
            case .warning: return .axWarning
            case .loading: return .axAccentBlue
            }
        }
        
        var label: String {
            switch self {
            case .online: return "Online"
            case .offline: return "Offline"
            case .warning: return "Warning"
            case .loading: return "Loading"
            }
        }
    }
    
    let status: Status
    var showLabel: Bool = true
    var size: CGFloat = 8
    var enablePulseAnimation: Bool = false // Disabled by default to save CPU
    
    @State private var isPulsing = false
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        HStack(spacing: AXSpacing.xs) {
            ZStack {
                // Outer glow - only animate when enabled and visible
                Circle()
                    .fill(status.color.opacity(0.3))
                    .frame(width: size * 2, height: size * 2)
                    .blur(radius: 4)
                    .opacity(status == .online ? (isPulsing && enablePulseAnimation ? 0.5 : 1.0) : 0)
                
                // Inner dot
                Circle()
                    .fill(status.color)
                    .frame(width: size, height: size)
                    .shadow(color: status.color.opacity(0.5), radius: 3)
            }
            .frame(width: size * 2, height: size * 2)
            
            if showLabel {
                Text(status.label)
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(status.color)
            }
        }
        .onAppear {
            startPulseIfNeeded()
        }
        .onDisappear {
            isPulsing = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                startPulseIfNeeded()
            } else {
                isPulsing = false
            }
        }
    }
    
    private func startPulseIfNeeded() {
        guard enablePulseAnimation, status == .online else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

// MARK: - Circular Progress

public struct AXCircularProgress<Content: View>: View {
    let value: Double // 0.0 - 1.0
    var size: CGFloat = 32
    var lineWidth: CGFloat = 3
    var color: Color = .axAccentBlue
    var showValue: Bool = true
    let content: Content?

    public init(value: Double, size: CGFloat = 32, lineWidth: CGFloat = 3, color: Color = .axAccentBlue, showValue: Bool = true) where Content == Never {
        self.value = value
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
        self.showValue = showValue
        self.content = nil
    }

    public init(progress: Double, color: Color = .axAccentBlue, size: CGFloat = 32, lineWidth: CGFloat = 3, @ViewBuilder content: () -> Content) {
        self.value = progress
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
        self.showValue = false
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.axBorder, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(value, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5), value: value)

            // Value text or custom content
            if let content {
                content
            } else if showValue {
                Text("\(Int(value * 100))")
                    .font(.system(size: size * 0.3, weight: .semibold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Text Field

public struct AXTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var icon: String? = nil
    var accentColor: Color = .axAccentBlue
    var validation: ((String) -> Bool)? = nil
    
    @State private var isFocused = false
    @FocusState private var fieldFocused: Bool
    
    private var isValid: Bool {
        guard let validation = validation else { return true }
        return text.isEmpty || validation(text)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isFocused ? accentColor : .axTextMuted)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                
                ZStack(alignment: .leading) {
                    // Floating label
                    Text(placeholder)
                        .font(isFocused || !text.isEmpty ? AXTypography.caption : AXTypography.body)
                        .foregroundColor(isFocused ? accentColor : .axTextMuted)
                        .offset(y: isFocused || !text.isEmpty ? -20 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused || !text.isEmpty)
                    
                    // Text field
                    Group {
                        if isSecure {
                            SecureField("", text: $text)
                        } else {
                            TextField("", text: $text)
                        }
                    }
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                    .focused($fieldFocused)
                    .onChange(of: fieldFocused) { _, newValue in
                        withAnimation { isFocused = newValue }
                    }
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(
                        isFocused ? accentColor :
                        (!isValid ? Color.axError : Color.axBorder),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Validation error
            if !isValid && !text.isEmpty {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10))
                    Text(L10n.Shared.invalidInput)
                        .font(AXTypography.caption2)
                }
                .foregroundColor(.axError)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Primary Button

public struct AXPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .primary
    
    public enum ButtonStyle {
        case primary, secondary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .axAccentBlue
            case .secondary: return .axSurface
            case .destructive: return .axError
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .axBackground
            case .secondary: return .axTextPrimary
            case .destructive: return .white
            }
        }
    }
        @State private var isPressed = false
    
    public var accentColor: Color = .axAccentBlue
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isDisabled ? .axTextMuted : style.foregroundColor)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isDisabled ? Color.axBackgroundTertiary : (style == .primary ? accentColor : style.backgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(style == .secondary ? Color.axBorder : .clear, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: style == .primary ? accentColor.opacity(0.3) : .clear, radius: isPressed ? 0 : 8, y: isPressed ? 0 : 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = pressing
            }
        }) {}
    }
}

// MARK: - Section Header

public struct AXSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    var accentColor: Color = .axAccentBlue
    
    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(title)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    HStack(spacing: AXSpacing.xxs) {
                        Text(actionLabel)
                        Image(systemName: "chevron.right")
                    }
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Empty State

public struct AXEmptyState: View {
    let icon: String
    let title: String
    let description: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    var accentColor: Color = .axAccentBlue
    
    public var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.15), Color.axAccentGreen.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, .axAccentGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: AXSpacing.sm) {
                Text(title)
                    .font(AXTypography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                
                Text(description)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            if let actionLabel = actionLabel, let action = action {
                AXPrimaryButton(title: actionLabel, icon: "plus", action: action, accentColor: accentColor)
            }
        }
        .padding(AXSpacing.xxxl)
    }
}

// MARK: - Mini Stat Card

public struct AXMiniStat: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .axAccentBlue
    var trend: Double? = nil // positive = up, negative = down
    
    public var body: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                
                HStack(spacing: AXSpacing.xxxs) {
                    Text(label)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                    
                    if let trend = trend {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(trend >= 0 ? .axSuccess : .axError)
                    }
                }
            }
        }
    }
}

// MARK: - Button & TextField Styles

public struct AXPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AXTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.axBackground)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue)
            .cornerRadius(AXCornerRadius.md)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

public struct AXSecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AXTypography.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.axTextPrimary)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

public struct AXHeaderButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AXTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.axAccentBlue)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axAccentBlue.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
    }
}

public struct AXOutlineButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AXTypography.caption)
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
    }
}

public struct AXTextFieldStyle: TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AXSpacing.sm)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
    }
}
