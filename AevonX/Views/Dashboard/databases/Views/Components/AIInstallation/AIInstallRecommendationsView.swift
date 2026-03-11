//
//  AIInstallRecommendationsView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct AIInstallRecommendationsView: View {
    let databaseType: DatabaseType
    let recommendation: AIInstallationResponse
    let selectedVersion: DatabaseVersionRecommendation?
    let isInstalling: Bool
    var onSelectVersion: (DatabaseVersionRecommendation) -> Void
    var onStartInstall: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // System Requirements
                systemRequirementsSection(recommendation.systemRequirements)
                
                // Version Recommendations
                versionRecommendationsSection(recommendation.recommendations)
                
                // Warnings
                if !recommendation.warnings.isEmpty {
                    warningsSection(recommendation.warnings)
                }
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Sections

    private func systemRequirementsSection(_ requirements: SystemRequirements) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("System Requirements")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            HStack(spacing: AXSpacing.lg) {
                RequirementItem(
                    icon: "memorychip",
                    title: "Memory",
                    value: "\(requirements.minimumMemoryMB) MB min",
                    recommended: "\(requirements.recommendedMemoryMB) MB"
                )
                
                RequirementItem(
                    icon: "internaldrive",
                    title: "Disk",
                    value: "\(requirements.minimumDiskGB) GB min",
                    recommended: "\(requirements.recommendedDiskGB) GB"
                )
                
                RequirementItem(
                    icon: "cpu",
                    title: "CPU",
                    value: "\(requirements.minimumCpuCores) core min",
                    recommended: "\(requirements.minimumCpuCores * 2)+ cores"
                )
            }
        }
    }

    private func versionRecommendationsSection(_ recommendations: [DatabaseVersionRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Recommended Versions")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(spacing: AXSpacing.md) {
                ForEach(recommendations) { rec in
                    VersionRecommendationCard(
                        recommendation: rec,
                        isSelected: selectedVersion?.version == rec.version,
                        accentColor: databaseType.brandColor,
                        onSelect: { onSelectVersion(rec) }
                    )
                }
            }
        }
    }

    private func warningsSection(_ warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Warnings")
                .font(AXTypography.headline)
                .foregroundColor(.axWarning)
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.axWarning)
                        
                        Text(warning)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
            .padding(AXSpacing.md)
            .background(Color.axWarning.opacity(0.1))
            .cornerRadius(AXCornerRadius.md)
        }
    }

    private var actionButtonsSection: some View {
        HStack(spacing: AXSpacing.md) {
            Button("Cancel", action: onCancel)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: onStartInstall) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.down.circle")
                    Text("Install \(selectedVersion?.version ?? "")")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(selectedVersion != nil ? databaseType.brandColor : Color.axTextMuted)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedVersion == nil || isInstalling)
        }
    }
}

// MARK: - Supporting Views

private struct RequirementItem: View {
    let icon: String
    let title: String
    let value: String
    let recommended: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            Text(value)
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
            
            Text("Rec: \(recommended)")
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }
}

private struct VersionRecommendationCard: View {
    let recommendation: DatabaseVersionRecommendation
    let isSelected: Bool
    let accentColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AXSpacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : Color.axBorder, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 10, height: 10)
                    }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    HStack(spacing: AXSpacing.sm) {
                        Text("Version \(recommendation.version)")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        
                        if recommendation.isRecommended {
                            Badge(text: "Recommended", color: .axSuccess)
                        }
                        
                        if recommendation.isLTS {
                            Badge(text: "LTS", color: .axInfo)
                        }
                        
                        SecurityBadge(status: recommendation.securityStatus)
                    }
                    
                    Text(recommendation.reasoning)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Compatibility score
                VStack(alignment: .trailing, spacing: AXSpacing.xxs) {
                    Text("\(recommendation.compatibilityScore)%")
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(compatibilityColor)
                    
                    Text("Compatible")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(AXSpacing.md)
            .background(isSelected ? accentColor.opacity(0.05) : Color.axSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? accentColor : Color.axBorder, lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var compatibilityColor: Color {
        if recommendation.compatibilityScore >= 90 {
            return .axSuccess
        } else if recommendation.compatibilityScore >= 70 {
            return .axWarning
        } else {
            return .axError
        }
    }
}

private struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AXTypography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
    }
}

private struct SecurityBadge: View {
    let status: SecurityStatus
    
    var body: some View {
        HStack(spacing: AXSpacing.xxs) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusDisplayName)
                .font(AXTypography.caption2)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AXSpacing.xs)
        .padding(.vertical, AXSpacing.xxxs)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private var statusColor: Color {
        switch status {
        case .secure:
            return .axSuccess
        case .updatesAvailable:
            return .axWarning
        case .critical, .endOfLife:
            return .axError
        case .unknown:
            return .axTextMuted
        @unknown default:
            return .axTextMuted
        }
    }
    
    private var statusDisplayName: String {
        switch status {
        case .secure:
            return "Secure"
        case .updatesAvailable:
            return "Updates Available"
        case .critical:
            return "Critical"
        case .endOfLife:
            return "End of Life"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}
