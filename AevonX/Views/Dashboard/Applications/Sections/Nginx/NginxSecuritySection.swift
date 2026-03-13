//
//  NginxSecuritySection.swift
//  AevonX
//
//  Security dashboard: HTTP headers, SSL certs, rate limiting.
//  Premium design: colored left-border section cards, cert expiry badges,
//  skeleton loading, gradient action buttons.
//

import SwiftUI
import AevonXCoreBridge

struct NginxSecuritySection: View {
    let serverId: String

    // Headers state
    @State private var serverTokens = "on"
    @State private var hsts = false
    @State private var xFrameOptions = "SAMEORIGIN"
    @State private var xContentType = false
    @State private var referrerPolicy = "no-referrer-when-downgrade"

    // Rate limiting state
    @State private var rateLimitRate = "10r/s"
    @State private var rateLimitZoneSize = "10m"
    @State private var rateLimitBurst = "20"
    @State private var existingRateLimits: [String] = []

    // SSL state
    @State private var sslCerts: [[String: String]] = []
    @State private var sslProtocols = ""
    @State private var sslPreferCiphers = false
    @State private var sslStapling = false

    @State private var isLoading = true
    @State private var isSavingHeaders = false
    @State private var isSavingRateLimit = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        Group {
            if isLoading {
                skeletonContent
            } else {
                mainContent
            }
        }
        .task { await loadSecurity() }
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                ForEach(0..<3, id: \.self) { _ in
                    skeletonSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    private var skeletonSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 14, height: 14)
                    .shimmer()
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 140, height: 14)
                    .shimmer()
            }
            VStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { _ in
                    AXSkeletonSettingRow()
                        .background(Color.axSurface)
                }
            }
            .cornerRadius(AXCornerRadius.md)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                securityHeadersSection
                sslSection
                rateLimitSection
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    // MARK: - Security Headers Section

    private var securityHeadersSection: some View {
        accentCard(title: "Security Headers", icon: "shield.lefthalf.filled", color: .red) {
            VStack(spacing: 1) {
                toggleRow(
                    label: "server_tokens",
                    hint: "Hide Nginx version",
                    isOn: Binding(
                        get: { serverTokens == "off" },
                        set: { serverTokens = $0 ? "off" : "on" }
                    )
                )
                Divider().background(Color.axBorder.opacity(0.15))

                toggleRow(label: "HSTS", hint: "Force HTTPS (Strict-Transport-Security)", isOn: $hsts)
                Divider().background(Color.axBorder.opacity(0.15))

                toggleRow(label: "X-Content-Type-Options", hint: "Prevent MIME sniffing", isOn: $xContentType)
                Divider().background(Color.axBorder.opacity(0.15))

                pickerRow(
                    label: "X-Frame-Options",
                    hint: "Prevent clickjacking",
                    value: $xFrameOptions,
                    options: [("DENY", "DENY"), ("SAMEORIGIN", "SAMEORIGIN"), ("Disabled", "")]
                )
                Divider().background(Color.axBorder.opacity(0.15))

                pickerRow(
                    label: "Referrer-Policy",
                    hint: "Control referrer info",
                    value: $referrerPolicy,
                    options: [
                        ("no-referrer", "no-referrer"),
                        ("no-referrer-when-downgrade", "no-referrer-when-downgrade"),
                        ("same-origin", "same-origin"),
                        ("strict-origin", "strict-origin"),
                    ]
                )
            }

            // Apply button
            HStack {
                Spacer()
                gradientButton(
                    icon: "shield.checkered",
                    label: "Apply Headers",
                    color: .red,
                    isLoading: isSavingHeaders,
                    action: { Task { await saveHeaders() } }
                )
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.bottom, AXSpacing.md)
        }
    }

    // MARK: - SSL Section

    private var sslSection: some View {
        accentCard(title: "SSL / TLS", icon: "lock.fill", color: .green) {
            VStack(spacing: 0) {
                infoRow("Protocols", value: sslProtocols.isEmpty ? "Not configured" : sslProtocols)
                Divider().background(Color.axBorder.opacity(0.15))
                sslBoolRow("Prefer Server Ciphers", enabled: sslPreferCiphers)
                Divider().background(Color.axBorder.opacity(0.15))
                sslBoolRow("OCSP Stapling", enabled: sslStapling)
            }

            if !sslCerts.isEmpty {
                Divider().padding(.horizontal, AXSpacing.lg).padding(.top, AXSpacing.sm)

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Certificates")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.lg)

                    ForEach(sslCerts.indices, id: \.self) { i in
                        certRow(sslCerts[i])
                    }
                }
                .padding(.bottom, AXSpacing.md)
            } else {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axWarning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No SSL certificates found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                        Text("Configure Let's Encrypt or upload your certificates")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                    }
                }
                .padding(AXSpacing.lg)
            }
        }
    }

    // MARK: - Rate Limit Section

    private var rateLimitSection: some View {
        accentCard(title: "Rate Limiting", icon: "speedometer", color: .orange) {
            VStack(spacing: 1) {
                inputRow(label: "Rate", value: $rateLimitRate, hint: "Requests/s (e.g. 10r/s)", placeholder: "10r/s")
                Divider().background(Color.axBorder.opacity(0.15))
                inputRow(label: "Zone Size", value: $rateLimitZoneSize, hint: "Shared memory (e.g. 10m)", placeholder: "10m")
                Divider().background(Color.axBorder.opacity(0.15))
                inputRow(label: "Burst", value: $rateLimitBurst, hint: "Allowed burst requests", placeholder: "20")
            }

            if !existingRateLimits.isEmpty {
                Divider().padding(.horizontal, AXSpacing.lg).padding(.top, AXSpacing.sm)
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Active Rules")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.lg)

                    ForEach(existingRateLimits, id: \.self) { rule in
                        Text(rule)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, 2)
                    }
                }
                .padding(.bottom, AXSpacing.sm)
            }

            HStack {
                Spacer()
                gradientButton(
                    icon: "bolt.shield.fill",
                    label: "Apply Rate Limit",
                    color: .orange,
                    isLoading: isSavingRateLimit,
                    action: { Task { await saveRateLimit() } }
                )
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.bottom, AXSpacing.md)
        }
    }

    // MARK: - Row Builders

    private func toggleRow(label: String, hint: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.85)
                .labelsHidden()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func pickerRow(label: String, hint: String, value: Binding<String>, options: [(String, String)]) -> some View {
        HStack(spacing: AXSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Picker("", selection: value) {
                ForEach(options, id: \.1) { opt in
                    Text(opt.0).tag(opt.1)
                }
            }
            .frame(width: 220)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 180, alignment: .leading)

            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func sslBoolRow(_ label: String, enabled: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 180, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(enabled ? .axSuccess : .axError)
                Text(enabled ? "Yes" : "No")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(enabled ? .axSuccess : .axError)
            }

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func certRow(_ cert: [String: String]) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 28, height: 28)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(cert["path"] ?? "Unknown")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)

                if let subject = cert["subject"], !subject.isEmpty {
                    Text(subject)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                }
            }

            Spacer()

            // Expiry badge
            if let expires = cert["expires_at"], !expires.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                    Text(expires)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.axWarning)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.axWarning.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }

    private func inputRow(label: String, value: Binding<String>, hint: String, placeholder: String) -> some View {
        HStack(spacing: AXSpacing.lg) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 90, alignment: .trailing)

            TextField(placeholder, text: value)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(.plain)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .frame(width: 100)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                )

            Text(hint)
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    // MARK: - Accent Card Container

    private func accentCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(color.opacity(0.05))

            Divider().background(color.opacity(0.2))

            content()
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        // Left color stripe
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    // MARK: - Gradient Button

    private func gradientButton(icon: String, label: String, color: Color, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                if isLoading {
                    ProgressView().scaleEffect(0.65).frame(width: 14, height: 14)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AXCornerRadius.sm)
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }

    // MARK: - Data Loading

    private func loadSecurity() async {
        isLoading = true
        let json = await bridge.getSecurity(serverID: serverId, appID: "nginx")

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {

            if let h = info["headers"] as? [String: Any] {
                if let v = h["server_tokens"] as? String { serverTokens = v }
                if let v = h["hsts"] as? Bool { hsts = v }
                if let v = h["x_frame_options"] as? String, !v.isEmpty { xFrameOptions = v }
                if let v = h["x_content_type_options"] as? Bool { xContentType = v }
                if let v = h["referrer_policy"] as? String, !v.isEmpty { referrerPolicy = v }
            }

            if let v = info["ssl_protocols"] as? String { sslProtocols = v }
            if let v = info["ssl_prefer_server_ciphers"] as? Bool { sslPreferCiphers = v }
            if let v = info["ssl_stapling"] as? Bool { sslStapling = v }

            if let certs = info["ssl_certs"] as? [[String: Any]] {
                sslCerts = certs.map { cert in
                    ["path": cert["path"] as? String ?? "",
                     "subject": cert["subject"] as? String ?? "",
                     "expires_at": cert["expires_at"] as? String ?? "",
                     "issuer": cert["issuer"] as? String ?? ""]
                }
            }

            if let rl = info["rate_limiting"] as? [String] {
                existingRateLimits = rl
            }
        }

        isLoading = false
    }

    private func saveHeaders() async {
        isSavingHeaders = true
        let headers: [String: Any] = [
            "server_tokens": serverTokens,
            "hsts": hsts,
            "x_frame_options": xFrameOptions,
            "x_content_type_options": xContentType,
            "referrer_policy": referrerPolicy,
            "content_security_policy": "",
            "permissions_policy": "",
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: headers),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode headers")
            isSavingHeaders = false
            return
        }

        let result = await bridge.saveSecurityHeaders(serverID: serverId, appID: "nginx", headersJSON: jsonStr)
        if let data = result.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Security headers applied — nginx config updated")
        } else {
            toast.showError("Failed to apply security headers")
        }
        isSavingHeaders = false
    }

    private func saveRateLimit() async {
        isSavingRateLimit = true
        let settings: [String: String] = [
            "rate": rateLimitRate,
            "zone_size": rateLimitZoneSize,
            "burst": rateLimitBurst,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode rate limit settings")
            isSavingRateLimit = false
            return
        }

        let result = await bridge.saveRateLimit(serverID: serverId, appID: "nginx", settingsJSON: jsonStr)
        if let data = result.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Rate limiting applied — nginx config updated")
        } else {
            toast.showError("Failed to apply rate limiting")
        }
        isSavingRateLimit = false
    }
}
