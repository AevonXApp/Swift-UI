//
//  ApacheSecuritySection.swift
//  AevonX
//
//  Apache security: ServerTokens, headers, SSL certs, rate limiting.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheSecuritySection: View {
    let serverId: String

    @State private var serverTokens = "on"
    @State private var hsts = false
    @State private var xFrameOptions = ""
    @State private var xContentType = false
    @State private var referrerPolicy = ""
    @State private var sslProtocols = ""
    @State private var sslCerts: [[String: String]] = []
    @State private var isLoading = true
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Server Identity
                AppOptimizationGroup(title: "Server Identity", icon: "shield.fill", color: apacheRed) {
                    AppOptimizationToggle(label: "ServerTokens (hide)", value: Binding(
                        get: { serverTokens == "off" ? "on" : "off" },
                        set: { serverTokens = $0 == "on" ? "off" : "on" }
                    ), hint: "Hide Apache version from responses")
                }

                // Security Headers
                AppOptimizationGroup(title: "Security Headers", icon: "lock.shield.fill", color: .purple) {
                    AppOptimizationToggle(label: "HSTS", value: Binding(
                        get: { hsts ? "on" : "off" },
                        set: { hsts = $0 == "on" }
                    ), hint: "HTTP Strict Transport Security")

                    HStack(spacing: AXSpacing.lg) {
                        Text(L10n.Apps.xFrameOptions)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 240, alignment: .trailing)
                        Picker("", selection: $xFrameOptions) {
                            Text("Off").tag("")
                            Text(L10n.Literal.deny).tag(L10n.Literal.deny)
                            Text(L10n.Literal.sameOrigin).tag(L10n.Literal.sameOrigin)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        Spacer()
                    }
                    .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)

                    AppOptimizationToggle(label: "X-Content-Type-Options", value: Binding(
                        get: { xContentType ? "on" : "off" },
                        set: { xContentType = $0 == "on" }
                    ), hint: "Prevent MIME-type sniffing")
                }

                // SSL
                if !sslCerts.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "SSL Certificates", icon: "lock.fill")
                        ForEach(Array(sslCerts.enumerated()), id: \.offset) { _, cert in
                            certRow(cert)
                        }
                    }
                }

                // Save
                AppOptimizationSaveButton(title: "Save Security Settings", color: apacheRed, isSaving: isSaving) {
                    Task { await saveSettings() }
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadSettings() }
    }

    private func certRow(_ cert: [String: String]) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "lock.fill").font(.system(size: 14)).foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(cert["path"] ?? "").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary).lineLimit(1)
                if let subject = cert["subject"] { Text(subject).font(.system(size: 11)).foregroundColor(.axTextSecondary) }
                if let expires = cert["expires"] { Text("Expires: \(expires)").font(.system(size: 10)).foregroundColor(.axTextMuted) }
            }
            Spacer()
        }
        .padding(AXSpacing.md).background(Color.axSurface.opacity(0.3)).cornerRadius(AXCornerRadius.md)
    }

    private func loadSettings() async {
        isLoading = true
        let json = await bridge.getSecurity(serverID: serverId, appID: "apache")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let sec = resp["data"] as? [String: Any] {
            if let h = sec["headers"] as? [String: Any] {
                serverTokens = h["server_tokens"] as? String ?? "on"
                hsts = h["hsts"] as? Bool ?? false
                xFrameOptions = h["x_frame_options"] as? String ?? ""
                xContentType = h["x_content_type"] as? Bool ?? false
                referrerPolicy = h["referrer_policy"] as? String ?? ""
            }
            sslProtocols = sec["ssl_protocols"] as? String ?? ""
            sslCerts = (sec["ssl_certs"] as? [[String: String]]) ?? []
        }
        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true
        let headers: [String: Any] = [
            "server_tokens": serverTokens,
            "hsts": hsts,
            "x_frame_options": xFrameOptions,
            "x_content_type": xContentType,
            "referrer_policy": referrerPolicy,
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: headers),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode headers"); isSaving = false; return
        }
        let result = await bridge.saveSecurityHeaders(serverID: serverId, appID: "apache", headersJSON: jsonStr)
        if let data = result.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Security settings saved")
        } else { toast.showError("Failed to save security settings") }
        isSaving = false
    }
}
