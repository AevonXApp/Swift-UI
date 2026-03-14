
import SwiftUI
import AevonXCoreBridge

// MARK: - Docker Security Tab

struct DockerSecurityTab: View {
    let serverId: String
    
    @State private var containers: [DockerContainer] = []
    @State private var auditResults: [String: SecurityAuditResult] = [:]  // containerId -> result
    @State private var isLoading = true
    @State private var scanningId: String?
    @State private var expandedId: String?
    @State private var vulnReport: String?
    @State private var vulnScanning: String?
    
    struct SecurityAuditResult {
        let score: Int
        let grade: String
        let findings: [(String, String)]  // (severity, message)
    }
    
    private var overallScore: Int {
        guard !auditResults.isEmpty else { return 0 }
        let total = auditResults.values.reduce(0) { $0 + $1.score }
        return total / auditResults.count
    }
    
    private var overallGrade: String {
        let s = overallScore
        if s >= 90 { return "A" }
        if s >= 75 { return "B" }
        if s >= 60 { return "C" }
        if s >= 40 { return "D" }
        return "F"
    }
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return .axSuccess
        case "B": return .axAccentBlue
        case "C": return .axWarning
        case "D": return .orange
        default: return .axError
        }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if isLoading {
                VStack(spacing: AXSpacing.lg) {
                    ProgressView().scaleEffect(1.2)
                    Text("Loading containers...")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
            } else {
                // Overall Score Banner
                if !auditResults.isEmpty {
                    overallBanner
                }
                
                // Scan All button
                HStack {
                    Text("Container Security")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    
                    Text("\(containers.count) containers")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                    
                    Button {
                        scanAll()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Scan All")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                
                // Container cards
                ForEach(containers, id: \.id) { container in
                    containerSecurityCard(container)
                }
            }
        }
        .onAppear { loadContainers() }
    }
    
    // MARK: - Overall Banner
    
    private var overallBanner: some View {
        HStack(spacing: AXSpacing.xl) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.axBorder.opacity(0.3), lineWidth: 8)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: CGFloat(overallScore) / 100.0)
                    .stroke(gradeColor(overallGrade), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(overallGrade)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(gradeColor(overallGrade))
                    Text("\(overallScore)%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Security Score")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text("\(auditResults.count) of \(containers.count) containers scanned")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            // Severity summary
            HStack(spacing: AXSpacing.md) {
                let allFindings = auditResults.values.flatMap(\.findings)
                let critical = allFindings.filter { $0.0 == "critical" || $0.0 == "high" }.count
                let medium = allFindings.filter { $0.0 == "medium" }.count
                let low = allFindings.filter { $0.0 == "low" || $0.0 == "info" }.count
                
                severityBadge("Critical", critical, .axError)
                severityBadge("Medium", medium, .axWarning)
                severityBadge("Low", low, .axTextTertiary)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(gradeColor(overallGrade).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func severityBadge(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextSecondary)
        }
        .frame(width: 60)
    }
    
    // MARK: - Container Card
    
    private func containerSecurityCard(_ container: DockerContainer) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(container.isRunning ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 8, height: 8)
                
                Text(container.names)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                
                Text(container.image)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextTertiary)
                
                Spacer()
                
                if let result = auditResults[container.id] {
                    // Score badge (clickable to expand)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedId = expandedId == container.id ? nil : container.id
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(result.grade)
                                .font(.system(size: 12, weight: .black))
                            Text("\(result.score)%")
                                .font(.system(size: 11, weight: .medium))
                            
                            Image(systemName: expandedId == container.id ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(gradeColor(result.grade))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(gradeColor(result.grade).opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                    
                    // Findings count badge
                    if !result.findings.isEmpty {
                        Text("\(result.findings.count) findings")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.axTextTertiary)
                    }
                }
                
                if scanningId == container.id {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button {
                        scanContainer(container)
                    } label: {
                        Text("Scan")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AXSpacing.md)
            
            // Expanded findings
            if expandedId == container.id, let result = auditResults[container.id] {
                expandedFindings(container: container, result: result)
            }
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func expandedFindings(container: DockerContainer, result: SecurityAuditResult) -> some View {
        Rectangle()
            .fill(Color.axBorder.opacity(0.2))
            .frame(height: 1)
        
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Findings header with severity summary
            findingsHeader(result: result)
            
            // Finding cards
            ForEach(Array(result.findings.enumerated()), id: \.offset) { _, finding in
                findingCard(severity: finding.0, message: finding.1)
            }
            
            // Vulnerability scan section
            Rectangle()
                .fill(Color.axBorder.opacity(0.2))
                .frame(height: 1)
                .padding(.vertical, 2)
            
            vulnScanButton(container: container)
            
            // Vulnerability report
            if let report = vulnReport, expandedId == container.id {
                vulnReportView(report: report)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axBackground.opacity(0.6))
    }
    
    private func findingsHeader(result: SecurityAuditResult) -> some View {
        let criticalCount = result.findings.filter { $0.0.lowercased() == "critical" || $0.0.lowercased() == "high" }.count
        let warnCount = result.findings.filter { $0.0.lowercased() == "warning" || $0.0.lowercased() == "medium" }.count
        let infoCount = result.findings.filter { $0.0.lowercased() == "info" || $0.0.lowercased() == "low" }.count
        
        return HStack(spacing: AXSpacing.md) {
            Text("Security Findings")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            if criticalCount > 0 { severityPill("CRITICAL", criticalCount, .axError) }
            if warnCount > 0 { severityPill("WARNING", warnCount, .axWarning) }
            if infoCount > 0 { severityPill("INFO", infoCount, .axAccentBlue) }
            
            Spacer()
        }
    }
    
    private func vulnScanButton(container: DockerContainer) -> some View {
        HStack(spacing: AXSpacing.md) {
            Button {
                scanVulnerabilities(container)
            } label: {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 28, height: 28)
                        if vulnScanning == container.id {
                            ProgressView().scaleEffect(0.5)
                        } else {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Scan Image Vulnerabilities")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.purple)
                        Text("Deep scan for known CVEs in \(container.image)")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(vulnScanning == container.id)
            
            Spacer()
        }
    }
    
    private func vulnReportView(report: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Vulnerability Report")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
            }
            
            ScrollView {
                Text(report)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding(10)
            .background(Color.black.opacity(0.25))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    private func findingColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical", "high": return .axError
        case "warning", "medium": return .axWarning
        case "low": return .axAccentBlue
        default: return .axTextTertiary
        }
    }
    
    private func findingIcon(_ severity: String) -> String {
        switch severity.lowercased() {
        case "critical", "high": return "exclamationmark.triangle.fill"
        case "warning", "medium": return "exclamationmark.circle.fill"
        case "low": return "info.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func severityPill(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func findingCard(severity: String, message: String) -> some View {
        let color = findingColor(severity)
        let icon = findingIcon(severity)
        // Split message at first ": " to get title and description
        let parts = message.components(separatedBy: ": ")
        let title = parts.first ?? message
        let desc = parts.count > 1 ? parts.dropFirst().joined(separator: ": ") : ""
        
        return HStack(alignment: .top, spacing: AXSpacing.sm) {
            // Severity icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    // Severity badge
                    Text(severity.uppercased())
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.12))
                        .cornerRadius(4)
                    
                    // Title
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                }
                
                if !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Actions
    
    private func loadContainers() {
        Task {
            do {
                let c = try await DockerService.shared.getContainers(serverId: serverId, all: false)
                await MainActor.run { containers = c; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func scanContainer(_ container: DockerContainer) {
        scanningId = container.id
        Task {
            do {
                let result = try await DockerService.shared.auditContainerSecurity(containerId: container.id, serverId: serverId)
                await MainActor.run {
                    auditResults[container.id] = SecurityAuditResult(
                        score: result.securityScore,
                        grade: result.grade,
                        findings: result.findings.map { ($0.severity, "\($0.title): \($0.description)") }
                    )
                    scanningId = nil
                    // Auto-expand to show findings immediately
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedId = container.id
                    }
                }
            } catch {
                await MainActor.run { scanningId = nil }
            }
        }
    }
    
    private func scanVulnerabilities(_ container: DockerContainer) {
        vulnScanning = container.id
        vulnReport = nil
        Task {
            do {
                let scan = try await DockerService.shared.scanImageVulnerabilities(image: container.image, serverId: serverId)
                await MainActor.run {
                    vulnReport = "\(scan.scanner): \(scan.summary)\n\n\(scan.rawOutput)"
                    vulnScanning = nil
                }
            } catch {
                await MainActor.run {
                    vulnReport = "Scan failed: \(error.localizedDescription)"
                    vulnScanning = nil
                }
            }
        }
    }
    
    private func scanAll() {
        for container in containers {
            if auditResults[container.id] == nil {
                scanContainer(container)
            }
        }
    }
}
