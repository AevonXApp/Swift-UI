
import SwiftUI
import AevonXCoreBridge

struct DockerEnvTemplatesView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var templates: [EnvTemplate] = []
    @State private var isLoading = true
    @State private var showAddForm = false
    @State private var errorMessage: String?
    
    // Form
    @State private var templateName = ""
    @State private var templateDesc = ""
    @State private var envLines = ""
    @State private var isAdding = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Environment Templates", systemImage: "list.bullet.rectangle")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button { showAddForm.toggle() } label: {
                    Label("New Template", systemImage: "plus")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.axAccentBlue)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
                
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
                    if showAddForm {
                        AXCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.Docker.createEnvironmentTemplate)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                TextField("Template name", text: $templateName)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Description", text: $templateDesc)
                                    .textFieldStyle(.roundedBorder)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.Docker.variablesOnePerLineKeyValue)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                    TextEditor(text: $envLines)
                                        .font(.system(size: 12, design: .monospaced))
                                        .frame(minHeight: 100)
                                        .padding(6)
                                        .background(Color.axSurface)
                                        .cornerRadius(AXCornerRadius.sm)
                                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder))
                                }
                                
                                HStack {
                                    Spacer()
                                    Button(L10n.Button.cancel) { showAddForm = false }
                                        .buttonStyle(.plain).foregroundColor(.axTextSecondary)
                                    Button {
                                        saveTemplate()
                                    } label: {
                                        if isAdding { ProgressView().scaleEffect(0.6) }
                                        else { Text(L10n.Docker.saveTemplate) }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(templateName.isEmpty ? Color.axSurface : Color.axAccentBlue)
                                    .foregroundColor(templateName.isEmpty ? .axTextMuted : .white)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .disabled(templateName.isEmpty || isAdding)
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error).font(AXTypography.caption).foregroundColor(.axError).padding()
                    }
                    
                    if isLoading {
                        ProgressView("Loading templates...").padding(30)
                    } else if templates.isEmpty {
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 32))
                                .foregroundColor(.axTextMuted)
                            Text(L10n.Docker.noTemplatesSaved)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                            Text(L10n.Docker.saveEnvVarSetsForQuickReuse)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                        .padding(30)
                    } else {
                        ForEach(templates) { template in
                            AXCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(AXTypography.body)
                                                .foregroundColor(.axTextPrimary)
                                                .fontWeight(.medium)
                                            Text(template.description)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            let text = template.variables.joined(separator: "\n")
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(text, forType: .string)
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 12))
                                                .foregroundColor(.axAccentBlue)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Copy variables")
                                        
                                        Button {
                                            deleteTemplate(template)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                                .foregroundColor(.axError)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    // Show variables
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(template.variables.prefix(5), id: \.self) { v in
                                            Text(v)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.axTextMuted)
                                                .lineLimit(1)
                                        }
                                        if template.variables.count > 5 {
                                            Text("... +\(template.variables.count - 5) more")
                                                .font(AXTypography.caption2)
                                                .foregroundColor(.axTextMuted)
                                        }
                                    }
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.axSurface)
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color.axBackground)
        .onAppear { loadTemplates() }
    }
    
    private func loadTemplates() {
        Task {
            do {
                let t = try await DockerService.shared.listEnvTemplates(serverId: serverId)
                await MainActor.run { templates = t; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func saveTemplate() {
        isAdding = true
        let vars = envLines.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let template = EnvTemplate(name: templateName, description: templateDesc, variables: vars)
        Task {
            do {
                try await DockerService.shared.saveEnvTemplate(template, serverId: serverId)
                await MainActor.run {
                    isAdding = false; showAddForm = false
                    templateName = ""; templateDesc = ""; envLines = ""
                    loadTemplates()
                }
            } catch {
                await MainActor.run { isAdding = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func deleteTemplate(_ template: EnvTemplate) {
        Task {
            try? await DockerService.shared.deleteEnvTemplate(id: template.id, serverId: serverId)
            await MainActor.run { templates.removeAll { $0.id == template.id } }
        }
    }
}
