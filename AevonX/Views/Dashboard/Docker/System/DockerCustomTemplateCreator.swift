
import SwiftUI
import AevonXCore

struct DockerCustomTemplateCreator: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var templateName: String = ""
    @State private var templateDescription: String = ""
    @State private var templateCategory: String = "Custom"
    @State private var composeContent: String = defaultCompose
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private let categories = ["Custom", "Web", "Database", "DevOps", "Development", "Media", "Analytics", "Security"]
    
    private static let defaultCompose = """
    version: '3.8'
    services:
      app:
        image: nginx:alpine
        restart: unless-stopped
        ports:
          - "8080:80"
        volumes:
          - app_data:/usr/share/nginx/html
          
    volumes:
      app_data:
    """
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "plus.rectangle.on.folder.fill")
                        .foregroundColor(.axAccentBlue)
                    Text("Create Custom Template")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            HSplitView {
                // Left: Form
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Template Name")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            TextField("e.g. My LEMP Stack", text: $templateName)
                                .textFieldStyle(AXTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Description")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            TextField("Brief description of this template", text: $templateDescription)
                                .textFieldStyle(AXTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Category")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            Picker("", selection: $templateCategory) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(AXSpacing.lg)
                }
                .frame(minWidth: 220, maxWidth: 260)
                
                // Right: Compose editor
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("docker-compose.yml")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface.opacity(0.5))
                    
                    TextEditor(text: $composeContent)
                        .font(.system(size: 11, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(AXSpacing.sm)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                        .foregroundColor(.white)
                }
            }
            
            // Messages + footer
            if let error = errorMessage {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                    .font(.system(size: 11)).foregroundColor(.axError)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
            }
            if let success = successMessage {
                HStack(spacing: 6) { Image(systemName: "checkmark.circle.fill"); Text(success) }
                    .font(.system(size: 11)).foregroundColor(.axSuccess)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axSuccess.opacity(0.08))
            }
            
            Divider()
            
            HStack {
                Spacer()
                
                Button(action: saveAndDeploy) {
                    HStack(spacing: 4) {
                        if isSaving { ProgressView().controlSize(.small) }
                        Image(systemName: "rocket.fill").font(.system(size: 10))
                        Text(isSaving ? "Deploying..." : "Save & Deploy")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(templateName.isEmpty || composeContent.isEmpty || isSaving)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 700, height: 480)
        .background(Color.axBackground)
    }
    
    // MARK: - Actions
    
    private func saveAndDeploy() {
        isSaving = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                try await DockerManager.shared.saveCustomTemplate(
                    name: templateName,
                    description: templateDescription,
                    category: templateCategory,
                    compose: composeContent,
                    serverId: serverId
                )
                await MainActor.run {
                    successMessage = "Template saved and deployed!"
                    isSaving = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isSaving = false }
            }
        }
    }
}
