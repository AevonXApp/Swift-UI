import SwiftUI
import AevonXCoreBridge

/// Dynamic paywall overlay — plan comparison + pricing fetched from API.
struct FeaturePaywallView: View {

    let featureTitle: String
    let featureDescription: String
    @Binding var isPresented: Bool

    @State private var appear = false
    @State private var plans: [PaywallPlan] = []
    @State private var pricing: [PaywallPricing] = []
    @State private var selectedPricing: PaywallPricing?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.opacity(appear ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, AXSpacing.lg)

                Divider().background(Color.axBorder.opacity(0.3))
                    .padding(.horizontal, -AXSpacing.xl)

                if isLoading {
                    loadingSection
                } else {
                    comparisonSection
                        .padding(.top, AXSpacing.lg)

                    if !pricing.isEmpty {
                        pricingSection
                            .padding(.top, AXSpacing.lg)
                    }
                }

                ctaSection
                    .padding(.top, AXSpacing.lg)
            }
            .padding(AXSpacing.xl)
            .frame(maxWidth: 460)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xl))
            .shadow(color: Color.black.opacity(0.4), radius: 20, y: 8)
            .scaleEffect(appear ? 1.0 : 0.92)
            .opacity(appear ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { appear = true }
            Task { await fetchPlans() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
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
    }

    // MARK: - Loading

    private var loadingSection: some View {
        ProgressView()
            .frame(height: 120)
            .padding(.vertical, AXSpacing.lg)
    }

    // MARK: - Plan Comparison

    private var comparisonSection: some View {
        HStack(spacing: AXSpacing.md) {
            ForEach(plans) { plan in
                planCard(plan: plan)
            }
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: AXSpacing.sm) {
            Text("Choose a Plan")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.axTextSecondary)
                .textCase(.uppercase)

            pricingGrid
        }
    }

    private var pricingGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AXSpacing.xs), count: 2)
        return LazyVGrid(columns: columns, spacing: AXSpacing.xs) {
            ForEach(pricing) { price in
                pricingChip(price: price)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedPricing = price
                        }
                    }
            }
        }
    }

    private func pricingChip(price: PaywallPricing) -> some View {
        let isSelected = selectedPricing?.id == price.id
        let hasDiscount = price.originalPrice > price.totalPrice

        return VStack(spacing: AXSpacing.xxxs) {
            if price.isPopular {
                popularBadge
            }

            // Duration label
            Text(price.durationLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)

            // Price row: original (crossed) + actual
            HStack(spacing: 4) {
                if hasDiscount {
                    Text("$\(String(format: "%.2f", price.originalPrice))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                        .strikethrough(color: .axTextMuted)
                }
                Text("$\(String(format: "%.2f", price.totalPrice))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
            }

            // Per-month if multi-month
            if price.durationMonths > 1 {
                Text("$\(String(format: "%.2f", price.monthlyPrice))/month")
                    .font(.system(size: 8))
                    .foregroundColor(.axTextMuted)
            }

            // Savings badge
            if price.savingsPercent > 0 {
                Text("Save \(price.savingsPercent)%")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.axSuccess)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.sm)
        .padding(.horizontal, AXSpacing.xs)
        .background(chipBackground(isSelected: isSelected))
        .contentShape(Rectangle())
    }

    private var popularBadge: some View {
        Text("MOST POPULAR")
            .font(.system(size: 6, weight: .black))
            .foregroundColor(.axAccentBlue)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Color.axAccentBlue.opacity(0.15))
            .cornerRadius(3)
    }

    private func chipBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.md)
            .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(
                        isSelected ? Color.axAccentBlue.opacity(0.4) : Color.axBorder.opacity(0.15),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: AXSpacing.sm) {
            Button(action: {
                var urlString = AppURLs.subscription.absoluteString
                if let selected = selectedPricing {
                    urlString += "?plan=\(selected.slug)"
                }
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
                dismiss()
            }) {
                ctaButtonContent
            }
            .buttonStyle(PlainButtonStyle())

            Button(L10n.Button.maybeLater) { dismiss() }
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .buttonStyle(PlainButtonStyle())
        }
    }

    private var ctaButtonContent: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))

            if let sel = selectedPricing {
                Text("\(L10n.Button.subscribeNow) — $\(String(format: "%.2f", sel.totalPrice))")
                    .fontWeight(.semibold)
            } else {
                Text(L10n.Button.subscribeNow)
                    .fontWeight(.semibold)
            }
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

    // MARK: - Plan Card

    private func planCard(plan: PaywallPlan) -> some View {
        let highlight = plan.plan != "free"
        let color: Color = highlight ? .axAccentBlue : .axTextMuted

        return VStack(spacing: AXSpacing.sm) {
            Text(plan.label)
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(highlight ? color : .axTextSecondary)

            planFeaturesList(plan: plan, highlight: highlight, color: color)
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

    private func planFeaturesList(plan: PaywallPlan, highlight: Bool, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(plan.features) { feature in
                HStack(spacing: 4) {
                    Image(systemName: feature.enabled ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(feature.enabled ? (highlight ? color : .axSuccess) : .axTextMuted)
                    Text(feature.displayText)
                        .font(.system(size: 11))
                        .foregroundColor(feature.enabled ? .axTextPrimary : .axTextMuted)
                }
            }
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.xl).fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: AXCornerRadius.xl).fill(Color.axSurface.opacity(0.6))
            RoundedRectangle(cornerRadius: AXCornerRadius.xl).stroke(Color.axBorder.opacity(0.25), lineWidth: 1)
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { appear = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }

    // MARK: - API Fetch

    private func fetchPlans() async {
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
        guard let token = await AuthService.shared.getToken() else {
            loadFallback()
            return
        }

        let resultJSON = await APIBridge.shared.fetchPlanComparisonAsync(baseURL: baseURL, token: token)

        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true else {
            loadFallback()
            return
        }

        let responseData: [String: Any]
        if let nested = result["data"] as? [String: Any] {
            responseData = nested
        } else {
            responseData = result
        }

        guard let plansArray = responseData["plans"] as? [[String: Any]] else {
            loadFallback()
            return
        }

        var parsed: [PaywallPlan] = []
        var parsedPricing: [PaywallPricing] = []

        for planDict in plansArray {
            guard let planName = planDict["plan"] as? String,
                  let label = planDict["label"] as? String,
                  let featuresArray = planDict["features"] as? [[String: Any]] else { continue }

            if planName == "enterprise" { continue }

            let features = parseFeatures(featuresArray)
            parsed.append(PaywallPlan(plan: planName, label: label, features: features))

            if planName == "pro", let pricingArray = planDict["pricing"] as? [[String: Any]] {
                parsedPricing = parsePricing(pricingArray)
            }
        }

        await MainActor.run {
            self.plans = parsed
            self.pricing = parsedPricing
            self.selectedPricing = parsedPricing.first(where: { $0.isPopular }) ?? parsedPricing.first
            self.isLoading = false
        }
    }

    private func parseFeatures(_ featuresArray: [[String: Any]]) -> [PaywallFeature] {
        featuresArray.compactMap { feat in
            let displayLabel = feat["label"] as? String ?? ""
            let rawValue = (feat["value"] as? Int) ?? Int(feat["value"] as? Double ?? 0)
            let enabled = rawValue != 0

            let displayText: String
            if rawValue == -1 {
                displayText = "∞ \(displayLabel)"
            } else if rawValue > 0 {
                let singular = displayLabel.replacingOccurrences(of: "s$", with: "", options: .regularExpression)
                displayText = "\(rawValue) \(rawValue == 1 ? singular : displayLabel)"
            } else {
                displayText = displayLabel
            }

            return PaywallFeature(
                key: feat["key"] as? String ?? "",
                displayText: displayText,
                enabled: enabled
            )
        }
    }

    private func parsePricing(_ pricingArray: [[String: Any]]) -> [PaywallPricing] {
        pricingArray.compactMap { p in
            let name = p["name"] as? String ?? ""
            let slug = p["slug"] as? String ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
            let durationMonths = (p["duration_months"] as? Int) ?? Int(p["duration_months"] as? Double ?? 1)
            let totalPrice = (p["price"] as? Double) ?? Double(p["price"] as? Int ?? 0)
            let originalPrice = (p["original_price"] as? Double) ?? Double(p["original_price"] as? Int ?? 0)
            let monthlyPrice = (p["monthly_price"] as? Double) ?? Double(p["monthly_price"] as? Int ?? 0)
            let savings = (p["savings_percent"] as? Int) ?? Int(p["savings_percent"] as? Double ?? 0)
            let isPopular = p["is_popular"] as? Bool ?? false

            return PaywallPricing(
                slug: slug,
                name: name,
                durationMonths: durationMonths,
                totalPrice: totalPrice,
                originalPrice: originalPrice > 0 ? originalPrice : totalPrice,
                monthlyPrice: monthlyPrice,
                savingsPercent: savings,
                isPopular: isPopular
            )
        }
    }

    private func loadFallback() {
        Task { @MainActor in
            self.plans = [
                PaywallPlan(plan: "free", label: "Free", features: [
                    PaywallFeature(key: "servers", displayText: "1 Server", enabled: true),
                    PaywallFeature(key: "websites", displayText: "∞ Websites", enabled: true),
                    PaywallFeature(key: "databases", displayText: "∞ Databases", enabled: true),
                ]),
                PaywallPlan(plan: "pro", label: "Pro", features: [
                    PaywallFeature(key: "servers", displayText: "∞ Servers", enabled: true),
                    PaywallFeature(key: "websites", displayText: "∞ Websites", enabled: true),
                    PaywallFeature(key: "databases", displayText: "∞ Databases", enabled: true),
                ]),
            ]
            self.pricing = [
                PaywallPricing(slug: "monthly", name: "Monthly", durationMonths: 1, totalPrice: 4.99, originalPrice: 7.99, monthlyPrice: 4.99, savingsPercent: 38, isPopular: false),
                PaywallPricing(slug: "3-month", name: "3-Month", durationMonths: 3, totalPrice: 11.99, originalPrice: 23.97, monthlyPrice: 4.00, savingsPercent: 50, isPopular: true),
                PaywallPricing(slug: "6-month", name: "6-Month", durationMonths: 6, totalPrice: 21.99, originalPrice: 47.94, monthlyPrice: 3.67, savingsPercent: 54, isPopular: false),
                PaywallPricing(slug: "annual", name: "Annual", durationMonths: 12, totalPrice: 39.99, originalPrice: 95.88, monthlyPrice: 3.33, savingsPercent: 58, isPopular: false),
            ]
            self.selectedPricing = self.pricing.first(where: { $0.isPopular }) ?? self.pricing.first
            self.isLoading = false
        }
    }
}

// MARK: - Models

private struct PaywallPlan: Identifiable {
    let plan: String
    let label: String
    let features: [PaywallFeature]
    var id: String { plan }
}

private struct PaywallFeature: Identifiable {
    let key: String
    let displayText: String
    let enabled: Bool
    var id: String { key }
}

private struct PaywallPricing: Identifiable {
    let slug: String
    let name: String
    let durationMonths: Int
    let totalPrice: Double
    let originalPrice: Double
    let monthlyPrice: Double
    let savingsPercent: Int
    let isPopular: Bool
    var id: String { slug }

    var durationLabel: String {
        switch durationMonths {
        case 1: return "1 Month"
        case 12: return "1 Year"
        default: return "\(durationMonths) Months"
        }
    }
}
