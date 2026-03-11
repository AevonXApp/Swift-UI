
import SwiftUI
import AevonXCoreBridge

struct ConfigEditorSheet: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                     ProgressView("Loading configuration...")
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TextEditor(text: $viewModel.configEditContent)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                }
            }
            .background(Color.axBackground)
            .navigationTitle("Edit Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveConfiguration()
                            // Dismiss handled by VM success or manual if preferred, 
                            // but VM toggles showConfigEditor = false on success
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.operationResult.isInProgress)
                }
            }
        }
        .onAppear {
            if viewModel.configEditContent.isEmpty {
                viewModel.configEditContent = viewModel.configuration?.rawContent ?? ""
                if viewModel.configEditContent.isEmpty {
                     Task { await viewModel.loadConfiguration() }
                }
            }
        }
        // Respond to showConfigEditor change to dismiss if needed
        .onChange(of: viewModel.showConfigEditor) { _, show in
            if !show {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
