//
//  FrameworksSection.swift
//  AevonX
//
//  Auto-detect Node.js frameworks and show framework-specific info.
//  Supports: Next.js, Express, NestJS, Nuxt, Remix, Fastify, Koa, AdonisJS
//

import SwiftUI
import AevonXCoreBridge

struct FrameworksSection: View {
    let serverId: String
    let appPath: String?

    @State private var frameworkInfo: NodeJSFrameworkService.FrameworkInfo?
    @State private var routes: [String] = []
    @State private var nextJSInfo: [String: String] = [:]
    @State private var scripts: [String: String] = [:]
    @State private var isLoading = true
    @State private var scriptOutput: String = ""
    @State private var showOutput = false
    @State private var runningScript: String?

    private let frameworkService = NodeJSFrameworkService()
    private let deployService = NodeJSDeployService()

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if isLoading {
                AXLoadingState(message: "Detecting framework…")
            } else if let fw = frameworkInfo, fw.framework != .unknown {
                frameworkBadge(fw)
                detailsCard(fw)
                scriptsCard
                if !routes.isEmpty { routesCard }
                if !nextJSInfo.isEmpty { nextJSCard }
                if showOutput { outputCard }
            } else {
                AXPlaceholder(
                    icon: "square.stack.3d.up.fill",
                    title: "No Framework Detected",
                    subtitle: "No recognized Node.js framework found in package.json"
                )
            }
        }
        .task { await loadData() }
    }

    // MARK: - Framework Badge

    private func frameworkBadge(_ fw: NodeJSFrameworkService.FrameworkInfo) -> some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: fw.framework.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(hex: fw.framework.color))

                VStack(alignment: .leading, spacing: 4) {
                    Text(fw.framework.rawValue)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.axTextPrimary)

                    HStack(spacing: AXSpacing.sm) {
                        if let version = fw.version {
                            Text("v\(version)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.axAccentBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.axAccentBlue.opacity(0.1))
                                .cornerRadius(4)
                        }

                        if fw.hasTypeScript {
                            HStack(spacing: 2) {
                                Image(systemName: "swift")
                                    .font(.system(size: 9))
                                Text("TypeScript")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#3178C6"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#3178C6").opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                // Port badge
                VStack(spacing: 2) {
                    Text("Port")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axTextMuted)
                    Text("\(fw.framework.defaultPort)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Details Card

    private func detailsCard(_ fw: NodeJSFrameworkService.FrameworkInfo) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("Framework Details")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                AXInfoRow(label: "Framework", value: fw.framework.rawValue,
                          valueColor: Color(hex: fw.framework.color))
                if let ver = fw.version {
                    AXInfoRow(label: "Version", value: ver, valueColor: .axAccentBlue)
                }
                if let nodeVer = fw.nodeVersion {
                    AXInfoRow(label: "Required Node", value: nodeVer)
                }
                AXInfoRow(label: "TypeScript", value: fw.hasTypeScript ? "Yes" : "No",
                          valueColor: fw.hasTypeScript ? .axSuccess : .axTextMuted)
                AXInfoRow(label: "Default Port", value: "\(fw.framework.defaultPort)")
            }
        }
    }

    // MARK: - Scripts Card

    private var scriptsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("NPM Scripts")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if scripts.isEmpty {
                    Text("No scripts found")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                } else {
                    ForEach(scripts.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.axAccentBlue)

                            Spacer()

                            Text(value)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                                .lineLimit(1)

                            Button {
                                Task { await runScript(key) }
                            } label: {
                                Image(systemName: runningScript == key ? "hourglass" : "play.circle.fill")
                                    .foregroundColor(.axSuccess)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .disabled(runningScript != nil)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Routes Card

    private var routesCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("Routes")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                ForEach(routes.prefix(20), id: \.self) { route in
                    Text(route)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                }
                if routes.count > 20 {
                    Text("+ \(routes.count - 20) more routes")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }
        }
    }

    // MARK: - Next.js Card

    private var nextJSCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("Next.js Details")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                ForEach(nextJSInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    AXInfoRow(label: key, value: value)
                }
            }
        }
    }

    // MARK: - Output Card

    private var outputCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    Text("Script Output")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    Button { showOutput = false; scriptOutput = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    Text(scriptOutput)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
            }
        }
    }

    // MARK: - Actions

    private func loadData() async {
        guard let path = appPath else { isLoading = false; return }
        isLoading = true
        do {
            frameworkInfo = try await frameworkService.detectFramework(projectPath: path, serverId: serverId)
            scripts = (try? await frameworkService.listScripts(path: path, serverId: serverId)) ?? [:]

            if let fw = frameworkInfo {
                switch fw.framework {
                case .nextjs:
                    nextJSInfo = (try? await frameworkService.getNextJSInfo(path: path, serverId: serverId)) ?? [:]
                case .express, .fastify, .koa:
                    routes = (try? await frameworkService.getExpressRoutes(path: path, serverId: serverId)) ?? []
                default:
                    break
                }
            }
        } catch {
            frameworkInfo = nil
        }
        isLoading = false
    }

    private func runScript(_ name: String) async {
        guard let path = appPath else { return }
        runningScript = name
        showOutput = true
        do {
            scriptOutput = try await deployService.runScript(path: path, script: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Script '\(name)' completed")
        } catch {
            scriptOutput = "Error: \(error.localizedDescription)"
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        runningScript = nil
    }
}
