
import SwiftUI
import AevonXCoreBridge

struct VersionPickerSheet: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isFetchingVersions {
                    ProgressView(L10n.Engine.fetchingVersions)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.availableVersions.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.axWarning)
                        Text(L10n.Engine.noVersionsAvailable)
                            .font(AXTypography.headline)
                        Text(L10n.Engine.couldNotFetchVersions)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.availableVersions) { version in
                            Button {
                                viewModel.showInstallConfirmation(version: version)
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(version.version)
                                            .font(AXTypography.body)
                                            .foregroundColor(.axTextPrimary)
                                        
                                        HStack(spacing: 6) {
                                            if version.isLTS {
                                                Text(L10n.Engine.lts)
                                                    .font(AXTypography.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.axAccentBlue.opacity(0.2))
                                                    .foregroundColor(.axAccentBlue)
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }
                                            
                                            if version.isRecommended {
                                                Text(L10n.Engine.recommended)
                                                    .font(AXTypography.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.axSuccess.opacity(0.2))
                                                    .foregroundColor(.axSuccess)
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.engineInfo?.version == version.version {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.axSuccess)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.axBackground)
            .navigationTitle(L10n.Database.selectVersion)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Button.cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.fetchAvailableVersions() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if viewModel.availableVersions.isEmpty {
                Task { await viewModel.fetchAvailableVersions() }
            }
        }
    }
}
