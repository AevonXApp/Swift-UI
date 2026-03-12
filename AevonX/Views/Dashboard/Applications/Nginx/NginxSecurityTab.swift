
import SwiftUI
import AevonXCoreBridge

@MainActor
public struct NginxSecurityTab: View {
    let application: ApplicationInstance
    @Binding var nginxConfig: NginxConfigData
    let onBlock: (String, String?, String?) async -> Void
    let onUnblock: (String) async -> Void

    @State private var newIPToBlock: String = ""
    @State private var blockReason: String = ""
    @State private var blockDuration: String = "Permanent"
    @State private var isBlocking = false
    @State private var searchText = ""
    @State private var selectedFilter: DateFilter = .all

    enum DateFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }

    public init(application: ApplicationInstance, nginxConfig: Binding<NginxConfigData>, onBlock: @escaping (String, String?, String?) async -> Void, onUnblock: @escaping (String) async -> Void) {
        self.application = application
        self._nginxConfig = nginxConfig
        self.onBlock = onBlock
        self.onUnblock = onUnblock
    }

    var filteredIPs: [AXBlockedIP] {
        nginxConfig.blockedIPs.filter { item in
            let matchesSearch = searchText.isEmpty || item.ip.contains(searchText) || (item.reason ?? "").contains(searchText)
            
            let calendar = Calendar.current
            let matchesDate: Bool
            switch selectedFilter {
            case .all: matchesDate = true
            case .today: matchesDate = calendar.isDateInToday(item.date)
            case .week: matchesDate = calendar.isDate(item.date, equalTo: Date(), toGranularity: .weekOfYear)
            case .month: matchesDate = calendar.isDate(item.date, equalTo: Date(), toGranularity: .month)
            }
            
            return matchesSearch && matchesDate
        }
    }

    public var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Block New IP Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Firewall Control")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("Block specific IP addresses from accessing your server")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }

                    HStack(spacing: AXSpacing.md) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextTertiary)
                            TextField("IP Address (e.g. 1.2.3.4)", text: $newIPToBlock)
                                .textFieldStyle(.plain)
                        }
                        .padding(AXSpacing.md)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))

                        TextField("Reason (Optional)", text: $blockReason)
                            .padding(AXSpacing.md)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                    }

                    HStack(spacing: AXSpacing.md) {
                        HStack(spacing: AXSpacing.sm) {
                            Text("Duration:")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            Picker("Duration", selection: $blockDuration) {
                                Text("Permanent").tag("Permanent")
                                Text("24 Hours").tag("24h")
                                Text("7 Days").tag("7d")
                                Text("30 Days").tag("30d")
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 6)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))

                        Spacer()

                        Button(action: {
                            Task {
                                isBlocking = true
                                await onBlock(newIPToBlock, blockReason, blockDuration)
                                newIPToBlock = ""
                                blockReason = ""
                                isBlocking = false
                            }
                        }) {
                            HStack(spacing: AXSpacing.sm) {
                                if isBlocking {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                }
                                Text("Block IP")
                            }
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axError)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                        .disabled(isBlocking || newIPToBlock.isEmpty)
                        .opacity((isBlocking || newIPToBlock.isEmpty) ? 0.5 : 1)
                    }
                }
            }

            // Blocked IPs Section
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: AXSpacing.md) {
                    Text("RESTRICTED ACCESS (\(filteredIPs.count))")
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                    
                    Picker("", selection: $selectedFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                    .controlSize(.small)
                    
                    // Compact Search Bar
                    AXSearchBar(text: $searchText, placeholder: "Search...")
                        .frame(width: 200)
                }
                .padding(.bottom, AXSpacing.md)

                // IP List
                if nginxConfig.blockedIPs.isEmpty && !isBlocking {
                    NoBlocksView()
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(filteredIPs) { item in
                            BlockedIPRow(item: item, onUnblock: onUnblock)
                        }
                        
                        if !searchText.isEmpty && filteredIPs.isEmpty {
                            AXCard {
                                Text("No results matching '\(searchText)'")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                                    .padding(AXSpacing.lg)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct NoBlocksView: View {
    var body: some View {
        AXCard {
            VStack(spacing: AXSpacing.md) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 36))
                    .foregroundColor(.axSuccess.opacity(0.5))
                Text("No blocked IPs")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                Text("Block IP addresses to prevent them from accessing your server")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.xl)
        }
    }
}

private struct BlockedIPRow: View {
    let item: AXBlockedIP
    let onUnblock: (String) async -> Void
    
    var body: some View {
        AXCard(padding: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AXSpacing.sm) {
                        Text(item.ip)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(item.duration ?? "Permanent")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axError.opacity(0.1))
                            .foregroundColor(.axError)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    HStack(spacing: AXSpacing.md) {
                        Label {
                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        } icon: {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                        }
                        
                        if let reason = item.reason, !reason.isEmpty {
                            Label {
                                Text(reason)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                }
                
                Spacer()
                
                Button(action: {
                    Task { await onUnblock(item.ip) }
                }) {
                    Text("Revoke")
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 6)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
