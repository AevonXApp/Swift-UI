//
//  SSHSecurityScoreView.swift
//  AevonX
//
//  Security score card and issue list.
//

import SwiftUI

extension SSHSecurityDetailSection {

    var scoreCard: some View {
        Group {
            if let score = vm.securityScore {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    HStack(spacing: AXSpacing.md) {
                        // Grade circle
                        ZStack {
                            Circle()
                                .stroke(score.gradeColor.opacity(0.2), lineWidth: 4)
                                .frame(width: 48, height: 48)
                            Circle()
                                .trim(from: 0, to: CGFloat(score.score) / 100)
                                .stroke(score.gradeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))
                            Text(score.grade)
                                .font(AXTypography.title3).fontWeight(.bold)
                                .foregroundColor(score.gradeColor)
                        }

                        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                            Text(L10n.ServerSettings.securityScore(score.score))
                                .font(AXTypography.caption).fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)
                            if score.issues.isEmpty {
                                Text(L10n.ServerSettings.noIssuesFound)
                                    .font(AXTypography.caption2).foregroundColor(.axSuccess)
                            }
                        }
                        Spacer()
                    }

                    if !score.issues.isEmpty {
                        ForEach(score.issues, id: \.self) { issue in
                            HStack(spacing: AXSpacing.xxs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(AXTypography.caption2).foregroundColor(.axWarning)
                                Text(issue)
                                    .font(AXTypography.caption2).foregroundColor(.axTextSecondary)
                            }
                        }
                    }

                    // Extra info rows
                    if !vm.maxAuthTries.isEmpty {
                        infoRow(L10n.ServerSettings.maxAuthTries, vm.maxAuthTries)
                    }
                    if !vm.x11Forwarding.isEmpty {
                        infoRow(L10n.ServerSettings.x11Forwarding, vm.x11Forwarding)
                    }
                    if !vm.allowedUsers.isEmpty {
                        infoRow(L10n.ServerSettings.allowUsers, vm.allowedUsers)
                    }
                }
                .padding(AXSpacing.sm)
                .background(score.gradeColor.opacity(0.05))
                .cornerRadius(AXCornerRadius.md)
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(AXTypography.caption2).foregroundColor(.axTextMuted)
            Spacer()
            Text(value).font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
        }
    }
}
