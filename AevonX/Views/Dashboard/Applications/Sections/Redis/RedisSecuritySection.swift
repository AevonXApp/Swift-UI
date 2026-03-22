//
//  RedisSecuritySection.swift
//  AevonX
//
//  Security dashboard: requirepass, protected-mode, ACL, bind, TLS.
//

import SwiftUI
import AevonXCoreBridge

struct RedisSecuritySection: View {
    let serverId: String
    @State private var serverTokens = "on"
    @State private var hsts = false
    @State private var xContentType = false
    @State private var existingRateLimits: [String] = []
    @State private var sslCerts: [[String: String]] = []
    @State private var sslProtocols = ""
    @State private var sslPreferCiphers = false
    @State private var sslStapling = false
    @State private var isLoading = true
    @State private var isSavingHeaders = false
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        Group { if isLoading { skeletonContent } else { mainContent } }
            .task { await loadSecurity() }
    }

    private var skeletonContent: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) { ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.sm) {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface).frame(width: 14, height: 14).shimmer()
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface).frame(width: 140, height: 14).shimmer()
                    }
                    VStack(spacing: 1) { ForEach(0..<3, id: \.self) { _ in AXSkeletonSettingRow().background(Color.axSurface) } }
                        .cornerRadius(AXCornerRadius.md)
                }
            }}.padding(AXSpacing.xl)
        }.background(Color.axBackground)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) { authSection; sslSection; aclSection }
                .padding(AXSpacing.xl)
        }.background(Color.axBackground)
    }

    private var authSection: some View {
        accentCard(title: "Authentication", icon: "lock.fill", color: .red) {
            VStack(spacing: 1) {
                toggleRow(label: "Protected Mode", hint: "Restrict external access when no password set",
                          isOn: Binding(get: { serverTokens == "on" }, set: { serverTokens = $0 ? "on" : "off" }))
                Divider().background(Color.axBorder.opacity(0.15))
                toggleRow(label: "requirepass", hint: "Password authentication enabled", isOn: $hsts)
            }
            HStack { Spacer()
                gradientButton(icon: "shield.checkered", label: "Apply", color: .red, isLoading: isSavingHeaders) { Task { await saveHeaders() } }
            }.padding(.horizontal, AXSpacing.lg).padding(.bottom, AXSpacing.md)
        }
    }

    private var sslSection: some View {
        accentCard(title: "TLS / SSL", icon: "lock.shield.fill", color: .green) {
            VStack(spacing: 0) {
                infoRow("TLS Port", value: sslProtocols.isEmpty ? "Not configured" : sslProtocols)
                Divider().background(Color.axBorder.opacity(0.15))
                sslBoolRow("TLS Enabled", enabled: sslPreferCiphers)
            }
            if !sslCerts.isEmpty {
                Divider().padding(.horizontal, AXSpacing.lg).padding(.top, AXSpacing.sm)
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Certificates").font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextMuted).padding(.horizontal, AXSpacing.lg)
                    ForEach(sslCerts.indices, id: \.self) { i in certRow(sslCerts[i]) }
                }.padding(.bottom, AXSpacing.md)
            }
        }
    }

    private var aclSection: some View {
        accentCard(title: "ACL Rules", icon: "person.badge.key.fill", color: .orange) {
            if existingRateLimits.isEmpty {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "info.circle.fill").font(.system(size: 12)).foregroundColor(.axAccentBlue)
                    Text("No ACL rules configured — default user only").font(.system(size: 12)).foregroundColor(.axTextSecondary)
                }.padding(AXSpacing.lg)
            } else {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    ForEach(existingRateLimits, id: \.self) { rule in
                        Text(rule).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.lg).padding(.vertical, 2)
                    }
                }.padding(.vertical, AXSpacing.sm)
            }
        }
    }

    // MARK: - Shared Builders

    private func toggleRow(label: String, hint: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
                Text(hint).font(.system(size: 10)).foregroundColor(.axTextMuted)
            }; Spacer()
            Toggle("", isOn: isOn).toggleStyle(.switch).scaleEffect(0.85).labelsHidden()
        }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm).background(Color.axSurface)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextSecondary).frame(width: 180, alignment: .leading)
            Text(value).font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextPrimary); Spacer()
        }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm).background(Color.axSurface)
    }

    private func sslBoolRow(_ label: String, enabled: Bool) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextSecondary).frame(width: 180, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 12)).foregroundColor(enabled ? .axSuccess : .axError)
                Text(enabled ? "Yes" : "No").font(.system(size: 12, weight: .medium)).foregroundColor(enabled ? .axSuccess : .axError)
            }; Spacer()
        }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm).background(Color.axSurface)
    }

    private func certRow(_ cert: [String: String]) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "lock.shield.fill").font(.system(size: 14)).foregroundColor(.green)
                .frame(width: 28, height: 28).background(Color.green.opacity(0.1)).cornerRadius(6)
            Text(cert["path"] ?? "Unknown").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextPrimary).lineLimit(1)
            Spacer()
        }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)
    }

    private func accentCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                ZStack { RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.15)).frame(width: 28, height: 28)
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color) }
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.axTextPrimary); Spacer()
            }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md).background(color.opacity(0.05))
            Divider().background(color.opacity(0.2)); content()
        }.background(Color.axSurface).cornerRadius(AXCornerRadius.lg)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(color.opacity(0.18), lineWidth: 1))
            .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .frame(width: 3).padding(.vertical, 8) }
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    private func gradientButton(icon: String, label: String, color: Color, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                if isLoading { ProgressView().scaleEffect(0.65).frame(width: 14, height: 14) }
                else { Image(systemName: icon).font(.system(size: 12, weight: .semibold)) }
                Text(label).font(.system(size: 12, weight: .semibold))
            }.foregroundColor(.white).padding(.horizontal, AXSpacing.lg).padding(.vertical, 8)
                .background(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(AXCornerRadius.sm).shadow(color: color.opacity(0.3), radius: 4, y: 2)
        }.buttonStyle(PlainButtonStyle()).disabled(isLoading)
    }

    // MARK: - Data

    private func loadSecurity() async {
        isLoading = true
        let json = await bridge.getSecurity(serverID: serverId, appID: "redis")
        if let data = json.data(using: .utf8), let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true, let info = resp["data"] as? [String: Any] {
            if let h = info["headers"] as? [String: Any] {
                if let v = h["server_tokens"] as? String { serverTokens = v }
                if let v = h["hsts"] as? Bool { hsts = v }
                if let v = h["x_content_type_options"] as? Bool { xContentType = v }
            }
            if let v = info["ssl_protocols"] as? String { sslProtocols = v }
            if let v = info["ssl_prefer_server_ciphers"] as? Bool { sslPreferCiphers = v }
            if let certs = info["ssl_certs"] as? [[String: Any]] {
                sslCerts = certs.map { ["path": $0["path"] as? String ?? ""] }
            }
            if let rl = info["rate_limiting"] as? [String] { existingRateLimits = rl }
        }
        isLoading = false
    }

    private func saveHeaders() async {
        isSavingHeaders = true
        let headers: [String: Any] = ["server_tokens": serverTokens, "hsts": hsts, "x_content_type_options": xContentType]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: headers),
              let jsonStr = String(data: jsonData, encoding: .utf8) else { isSavingHeaders = false; return }
        let result = await bridge.saveSecurityHeaders(serverID: serverId, appID: "redis", headersJSON: jsonStr)
        if let data = result.data(using: .utf8), let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true { toast.showSuccess("Security settings applied") }
        else { toast.showError("Failed to apply security settings") }
        isSavingHeaders = false
    }
}
