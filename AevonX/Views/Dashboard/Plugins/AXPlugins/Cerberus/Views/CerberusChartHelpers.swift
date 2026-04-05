//
//  CerberusChartHelpers.swift
//  AevonX
//
//  Shared chart utilities for AXCerberus WAF views:
//  continent-based country coloring, interactive tooltip,
//  time-range picker, and semantic color helpers.
//

import SwiftUI
import Charts
import AevonXCoreBridge

// MARK: - Continent

enum WAFContinent: String, CaseIterable {
    case europe, asia, americas, africa, oceania, unknown

    // ISO 3166-1 alpha-2 → continent
    static func from(countryCode: String) -> WAFContinent {
        switch countryCode.uppercased() {

        // Europe
        case "AD","AL","AT","BA","BE","BG","BY","CH","CY","CZ","DE","DK",
             "EE","ES","FI","FO","FR","GB","GE","GI","GL","GR","HR","HU",
             "IE","IS","IT","LI","LT","LU","LV","MC","MD","ME","MK","MT",
             "NL","NO","PL","PT","RO","RS","RU","SE","SI","SK","SM","TR",
             "UA","VA","XK","IM","JE","GG","AX":
            return .europe

        // Asia
        case "AE","AF","AM","AZ","BD","BH","BN","BT","CN","HK","ID","IL",
             "IN","IQ","IR","JO","JP","KG","KH","KP","KR","KW","KZ","LA",
             "LB","LK","MM","MN","MO","MV","MY","NP","OM","PH","PK","PS",
             "QA","SA","SG","SY","TH","TJ","TL","TM","TW","UZ","VN","YE":
            return .asia

        // Africa
        case "AO","BF","BI","BJ","BW","CD","CF","CG","CI","CM","CV","DJ",
             "DZ","EG","EH","ER","ET","GA","GH","GM","GN","GQ","GW","KE",
             "KM","LR","LS","LY","MA","MG","ML","MR","MU","MW","MZ","NA",
             "NE","NG","RE","RW","SC","SD","SH","SL","SN","SO","SS","ST",
             "SZ","TD","TG","TN","TZ","UG","YT","ZA","ZM","ZW":
            return .africa

        // Americas
        case "AG","AI","AR","AW","BB","BL","BM","BO","BR","BS","BZ","CA",
             "CL","CO","CR","CU","DM","DO","EC","FK","GP","GT","GY","HN",
             "HT","JM","KN","KY","LC","MF","MQ","MS","MX","NI","PA","PE",
             "PM","PR","PY","SV","TC","TT","US","UY","VC","VE","VG","VI",
             "GD","SR","AN","SX","CW","BQ":
            return .americas

        // Oceania
        case "AS","AU","CK","FJ","FM","GU","KI","MH","MP","NC","NF","NR",
             "NU","NZ","PF","PG","PN","PW","SB","TK","TO","TV","VU","WF","WS":
            return .oceania

        default:
            return .unknown
        }
    }

    var color: Color {
        switch self {
        case .europe:   return .axAccentBlue
        case .asia:     return Color(red: 1.0, green: 0.55, blue: 0.1)   // amber-orange
        case .americas: return .axAccentGreen
        case .africa:   return Color(red: 0.65, green: 0.3, blue: 0.9)   // violet-purple
        case .oceania:  return Color(red: 0.0, green: 0.78, blue: 0.7)   // teal
        case .unknown:  return Color.axTextMuted
        }
    }

    var label: String {
        switch self {
        case .europe:   return "Europe"
        case .asia:     return "Asia"
        case .americas: return "Americas"
        case .africa:   return "Africa"
        case .oceania:  return "Oceania"
        case .unknown:  return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .europe:   return "globe.europe.africa.fill"
        case .asia:     return "globe.asia.australia.fill"
        case .americas: return "globe.americas.fill"
        case .africa:   return "globe.europe.africa.fill"
        case .oceania:  return "globe.asia.australia.fill"
        case .unknown:  return "questionmark.circle"
        }
    }
}

// MARK: - Continent Legend

/// Compact horizontal legend showing only the continents present in data.
struct ContinentLegendView: View {
    let countryCodes: [String]

    private var presentContinents: [WAFContinent] {
        var seen = Set<WAFContinent>()
        return countryCodes.compactMap { code -> WAFContinent? in
            let c = WAFContinent.from(countryCode: code)
            guard !seen.contains(c) else { return nil }
            seen.insert(c)
            return c
        }
    }

    var body: some View {
        if !presentContinents.isEmpty {
            HStack(spacing: AXSpacing.md) {
                ForEach(presentContinents, id: \.rawValue) { continent in
                    HStack(spacing: AXSpacing.xxs) {
                        Circle()
                            .fill(continent.color)
                            .frame(width: 6, height: 6)
                        Text(continent.label)
                            .font(AXTypography.caption2)
                            .foregroundStyle(Color.axTextTertiary)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Time Range

enum WAFTimeRange: String, CaseIterable, Identifiable {
    case hour1  = "1H"
    case hour6  = "6H"
    case hour24 = "24H"
    case day7   = "7D"
    case day30  = "30D"
    case all    = "All"

    var id: String { rawValue }

    var granularity: String {
        switch self {
        case .hour1:        return "minute"
        case .hour6:        return "hour"
        case .hour24:       return "hour"
        case .day7, .day30: return "day"
        case .all:          return "week"
        }
    }

    func startDate() -> Date {
        let now = Date()
        let cal = Calendar.current
        switch self {
        case .hour1:  return now.addingTimeInterval(-3600)
        case .hour6:  return now.addingTimeInterval(-6 * 3600)
        case .hour24: return now.addingTimeInterval(-24 * 3600)
        case .day7:   return now.addingTimeInterval(-7 * 86400)
        case .day30:  return now.addingTimeInterval(-30 * 86400)
        case .all:    return cal.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-365 * 86400)
        }
    }
}

// MARK: - Time Range Picker

/// Compact pill-row time range selector.
struct WAFTimeRangePicker: View {
    @Binding var selected: WAFTimeRange
    var ranges: [WAFTimeRange] = WAFTimeRange.allCases

    var body: some View {
        HStack(spacing: AXSpacing.xxs) {
            ForEach(ranges) { range in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selected = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(AXTypography.caption2)
                        .fontWeight(selected == range ? .bold : .medium)
                        .foregroundStyle(selected == range ? .white : Color.axTextSecondary)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxs)
                        .background(
                            selected == range
                                ? AnyShapeStyle(Color.axAccentBlue)
                                : AnyShapeStyle(Color.axSurface)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .strokeBorder(
                                    selected == range
                                        ? Color.clear
                                        : Color.axBorder.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Chart Tooltip

/// Floating tooltip card shown on chart hover.
struct WAFChartTooltip: View {
    let title: String
    let rows: [(label: String, value: String, color: Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(title)
                .font(AXTypography.monoXs)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextSecondary)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: AXSpacing.xs) {
                    Circle()
                        .fill(row.color)
                        .frame(width: 5, height: 5)
                    Text(row.label)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextTertiary)
                    Spacer(minLength: AXSpacing.sm)
                    Text(row.value)
                        .font(AXTypography.monoXs)
                        .fontWeight(.semibold)
                        .foregroundStyle(row.color)
                }
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .strokeBorder(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .fixedSize()
    }
}

// MARK: - Semantic Color Helpers

/// Color for HTTP status code family.
func wafStatusCodeColor(_ code: Int) -> Color {
    switch code {
    case 200..<300: return .axAccentGreen
    case 300..<400: return .axAccentBlue
    case 400..<500: return Color.orange
    case 500..<600: return .axError
    default:        return .axTextMuted
    }
}

/// Color for ranked items (rank 1 = most prominent/dangerous).
func wafRankColor(_ index: Int) -> Color {
    switch index {
    case 0:  return .axError
    case 1:  return Color.orange
    case 2:  return Color.yellow
    default: return .axAccentBlue.opacity(max(0.35, 0.8 - Double(index - 3) * 0.1))
    }
}

/// Returns the flag emoji for a valid ISO 3166-1 alpha-2 country code,
/// or "🌐" globe emoji for unknown/invalid codes (e.g., "XX", "T1", "").
func countryFlagEmoji(_ code: String) -> String {
    let upper = code.uppercased()
    // Must be exactly 2 uppercase ASCII letters (A-Z)
    guard upper.count == 2,
          upper.unicodeScalars.allSatisfy({ $0.value >= 65 && $0.value <= 90 }) else {
        return "🌐"
    }
    let base: UInt32 = 127397
    let scalars = upper.unicodeScalars.compactMap { Unicode.Scalar(base + $0.value) }
    guard scalars.count == 2 else { return "🌐" }
    return scalars.map(String.init).joined()
}
