
import SwiftUI
import AevonXCoreBridge

struct VersionPickerSheet: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isFetchingVersions {
                    ProgressView("Fetching versions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.availableVersions.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.axWarning)
                        Text("No versions available")
                            .font(AXTypography.headline)
                        Text("Could not fetch version information.")
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
                                                Text("LTS")
                                                    .font(AXTypography.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.axAccentBlue.opacity(0.2))
                                                    .foregroundColor(.axAccentBlue)
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }
                                            
                                            if version.isRecommended {
                                                Text("Recommended")
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
            .navigationTitle("Select Version")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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
