
import SwiftUI
import AevonXCoreBridge

struct DockerSecurityAuditView: View {
    let container: DockerContainer
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var audit: SecurityAudit?
    @State private var vulnScan: VulnerabilityScan?
    @State private var isLoadingAudit = true
    @State private var isLoadingScan = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Docker.securityAudit)
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)
                    Text(container.names)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Divider()
            
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    if isLoadingAudit {
                        ProgressView("Running security audit...")
                            .padding(30)
                    } else if let audit = audit {
                        // Score Card
                        AXCard {
                            HStack(spacing: AXSpacing.md) {
                                // Grade circle
                                ZStack {
                                    Circle()
                                        .stroke(gradeColor(audit.grade).opacity(0.2), lineWidth: 6)
                                        .frame(width: 60, height: 60)
                                    Circle()
                                        .trim(from: 0, to: Double(audit.securityScore) / 100.0)
                                        .stroke(gradeColor(audit.grade), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                        .frame(width: 60, height: 60)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(spacing: 0) {
                                        Text(audit.grade)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(gradeColor(audit.grade))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Security Score: \(audit.securityScore)/100")
                                        .font(AXTypography.headline)
                                        .foregroundColor(.axTextPrimary)
                                    Text("\(audit.findings.count) finding(s)")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Findings
                        if !audit.findings.isEmpty {
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text(L10n.Docker.findings)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                ForEach(Array(audit.findings.enumerated()), id: \.offset) { _, finding in
                                    AXCard {
                                        HStack(alignment: .top, spacing: AXSpacing.sm) {
                                            Image(systemName: findingIcon(finding.severity))
                                                .foregroundColor(findingColor(finding.severity))
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(finding.title)
                                                    .font(AXTypography.body)
                                                    .foregroundColor(.axTextPrimary)
                                                    .fontWeight(.medium)
                                                Text(finding.description)
                                                    .font(AXTypography.caption)
                                                    .foregroundColor(.axTextSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(finding.severity.uppercased())
                                                .font(AXTypography.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(findingColor(finding.severity))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(findingColor(finding.severity).opacity(0.15))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Vulnerability Scan
                    AXCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Image Vulnerability Scan", systemImage: "shield.lefthalf.filled")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                if vulnScan == nil {
                                    Button {
                                        runVulnScan()
                                    } label: {
                                        if isLoadingScan {
                                            ProgressView().scaleEffect(0.6)
                                        } else {
                                            Label("Scan", systemImage: "magnifyingglass")
                                                .font(AXTypography.caption)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.axAccentBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .disabled(isLoadingScan)
                                }
                            }
                            
                            if let scan = vulnScan {
                                HStack(spacing: AXSpacing.md) {
                                    scanBadge("Critical", count: scan.critical, color: .red)
                                    scanBadge("High", count: scan.high, color: .orange)
                                    scanBadge("Medium", count: scan.medium, color: .yellow)
                                    scanBadge("Low", count: scan.low, color: .green)
                                }
                                
                                Text("Scanner: \(scan.scanner)")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .background(Color.axBackground)
        .onAppear { runAudit() }
    }
    
    @ViewBuilder
    private func scanBadge(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(count > 0 ? color : .axTextMuted)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(count > 0 ? color.opacity(0.1) : Color.axSurface)
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return .green
        case "B": return .mint
        case "C": return .yellow
        case "D": return .orange
        default: return .red
        }
    }
    
    private func findingIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "warning": return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func findingColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
    
    private func runAudit() {
        Task {
            do {
                let result = try await DockerService.shared.auditContainerSecurity(
                    containerId: container.id, serverId: serverId
                )
                await MainActor.run {
                    audit = result
                    isLoadingAudit = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingAudit = false
                }
            }
        }
    }
    
    private func runVulnScan() {
        isLoadingScan = true
        Task {
            do {
                let result = try await DockerService.shared.scanImageVulnerabilities(
                    image: container.image, serverId: serverId
                )
                await MainActor.run {
                    vulnScan = result
                    isLoadingScan = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingScan = false
                }
            }
        }
    }
}
