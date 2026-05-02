//
//  EngineMigrationSection.swift
//  AevonX
//
//  Migrate a website from one web server engine to another (nginx/apache/OLS).
//

import SwiftUI
import AevonXCoreBridge

struct EngineMigrationSection: View {
    let website: WebsiteInfo
    let installedEngines: Set<String>
    let serverId: String
    let serverPaths: ServerPaths

    @State private var targetEngine = ""
    @State private var isMigrating = false
    @State private var migrationStatus = ""
    @State private var migrationComplete = false
    @State private var migrationFailed = false
    @State private var showConfirmation = false
    @State private var currentStep = 0
    @State private var totalSteps = 0

    private var currentEngine: String {
        website.webServerEngine ?? "nginx"
    }

    private var availableTargets: [String] {
        installedEngines
            .filter { $0 != currentEngine }
            .sorted()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                if availableTargets.isEmpty {
                    singleEngineView
                } else {
                    migrationContent
                }
            }
            .padding(AXSpacing.xl)
        }
        .alert("Confirm Engine Migration", isPresented: $showConfirmation) {
            Button(L10n.Button.cancel, role: .cancel) {}
            Button("Migrate", role: .destructive) {
                Task { await performMigration() }
            }
        } message: {
            Text("Migrate \(website.domain) from \(engineDisplayName(currentEngine)) to \(engineDisplayName(targetEngine))?\n\nThe source config will be disabled but not deleted. You can rollback if needed.")
        }
    }

    // MARK: - Single Engine

    private var singleEngineView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.axTextMuted.opacity(0.4))
                .padding(.top, AXSpacing.xxxl)

            Text(L10n.Websites.engineMigrationUnavailable)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.axTextSecondary)

            Text(L10n.Websites.onlyOneWebServerEngineIsInstalledOnThisServerInstallAnotherEngineNginxApacheOrOpenlitespeedToEnableMigration)
                .font(AXTypography.footnote)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }

    // MARK: - Migration Content

    private var migrationContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Current engine status
            currentEngineCard

            // Migration flow
            migrationFlowCard

            // Status
            if migrationComplete {
                statusCard(
                    icon: "checkmark.circle.fill",
                    color: .axSuccess,
                    title: "Migration Complete",
                    message: "\(website.domain) is now served by \(engineDisplayName(targetEngine)). The previous \(engineDisplayName(currentEngine)) config has been disabled."
                )
            }

            if migrationFailed {
                statusCard(
                    icon: "exclamationmark.triangle.fill",
                    color: .axError,
                    title: "Migration Failed",
                    message: migrationStatus.isEmpty ? "An error occurred during migration. The source configuration was not removed." : migrationStatus
                )
            }
        }
    }

    private var currentEngineCard: some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [engineColor(currentEngine).opacity(0.2), engineColor(currentEngine).opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: engineIcon(currentEngine))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(engineColor(currentEngine))
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Websites.currentEngine)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.axTextMuted)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(engineDisplayName(currentEngine))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                Text(website.domain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            // Active indicator
            HStack(spacing: AXSpacing.xxs) {
                Circle()
                    .fill(Color.axSuccess)
                    .frame(width: 6, height: 6)
                Text(L10n.Status.active)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axSuccess)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs)
            .background(
                Capsule()
                    .fill(Color.axSuccess.opacity(0.1))
            )
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .stroke(engineColor(currentEngine).opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var migrationFlowCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header
            HStack {
                Text(L10n.Websites.migrateTo)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Spacer()

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextMuted)
            }

            // Target engine options
            VStack(spacing: AXSpacing.sm) {
                ForEach(availableTargets, id: \.self) { engine in
                    targetEngineOption(engine)
                }
            }

            // Migration button or progress
            if isMigrating {
                migrationProgressView
            } else if !targetEngine.isEmpty {
                migrateActionButton
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .stroke(Color.axBorder.opacity(0.3), lineWidth: 0.5)
                )
        )
        .onAppear {
            if targetEngine.isEmpty, let first = availableTargets.first {
                targetEngine = first
            }
        }
    }

    private func targetEngineOption(_ engine: String) -> some View {
        let isSelected = targetEngine == engine

        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                targetEngine = engine
            }
        }) {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(isSelected ? engineColor(engine).opacity(0.15) : Color.axSurface.opacity(0.5))
                        .frame(width: 38, height: 38)

                    Image(systemName: engineIcon(engine))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? engineColor(engine) : .axTextMuted)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(engineDisplayName(engine))
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                    Text(engineSubtitle(engine))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? engineColor(engine) : Color.axBorder, lineWidth: isSelected ? 2 : 1)
                        .frame(width: 18, height: 18)

                    if isSelected {
                        Circle()
                            .fill(engineColor(engine))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(isSelected ? engineColor(engine).opacity(0.04) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(isSelected ? engineColor(engine).opacity(0.2) : Color.axBorder.opacity(0.2), lineWidth: isSelected ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var migrateActionButton: some View {
        Button(action: { showConfirmation = true }) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))

                Text("Migrate to \(engineDisplayName(targetEngine))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [engineColor(targetEngine), engineColor(targetEngine).opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: engineColor(targetEngine).opacity(0.3), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(targetEngine.isEmpty)
    }

    private var migrationProgressView: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(engineColor(targetEngine))

                Text(migrationStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextSecondary)

                Spacer()

                if totalSteps > 0 {
                    Text("\(currentStep)/\(totalSteps)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(engineColor(targetEngine))
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(
                            Capsule().fill(engineColor(targetEngine).opacity(0.1))
                        )
                }
            }

            if totalSteps > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.axSurface)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(engineColor(targetEngine))
                            .frame(width: geo.size.width * (Double(currentStep) / Double(totalSteps)), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(engineColor(targetEngine).opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(engineColor(targetEngine).opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private func statusCard(icon: String, color: Color, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                Text(message)
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(color.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Migration Logic

    private func performMigration() async {
        isMigrating = true
        migrationComplete = false
        migrationFailed = false
        migrationStatus = "Preparing migration..."
        currentStep = 0
        totalSteps = 0

        let bridge = WebsitesBridge.shared
        let docRoot = website.documentRoot ?? "\(serverPaths.webRoot)/\(website.domain)"

        guard let pathsData = try? JSONEncoder().encode(serverPaths),
              let pathsJSON = String(data: pathsData, encoding: .utf8) else {
            migrationStatus = "Failed to encode server paths"
            migrationFailed = true
            isMigrating = false
            return
        }

        let resultJSON = bridge.migrateSiteCmds(
            sourceEngine: currentEngine,
            targetEngine: targetEngine,
            domain: website.domain,
            docRoot: docRoot,
            pathsJSON: pathsJSON
        )

        guard let data = resultJSON.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              resp["success"] as? Bool == true,
              let migrationData = resp["data"] as? [String: Any],
              let preflightCmds = migrationData["preflight_cmds"] as? [String],
              let migrationCmds = migrationData["migration_cmds"] as? [String] else {
            migrationStatus = "Failed to generate migration commands"
            migrationFailed = true
            isMigrating = false
            return
        }

        totalSteps = preflightCmds.count + migrationCmds.count

        // Execute preflight
        migrationStatus = "Running preflight checks..."
        for cmd in preflightCmds {
            let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            currentStep += 1
            if output.contains("AEVON_MIGRATE_ERROR") {
                migrationStatus = output
                migrationFailed = true
                isMigrating = false
                return
            }
        }

        // Execute migration
        migrationStatus = "Migrating site configuration..."
        for (i, cmd) in migrationCmds.enumerated() {
            migrationStatus = "Applying changes (\(i + 1)/\(migrationCmds.count))..."
            let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            currentStep += 1
            if output.contains("AEVON_MIGRATE_ERROR") {
                migrationStatus = output
                migrationFailed = true
                isMigrating = false
                return
            }
        }

        migrationStatus = "Migration successful"
        migrationComplete = true
        isMigrating = false
    }

    // MARK: - Engine Helpers

    private func engineIcon(_ engine: String) -> String {
        switch engine {
        case "apache": return "flame.fill"
        case "openlitespeed": return "bolt.horizontal.fill"
        default: return "bolt.fill"
        }
    }

    private func engineDisplayName(_ engine: String) -> String {
        switch engine {
        case "apache": return "Apache"
        case "openlitespeed": return "OpenLiteSpeed"
        default: return "Nginx"
        }
    }

    private func engineColor(_ engine: String) -> Color {
        switch engine {
        case "apache": return .orange
        case "openlitespeed": return Color(red: 1.0, green: 0.416, blue: 0.0)
        default: return .blue
        }
    }

    private func engineSubtitle(_ engine: String) -> String {
        switch engine {
        case "apache": return "Traditional, .htaccess support"
        case "openlitespeed": return "High performance, LSCache"
        default: return "Fast, lightweight, reverse proxy"
        }
    }
}
