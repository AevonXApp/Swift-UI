//
//  DBEMAccessSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEMAccessSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Access & Permissions")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.loadUsers() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(AXTypography.subheadline)
                            Text("Refresh")
                                .font(AXTypography.subheadline)
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                // Users Management
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Database Users")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()
                        }

                        Divider()

                        if viewModel.isLoadingUsers {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(AXSpacing.lg)
                                Spacer()
                            }
                        } else if let error = viewModel.userLoadError {
                            Text(error)
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axError)
                        } else if viewModel.databaseUsers.isEmpty {
                            Text("No users found or user listing not supported for this engine.")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextMuted)
                        } else {
                            ForEach(viewModel.databaseUsers) { user in
                                HStack(spacing: AXSpacing.md) {
                                    Image(systemName: "person.circle.fill")
                                        .font(AXTypography.title2)
                                        .foregroundColor(.axAccentBlue)

                                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                        Text(user.username)
                                            .font(AXTypography.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.axTextPrimary)

                                        Text("@\(user.host)")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextMuted)
                                    }

                                    Spacer()

                                    if user.isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(AXTypography.subheadline)
                                            .foregroundColor(.axWarning)
                                    }

                                    if user.sslRequired {
                                        Image(systemName: "lock.shield.fill")
                                            .font(AXTypography.subheadline)
                                            .foregroundColor(.axAccentGreen)
                                    }

                                    if !user.privileges.isEmpty {
                                        Text("\(user.privileges.count) privileges")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextMuted)
                                    }
                                }
                                .padding(.vertical, AXSpacing.sm)

                                if user.id != viewModel.databaseUsers.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            Task { await viewModel.loadUsers() }
        }
    }
}
