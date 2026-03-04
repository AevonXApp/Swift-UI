//
//  SkeletonLoadingView.swift
//  AevonX
//
//  Reusable shimmer loading components for first-load states.
//  Shows animated placeholder content instead of spinners.
//

import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + phase * geo.size.width * 3)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Text

struct SkeletonText: View {
    var width: CGFloat = 120
    var height: CGFloat = 12
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.axSurface.opacity(0.6))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Skeleton Row (for file lists, table rows)

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.axSurface.opacity(0.5))
                .frame(width: 28, height: 28)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 6) {
                SkeletonText(width: CGFloat.random(in: 80...180), height: 12)
                SkeletonText(width: CGFloat.random(in: 60...120), height: 10)
            }
            
            Spacer()
            
            // Right-side placeholder
            SkeletonText(width: 50, height: 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Skeleton Card (for overview stats)

struct SkeletonCard: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.axSurface.opacity(0.4))
                    .frame(width: 16, height: 16)
                SkeletonText(width: 60, height: 10)
                Spacer()
            }
            
            // Ring placeholder
            Circle()
                .stroke(Color.axSurface.opacity(0.3), lineWidth: 4)
                .frame(width: 56, height: 56)
                .shimmer()
            
            // Sparkline placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface.opacity(0.3))
                .frame(height: 24)
                .shimmer()
            
            // Detail text
            SkeletonText(width: 70, height: 8)
        }
        .padding(12)
        .background(Color.axBackgroundTertiary)
        .cornerRadius(AXCornerRadius.md)
    }
}

// MARK: - Skeleton File List

struct SkeletonFileList: View {
    var rowCount: Int = 8
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { _ in
                SkeletonRow()
                Divider()
                    .background(Color.axBorder.opacity(0.3))
            }
        }
    }
}

// MARK: - Skeleton Stats Grid

struct SkeletonStatsGrid: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonCard()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        Text("Skeleton Loading States")
            .font(.headline)
            .foregroundColor(.axTextPrimary)
        
        SkeletonStatsGrid()
        
        Divider()
        
        SkeletonFileList(rowCount: 5)
    }
    .padding()
    .background(Color.axBackground)
}
