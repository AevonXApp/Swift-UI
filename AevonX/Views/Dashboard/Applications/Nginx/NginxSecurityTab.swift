
import SwiftUI
import AevonXCore

@MainActor
public struct NginxSecurityTab: View {
    let application: ApplicationInstance
    @Binding var nginxConfig: NginxConfigData
    let onBlock: (String) async -> Void
    let onUnblock: (String) async -> Void

    @State private var newIPToBlock: String = ""
    @State private var isBlocking = false

    public init(application: ApplicationInstance, nginxConfig: Binding<NginxConfigData>, onBlock: @escaping (String) async -> Void, onUnblock: @escaping (String) async -> Void) {
        self.application = application
        self._nginxConfig = nginxConfig
        self.onBlock = onBlock
        self.onUnblock = onUnblock
    }

    public var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Block New IP
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Firewall Control")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("Block specific IP addresses from accessing your server")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }

                    HStack(spacing: AXSpacing.md) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(.axTextTertiary)
                            TextField("IP Address (e.g. 1.2.3.4)", text: $newIPToBlock)
                                .textFieldStyle(.plain)
                        }
                        .padding(AXSpacing.md)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                        )

                        Button(action: {
                            Task {
                                isBlocking = true
                                await onBlock(newIPToBlock)
                                newIPToBlock = ""
                                isBlocking = false
                            }
                        }) {
                            HStack {
                                if isBlocking {
                                    ProgressView().controlSize(.small)
                                }
                                Text("Block IP")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(isBlocking || newIPToBlock.isEmpty)
                    }
                }
            }

            // Blocked IPs List
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("RESTRICTED ACCESS (\(nginxConfig.blockedIPs.count))")
                    .font(AXTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextTertiary)
                    .padding(.horizontal, AXSpacing.sm)

                if nginxConfig.blockedIPs.isEmpty {
                    AXCard {
                        HStack {
                            Spacer()
                            VStack(spacing: AXSpacing.sm) {
                                Image(systemName: "checkmark.shield")
                                    .font(.system(size: 32))
                                    .foregroundColor(.axSuccess.opacity(0.5))
                                Text("No IPs are currently blocked")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(AXSpacing.xl)
                    }
                } else {
                    LazyVStack(spacing: AXSpacing.md) {
                        ForEach(nginxConfig.blockedIPs, id: \.self) { ip in
                            AXCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ip)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.axTextPrimary)
                                        Text("Manual Restriction")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Revoke") {
                                        Task { await onUnblock(ip) }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
