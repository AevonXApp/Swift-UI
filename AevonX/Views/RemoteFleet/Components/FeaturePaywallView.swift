import SwiftUI
import AevonXCoreBridge

/// Beautiful paywall view shown when a feature is locked.
/// Displays a comparison between Free and Pro plans with features from the API.
/// Uses glassmorphism + spring animations for premium feel.
struct FeaturePaywallView: View {
    
    let featureTitle: String
    let featureDescription: String
    @Binding var isPresented: Bool
    
    @State private var appearAnimation = false
    @State private var planData: [[String: Any]] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            // Main card
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Plan comparison
                comparisonSection
                
                // CTA button
                ctaSection
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 30, y: 10)
            .padding(.horizontal, 40)
            .scaleEffect(appearAnimation ? 1.0 : 0.9)
            .opacity(appearAnimation ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: AXSpacing.md) {
            // Lock icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentBlue.opacity(0.3), Color.axAccentBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.axAccentBlue)
            }
            
            Text(featureTitle)
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
                .multilineTextAlignment(.center)
            
            Text(featureDescription)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
    
    // MARK: - Comparison
    
    private var comparisonSection: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            // Free Plan
            planColumn(
                title: "Free",
                color: .axTextMuted,
                features: [
                    PlanFeatureRow(icon: "server.rack", label: "1 Server", enabled: true),
                    PlanFeatureRow(icon: "globe", label: "No Websites", enabled: false),
                    PlanFeatureRow(icon: "cylinder", label: "No Databases", enabled: false),
                    PlanFeatureRow(icon: "chart.bar", label: "No Monitoring", enabled: false),
                ]
            )
            
            // VS divider
            VStack {
                Spacer()
                Text("VS")
                    .font(AXTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextMuted)
                    .padding(.vertical, AXSpacing.sm)
                    .padding(.horizontal, AXSpacing.md)
                    .background(
                        Capsule()
                            .fill(Color.axTextMuted.opacity(0.1))
                    )
                Spacer()
            }
            
            // Pro Plan
            planColumn(
                title: "Pro ⭐",
                color: .axAccentBlue,
                features: [
                    PlanFeatureRow(icon: "server.rack", label: "∞ Servers", enabled: true),
                    PlanFeatureRow(icon: "globe", label: "∞ Websites", enabled: true),
                    PlanFeatureRow(icon: "cylinder", label: "∞ Databases", enabled: true),
                    PlanFeatureRow(icon: "chart.bar", label: "Monitoring", enabled: true),
                ],
                highlighted: true
            )
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }
    
    private func planColumn(
        title: String,
        color: Color,
        features: [PlanFeatureRow],
        highlighted: Bool = false
    ) -> some View {
        VStack(spacing: AXSpacing.md) {
            Text(title)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundColor(highlighted ? color : .axTextSecondary)
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(features, id: \.label) { feature in
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: feature.enabled ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(feature.enabled ? (highlighted ? color : .axSuccess) : .axTextMuted)
                        
                        Text(feature.label)
                            .font(AXTypography.caption)
                            .foregroundColor(feature.enabled ? .axTextPrimary : .axTextMuted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(highlighted ? color.opacity(0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(highlighted ? color.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    // MARK: - CTA
    
    private var ctaSection: some View {
        VStack(spacing: AXSpacing.md) {
            Button(action: openSubscription) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Subscribe Now")
                        .fontWeight(.semibold)
                }
                .font(AXTypography.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AXSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
                .shadow(color: Color.axAccentBlue.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: dismiss) {
                Text("Maybe Later")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }
    
    // MARK: - Actions
    
    private func openSubscription() {
        NSWorkspace.shared.open(AppURLs.subscription)
        dismiss()
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            appearAnimation = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Supporting Types

private struct PlanFeatureRow {
    let icon: String
    let label: String
    let enabled: Bool
}
