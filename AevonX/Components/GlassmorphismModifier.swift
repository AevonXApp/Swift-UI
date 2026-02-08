//
//  GlassmorphismModifier.swift
//  AevonX
//
//  Glassmorphism effect modifier for sidebar and cards with hover states
//

import SwiftUI
import Combine

// MARK: - Glassmorphism Modifier
struct GlassmorphismModifier: ViewModifier {
    var blurRadius: CGFloat = 20
    var backgroundOpacity: Double = 0.75
    var borderOpacity: Double = 0.08
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.black.opacity(backgroundOpacity)
                    
                    // Gradient overlay for depth
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassmorphism(
        blurRadius: CGFloat = 20,
        backgroundOpacity: Double = 0.75,
        borderOpacity: Double = 0.08,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(GlassmorphismModifier(
            blurRadius: blurRadius,
            backgroundOpacity: backgroundOpacity,
            borderOpacity: borderOpacity,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Card Component with Hover State
struct AXCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12
    var accentColor: Color = Color(hex: "#00D4FF")
    
    @State private var isHovered = false
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 12, accentColor: Color = Color(hex: "#00D4FF"), @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "#1E1E1E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(hex: "#27272A"), lineWidth: 1)
                    )
                    .shadow(
                        color: isHovered ? accentColor.opacity(0.05) : Color.clear,
                        radius: isHovered ? 8 : 0,
                        x: 0,
                        y: isHovered ? 2 : 0
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: ServerStatus
    var showLabel: Bool = true
    var size: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: size, height: size)
                .shadow(color: statusColor.opacity(0.5), radius: size/2, x: 0, y: 0)
            
            if showLabel {
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(Color(hex: "#A1A1AA"))
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .online: return Color(hex: "#22C55E")
        case .offline: return Color(hex: "#52525B")
        case .maintenance: return Color(hex: "#F59E0B")
        case .error: return Color(hex: "#EF4444")
        }
    }
}

// MARK: - Animated Counter
struct AnimatedCounter: View {
    let value: Double
    var suffix: String = "%"
    var font: Font = .system(size: 18, weight: .semibold, design: .rounded)
    var color: Color = Color(hex: "#FAFAFA")
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text("\(Int(displayValue))\(suffix)")
            .font(font)
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Hoverable Button Style
struct HoverableButtonStyle: ButtonStyle {
    @State private var isHovered = false
    var backgroundColor: Color = Color(hex: "#1E1E1E")
    var hoverColor: Color = Color(hex: "#2A2A2A")
    var cornerRadius: CGFloat = 8
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? hoverColor : backgroundColor)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Interactive Row Style
struct InteractiveRowModifier: ViewModifier {
    var isSelected: Bool = false
    var cornerRadius: CGFloat = 12
    var accentColor: Color = Color(hex: "#00D4FF")
    
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? accentColor.opacity(0.08) : (isHovered ? Color(hex: "#2A2A2A").opacity(0.5) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(isSelected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    func interactiveRow(isSelected: Bool = false, cornerRadius: CGFloat = 12, accentColor: Color = Color(hex: "#00D4FF")) -> some View {
        modifier(InteractiveRowModifier(isSelected: isSelected, cornerRadius: cornerRadius, accentColor: accentColor))
    }
}
