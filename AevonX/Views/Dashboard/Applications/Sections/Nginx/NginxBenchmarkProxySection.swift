//
//  NginxBenchmarkProxySection.swift
//  AevonX
//
//  Benchmark tester + Reverse Proxy / Upstream Manager
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Benchmark

struct NginxBenchmarkSection: View {
    let serverId: String
    @State private var url = "http://localhost"
    @State private var requests: Double = 10
    @State private var concurrency: Double = 1
    @State private var result: BenchResult?
    @State private var isRunning = false
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    struct BenchResult {
        let url: String
        let requests: Int
        let concurrency: Int
        let rps: Double
        let meanMs: Double
        let failed: Int
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Config
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("TARGET").font(.system(size: 10, weight: .bold)).foregroundColor(.axTextMuted)
                    HStack {
                        Image(systemName: "link").foregroundColor(.axTextMuted)
                        TextField("http://localhost", text: $url)
                            .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced))
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))

                    HStack(spacing: AXSpacing.xl) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Requests: \(Int(requests))").font(.system(size: 11)).foregroundColor(.axTextSecondary)
                            Slider(value: $requests, in: 5...50, step: 5)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Concurrency: \(Int(concurrency))").font(.system(size: 11)).foregroundColor(.axTextSecondary)
                            Slider(value: $concurrency, in: 1...10, step: 1)
                        }
                    }

                    Button { Task { await runBenchmark() } } label: {
                        HStack(spacing: AXSpacing.sm) {
                            if isRunning { ProgressView().scaleEffect(0.7) } else { Image(systemName: "gauge.with.dots.needle.100percent") }
                            Text(isRunning ? "Running..." : "Run Benchmark")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, AXSpacing.xl).padding(.vertical, 10)
                        .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle()).disabled(isRunning || url.isEmpty)
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))

                // Results
                if let r = result {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("RESULTS").font(.system(size: 10, weight: .bold)).foregroundColor(.axTextMuted)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                            benchCard("Req/sec", value: String(format: "%.1f", r.rps), color: r.rps > 100 ? .green : r.rps > 10 ? .orange : .red, icon: "arrow.up.right")
                            benchCard("Mean Latency", value: String(format: "%.0fms", r.meanMs), color: r.meanMs < 100 ? .green : r.meanMs < 500 ? .orange : .red, icon: "clock")
                            benchCard("Failed", value: "\(r.failed)", color: r.failed == 0 ? .green : .red, icon: "xmark.circle")
                            benchCard("Requests", value: "\(r.requests)", color: .axAccentBlue, icon: "number.circle")
                            benchCard("Concurrency", value: "\(r.concurrency)", color: .purple, icon: "person.2")
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func benchCard(_ label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.axTextPrimary)
            Text(label).font(.system(size: 10)).foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity).padding(AXSpacing.lg)
        .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.2), lineWidth: 1))
    }

    private func runBenchmark() async {
        isRunning = true
        let json = await bridge.runBenchmark(serverID: serverId, appID: "nginx", url: url, requests: Int32(requests), concurrency: Int32(concurrency))
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let d = resp["data"] as? [String: Any] {
            result = BenchResult(
                url: d["url"] as? String ?? url,
                requests: d["requests"] as? Int ?? 0,
                concurrency: d["concurrency"] as? Int ?? 0,
                rps: d["requests_per_sec"] as? Double ?? 0,
                meanMs: d["mean_latency_ms"] as? Double ?? 0,
                failed: d["failed_requests"] as? Int ?? 0
            )
        } else { toast.showError("Benchmark failed") }
        isRunning = false
    }
}

// MARK: - Reverse Proxy / Upstreams

struct NginxProxySection: View {
    let serverId: String
    @State private var upstreams: [[String: Any]] = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newAlgo = "round_robin"
    @State private var newServers = "127.0.0.1:8080"
    @State private var isSaving = false
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Upstream Groups").font(.system(size: 13, weight: .bold)).foregroundColor(.axTextPrimary)
                Spacer()
                Button { showAddSheet = true } label: {
                    Label("Add Upstream", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md).padding(.vertical, 7)
                        .background(Color.axAccentBlue).cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            Divider()

            if isLoading {
                ProgressView("Loading...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if upstreams.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "arrow.triangle.branch").font(.system(size: 40)).foregroundColor(.axTextMuted)
                    Text("No upstream groups").font(.system(size: 13)).foregroundColor(.axTextSecondary)
                    Text("Add an upstream group to configure reverse proxy load balancing").font(.system(size: 11)).foregroundColor(.axTextMuted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.md) {
                        ForEach(upstreams.indices, id: \.self) { i in upstreamCard(upstreams[i]) }
                    }.padding(AXSpacing.xl)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) { addUpstreamSheet }
        .task { await loadUpstreams() }
    }

    private func upstreamCard(_ u: [String: Any]) -> some View {
        let name = u["name"] as? String ?? ""
        let algo = u["algorithm"] as? String ?? "round_robin"
        let servers = u["servers"] as? [[String: Any]] ?? []
        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Label(name, systemImage: "arrow.triangle.branch").font(.system(size: 13, weight: .bold)).foregroundColor(.axTextPrimary)
                Spacer()
                Text(algo.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.axAccentBlue.opacity(0.1)).cornerRadius(3)
            }
            ForEach(servers.indices, id: \.self) { j in
                let srv = servers[j]
                HStack(spacing: AXSpacing.sm) {
                    Circle().fill((srv["down"] as? Bool == true) ? Color.red : Color.green).frame(width: 7, height: 7)
                    Text(srv["address"] as? String ?? "").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextPrimary)
                    Text("w:\(srv["weight"] as? Int ?? 1)").font(.system(size: 9)).foregroundColor(.axTextMuted)
                    if srv["down"] as? Bool == true {
                        Text("DOWN").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                    }
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    private var addUpstreamSheet: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────────
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.axAccentBlue.opacity(0.25), Color.axAccentBlue.opacity(0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Upstream Group")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Configure reverse proxy load balancing")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
                Button {
                    showAddSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 24, height: 24)
                        .background(Color.axSurface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)

            Divider().background(Color.axBorder.opacity(0.3))

            // ── Form Fields ───────────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {

                    // Name field
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("Name", systemImage: "tag.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextMuted)
                        HStack {
                            TextField("backend", text: $newName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 9)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                    }

                    // Algorithm picker
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("Load Balancing Algorithm", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextMuted)
                        HStack(spacing: AXSpacing.sm) {
                            ForEach([("round_robin", "Round Robin", "arrow.clockwise"),
                                     ("least_conn", "Least Conn", "chart.bar.fill"),
                                     ("ip_hash", "IP Hash", "lock.fill")], id: \.0) { algo, label, icon in
                                let isSelected = newAlgo == algo
                                Button { newAlgo = algo } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: icon)
                                            .font(.system(size: 9, weight: .semibold))
                                        Text(label)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Color.axAccentBlue.opacity(0.12) : Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .stroke(isSelected ? Color.axAccentBlue.opacity(0.4) : Color.axBorder.opacity(0.2), lineWidth: 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Servers textarea
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("Servers", systemImage: "server.rack")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextMuted)
                        Text("One server per line: host:port")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted.opacity(0.7))
                        TextEditor(text: $newServers)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Color.axSurface)
                            .frame(height: 90)
                            .padding(AXSpacing.sm)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(AXSpacing.xl)
            }

            Divider().background(Color.axBorder.opacity(0.3))

            // ── Footer ────────────────────────────────────────────────
            HStack(spacing: AXSpacing.sm) {
                Button("Cancel") {
                    showAddSheet = false
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, 8)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))

                Spacer()

                Button {
                    Task { await saveUpstream() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isSaving {
                            ProgressView().scaleEffect(0.6).tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text("Save Upstream")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.7)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(AXCornerRadius.sm)
                    .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 6, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isSaving || newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 440, height: 520)
        .background(Color.axBackground)
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    private func loadUpstreams() async {
        isLoading = true
        let json = await bridge.listUpstreams(serverID: serverId, appID: "nginx")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = resp["data"] as? [[String: Any]] { upstreams = list }
        isLoading = false
    }

    private func saveUpstream() async {
        isSaving = true
        let serverList = newServers.split(separator: "\n").map { line -> [String: Any] in
            ["address": String(line).trimmingCharacters(in: .whitespaces), "weight": 1, "max_fails": 3, "down": false]
        }
        let payload: [String: Any] = ["name": newName, "algorithm": newAlgo, "servers": serverList]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonStr = String(data: jsonData, encoding: .utf8) else { isSaving = false; return }
        let result = await bridge.writeUpstream(serverID: serverId, appID: "nginx", upstreamJSON: jsonStr)
        if let data = result.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Upstream '\(newName)' saved")
            showAddSheet = false
            await loadUpstreams()
        } else { toast.showError("Failed to save upstream") }
        isSaving = false
    }
}
