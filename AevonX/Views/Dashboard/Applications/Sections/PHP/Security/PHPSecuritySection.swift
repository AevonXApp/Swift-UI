//
//  PHPSecuritySection.swift
//  AevonX
//
//  Hardening, disable_functions, open_basedir.
//

import SwiftUI
import AevonXCoreBridge

struct PHPSecuritySection: View {
    let serverId: String

    @State private var exposePhp = true
    @State private var displayErrors = false
    @State private var allowUrlFopen = true
    @State private var allowUrlInclude = false
    @State private var cgiFixPathinfo = true
    @State private var cookieHttponly = false
    @State private var cookieSecure = false
    @State private var useStrictMode = false
    @State private var disableFunctions = ""
    @State private var openBasedir = ""

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var securityScore = 0
    @State private var securityChecks: [(status: String, setting: String, message: String)] = []

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        Group {
            if isLoading { skeletonContent } else { mainContent }
        }
        .task { await loadSecurity() }
    }

    private var skeletonContent: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack(spacing: AXSpacing.sm) {
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface).frame(width: 14, height: 14).shimmer()
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurface).frame(width: 140, height: 14).shimmer()
                        }
                        VStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { _ in AXSkeletonSettingRow().background(Color.axSurface) }
                        }
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Score ring
                HStack(spacing: AXSpacing.xl) {
                    ZStack {
                        Circle().stroke(Color.axSurface, lineWidth: 10).frame(width: 90, height: 90)
                        Circle().trim(from: 0, to: Double(securityScore) / 100.0)
                            .stroke(scoreColor(securityScore), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 90, height: 90).rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(securityScore)").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(scoreColor(securityScore))
                            Text("/ 100").font(.system(size: 10)).foregroundColor(.axTextMuted)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Apps.securityScore).font(.system(size: 16, weight: .bold)).foregroundColor(.axTextPrimary)
                        Text(securityScore >= 80 ? "Well hardened" : securityScore >= 50 ? "Improvements needed" : "Critical issues")
                            .font(.system(size: 12)).foregroundColor(.axTextSecondary)
                    }
                    Spacer()
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface.opacity(0.4))
                .cornerRadius(AXCornerRadius.lg)

                accentCard(title: "PHP Exposure", icon: "eye.slash.fill", color: .red) {
                    VStack(spacing: 1) {
                        secToggleRow(label: "expose_php", hint: "Hide PHP version from HTTP headers", isOn: $exposePhp, inverted: true)
                        Divider().background(Color.axBorder.opacity(0.15))
                        secToggleRow(label: "display_errors", hint: "Show errors to users (disable in production)", isOn: $displayErrors, inverted: true)
                        Divider().background(Color.axBorder.opacity(0.15))
                        secToggleRow(label: "cgi.fix_pathinfo", hint: "Path info handling (set to 0 for security)", isOn: $cgiFixPathinfo, inverted: true)
                    }
                }

                accentCard(title: "URL Security", icon: "globe", color: .orange) {
                    VStack(spacing: 1) {
                        secToggleRow(label: "allow_url_fopen", hint: "Allow remote file access", isOn: $allowUrlFopen, inverted: true)
                        Divider().background(Color.axBorder.opacity(0.15))
                        secToggleRow(label: "allow_url_include", hint: "Allow remote file inclusion (CRITICAL)", isOn: $allowUrlInclude, inverted: true)
                    }
                }

                accentCard(title: "Session Security", icon: "lock.fill", color: .green) {
                    VStack(spacing: 1) {
                        secToggleRow(label: "session.cookie_httponly", hint: "Prevent XSS cookie theft", isOn: $cookieHttponly, inverted: false)
                        Divider().background(Color.axBorder.opacity(0.15))
                        secToggleRow(label: "session.cookie_secure", hint: "HTTPS-only cookies", isOn: $cookieSecure, inverted: false)
                        Divider().background(Color.axBorder.opacity(0.15))
                        secToggleRow(label: "session.use_strict_mode", hint: "Reject uninitialized session IDs", isOn: $useStrictMode, inverted: false)
                    }
                }

                accentCard(title: "Filesystem Restrictions", icon: "folder.badge.minus", color: phpPurple) {
                    VStack(spacing: AXSpacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("disable_functions").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
                            Text(L10n.Apps.commaSeparatedListOfDangerousFunctionsToDisable).font(.system(size: 10)).foregroundColor(.axTextMuted)
                            TextField("exec,passthru,shell_exec,system...", text: $disableFunctions)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 11, design: .monospaced))
                                .padding(AXSpacing.sm)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, AXSpacing.lg).padding(.top, AXSpacing.md)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("open_basedir").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
                            Text(L10n.Apps.restrictFilesystemAccessToSpecifiedDirectories).font(.system(size: 10)).foregroundColor(.axTextMuted)
                            TextField("/var/www:/tmp:/usr/share/php", text: $openBasedir)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 11, design: .monospaced))
                                .padding(AXSpacing.sm)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, AXSpacing.lg).padding(.bottom, AXSpacing.md)
                    }
                }

                if !securityChecks.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        AXSectionTitle(title: "Security Checks", icon: "checklist")
                        ForEach(securityChecks.indices, id: \.self) { i in
                            let check = securityChecks[i]
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: checkIcon(check.status))
                                    .font(.system(size: 12))
                                    .foregroundColor(checkColor(check.status))
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(check.setting).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
                                    Text(check.message).font(.system(size: 10)).foregroundColor(.axTextSecondary)
                                }
                                Spacer()
                            }
                            .padding(AXSpacing.sm)
                            .background(Color.axSurface.opacity(0.2))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }

                Button {
                    Task { await saveSecurity() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isSaving { ProgressView().scaleEffect(0.65).frame(width: 14, height: 14) }
                        else { Image(systemName: "shield.checkered").font(.system(size: 12, weight: .semibold)) }
                        Text(L10n.Apps.applySecurityHardening).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AXSpacing.md)
                    .background(LinearGradient(colors: [.red, .red.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(AXCornerRadius.lg)
                    .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isSaving)

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    // MARK: - Security Row Builders

    private func secToggleRow(label: String, hint: String, isOn: Binding<Bool>, inverted: Bool) -> some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
                Text(hint).font(.system(size: 10)).foregroundColor(.axTextMuted)
            }
            Spacer()
            if inverted {
                HStack(spacing: 4) {
                    Circle().fill(isOn.wrappedValue ? Color.axWarning : Color.axSuccess).frame(width: 6, height: 6)
                    Text(isOn.wrappedValue ? "On" : "Off").font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isOn.wrappedValue ? .axWarning : .axSuccess)
                }
            }
            Toggle("", isOn: isOn).toggleStyle(.switch).scaleEffect(0.85).labelsHidden()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func accentCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.15)).frame(width: 28, height: 28)
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
                }
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.axTextPrimary)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md).background(color.opacity(0.05))
            Divider().background(color.opacity(0.2))
            content()
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(color.opacity(0.18), lineWidth: 1))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .frame(width: 3).padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    private func scoreColor(_ s: Int) -> Color { s >= 80 ? .axSuccess : (s >= 50 ? .orange : .axError) }
    private func checkIcon(_ s: String) -> String {
        switch s { case "OK": return "checkmark.circle.fill"; case "WARN": return "exclamationmark.triangle.fill"; case "FAIL": return "xmark.circle.fill"; default: return "minus.circle.fill" }
    }
    private func checkColor(_ s: String) -> Color {
        switch s { case "OK": return .axSuccess; case "WARN": return .orange; case "FAIL": return .axError; default: return .axTextMuted }
    }

    // MARK: - Data Loading & Saving

    private func loadSecurity() async {
        isLoading = true
        let json = await bridge.getSecurity(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {
            if let h = info["headers"] as? [String: Any] {
                exposePhp = (h["server_tokens"] as? String) == "on"
            }
            if let raw = info["raw"] as? [String: String] {
                exposePhp = raw["expose_php"] == "1" || (raw["expose_php"] ?? "").lowercased() == "on"
                displayErrors = raw["display_errors"] == "1" || (raw["display_errors"] ?? "").lowercased() == "on"
                allowUrlFopen = raw["allow_url_fopen"] == "1" || (raw["allow_url_fopen"] ?? "").lowercased() == "on"
                allowUrlInclude = raw["allow_url_include"] == "1" || (raw["allow_url_include"] ?? "").lowercased() == "on"
                openBasedir = raw["open_basedir"] ?? ""
                disableFunctions = raw["disable_functions"] ?? ""
                cookieHttponly = raw["session.cookie_httponly"] == "1"
                cookieSecure = raw["session.cookie_secure"] == "1"
                useStrictMode = raw["session.use_strict_mode"] == "1"
                cgiFixPathinfo = raw["cgi.fix_pathinfo"] == "1"
            }
            if let checks = info["checks"] as? [[String: String]] {
                securityChecks = checks.compactMap { c in
                    guard let st = c["status"], let se = c["setting"], let msg = c["message"] else { return nil }
                    return (status: st, setting: se, message: msg)
                }
            }
            if let sc = info["score"] as? Int { securityScore = sc }
        }
        isLoading = false
    }

    private func saveSecurity() async {
        isSaving = true
        let headers: [String: Any] = [
            "server_tokens": exposePhp ? "on" : "off",
            "hsts": false, "x_frame_options": "",
            "x_content_type_options": true, "referrer_policy": "",
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: headers),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode security settings")
            isSaving = false
            return
        }
        let result = await bridge.saveSecurityHeaders(serverID: serverId, appID: "php-fpm", headersJSON: jsonStr)
        if let data = result.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("Security hardening applied — php.ini updated")
            await loadSecurity()
        } else {
            toast.showError("Failed to apply security settings")
        }
        isSaving = false
    }
}
