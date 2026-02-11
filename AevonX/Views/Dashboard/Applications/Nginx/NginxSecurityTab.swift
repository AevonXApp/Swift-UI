
import SwiftUI
import AevonXCore

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
        VStack(spacing: 0) {
            // Block New IP
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Firewall Control")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("Block specific IP addresses from accessing your server")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }

                    VStack(spacing: AXSpacing.md) {
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
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))

                            TextField("Reason (Optional)", text: $blockReason)
                                .padding(AXSpacing.md)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                        }

                        HStack(spacing: AXSpacing.md) {
                            HStack {
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
                            .padding(.vertical, 4)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))

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
                                HStack {
                                    if isBlocking {
                                        ProgressView().controlSize(.small)
                                    }
                                    Text("Block IP")
                                }
                                .padding(.horizontal, AXSpacing.md)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(isBlocking || newIPToBlock.isEmpty)
                        }
                    }
                }
            }
            .padding(.bottom, AXSpacing.md)

            // Blocked IPs List Section
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                // Header (Single Row)
                Text("RESTRICTED ACCESS (\(filteredIPs.count))")
                    .font(AXTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextTertiary)
                    .padding(.horizontal, AXSpacing.sm)
                
                HStack(spacing: AXSpacing.md) {
                    Picker("Date Filter", selection: $selectedFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .controlSize(.small)
                    
                    Spacer()
                    
                    // Compact Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextTertiary)
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(AXTypography.subheadline)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, 6)
                    .frame(width: 180)
                    .background(Color.axBackground.opacity(0.5))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                }
                .padding(.horizontal, AXSpacing.sm)

                // The List directly follows
                VStack(spacing: 4) {
                    if nginxConfig.blockedIPs.isEmpty && !isBlocking {
                        NoBlocksView()
                    } else {
                        ForEach(filteredIPs) { item in
                            BlockedIPRow(item: item, onUnblock: onUnblock)
                        }
                        
                        if !searchText.isEmpty && filteredIPs.isEmpty {
                            Text("No results matching '\(searchText)'")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .padding(AXSpacing.xl)
                                .frame(maxWidth: .infinity)
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
    }
}

private struct BlockedIPRow: View {
    let item: AXBlockedIP
    let onUnblock: (String) async -> Void
    
    var body: some View {
        AXCard(padding: 12) { // Tighter padding
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AXSpacing.sm) {
                        Text(item.ip)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(item.duration ?? "Permanent")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axError.opacity(0.1))
                            .foregroundColor(.axError)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: AXSpacing.md) {
                        Label(item.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        if let reason = item.reason, !reason.isEmpty {
                            Label(reason, systemImage: "info.circle")
                        }
                    }
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                }
                
                Spacer()
                
                Button("Revoke") {
                    Task { await onUnblock(item.ip) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
