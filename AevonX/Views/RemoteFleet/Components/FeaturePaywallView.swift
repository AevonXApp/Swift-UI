import SwiftUI
import AevonXCoreBridge

/// Compact paywall overlay — centered card with plan comparison.
struct FeaturePaywallView: View {

    let featureTitle: String
    let featureDescription: String
    @Binding var isPresented: Bool

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(appear ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: AXSpacing.lg) {
                // ── Header ──
                VStack(spacing: AXSpacing.sm) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axAccentBlue)
                        .padding(AXSpacing.md)
                        .background(Color.axAccentBlue.opacity(0.12))
                        .clipShape(Circle())

                    Text(featureTitle)
                        .font(AXTypography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Text(featureDescription)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                Divider().background(Color.axBorder.opacity(0.3))

                // ── Compact Plan Comparison ──
                HStack(spacing: AXSpacing.md) {
                    planCard(
                        title: "Free", color: .axTextMuted,
                        features: [("1 Server", true), ("Websites", false), ("Databases", false)]
                    )

                    planCard(
                        title: "Pro", color: .axAccentBlue, highlight: true,
                        features: [("∞ Servers", true), ("∞ Websites", true), ("∞ Databases", true)]
                    )
                }

                // ── CTA ──
                Button(action: {
                    NSWorkspace.shared.open(AppURLs.subscription)
                    dismiss()
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Subscribe Now")
                            .fontWeight(.semibold)
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm + 2)
                    .background(
                        LinearGradient(
                            colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(PlainButtonStyle())

                Button("Maybe Later") { dismiss() }
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            .frame(maxWidth: 360)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl).fill(Color.axSurface.opacity(0.6))
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl).stroke(Color.axBorder.opacity(0.25), lineWidth: 1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xl))
            .shadow(color: Color.black.opacity(0.4), radius: 20, y: 8)
            .scaleEffect(appear ? 1.0 : 0.92)
            .opacity(appear ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { appear = true }
        }
    }

    // MARK: - Plan Card

    private func planCard(
        title: String, color: Color, highlight: Bool = false,
        features: [(String, Bool)]
    ) -> some View {
        VStack(spacing: AXSpacing.sm) {
            Text(title)
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(highlight ? color : .axTextSecondary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(features, id: \.0) { feat in
                    HStack(spacing: 4) {
                        Image(systemName: feat.1 ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.system(size: 10))
                            .foregroundColor(feat.1 ? (highlight ? color : .axSuccess) : .axTextMuted)
                        Text(feat.0)
                            .font(.system(size: 11))
                            .foregroundColor(feat.1 ? .axTextPrimary : .axTextMuted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(highlight ? color.opacity(0.06) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(highlight ? color.opacity(0.2) : Color.axBorder.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { appear = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }
}
