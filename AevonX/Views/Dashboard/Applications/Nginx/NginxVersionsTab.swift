
import SwiftUI
import AevonXCore

@MainActor
public struct NginxVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String
    @State private var availableVersions: [String] = []
    @State private var isLoadingVersions = false
    @State private var installingVersion: String?

    let onInstall: (String) async -> Void
    let onSwitch: (String) async -> Void

    public init(application: ApplicationInstance, serverId: String, onInstall: @escaping (String) async -> Void, onSwitch: @escaping (String) async -> Void) {
        self.application = application
        self.serverId = serverId
        self.onInstall = onInstall
        self.onSwitch = onSwitch
    }

    public var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Current Version
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Current Version")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    HStack {
                        Text(application.version ?? "Unknown")
                            .font(AXTypography.title)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.axSuccess)
                    }
                }
            }

            // Available Versions
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Text("Available Versions")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        Button("Refresh") {
                            Task { await loadVersions() }
                        }
                        .buttonStyle(.bordered)
                    }

                    if isLoadingVersions {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if availableVersions.isEmpty {
                        Text("No versions available")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    } else {
                        ForEach(availableVersions, id: \.self) { version in
                            HStack {
                                Text(version)
                                    .font(AXTypography.body)

                                Spacer()

                                if version == application.version {
                                    Text("Current")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axSuccess)
                                } else if installingVersion == version {
                                    ProgressView()
                                } else {
                                    Button("Switch") {
                                        Task {
                                            installingVersion = version
                                            await onSwitch(version)
                                            installingVersion = nil
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadVersions()
        }
    }

    private func loadVersions() async {
        isLoadingVersions = true
        do {
            let versions = try await ApplicationManager.shared.getAvailableVersions(type: .nginx, serverId: serverId)
            await MainActor.run {
                self.availableVersions = versions
                self.isLoadingVersions = false
            }
        } catch {
            await MainActor.run {
                self.availableVersions = []
                self.isLoadingVersions = false
            }
        }
    }
}
