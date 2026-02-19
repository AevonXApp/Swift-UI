
import SwiftUI
import AevonXCore

struct DockerTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let composeContent: String
}

struct DockerTemplateDeployView: View {
    let serverId: String
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTemplate: DockerTemplate?
    @State private var projectName: String = ""
    @State private var isDeploying = false
    @State private var errorMessage: String?
    
    let templates = [
        DockerTemplate(
            name: "WordPress Stack",
            description: "WordPress with MySQL database and persistent volumes.",
            icon: "globe",
            composeContent: """
services:
  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/var/www/html

volumes:
  db_data:
  wp_data:
"""
        ),
        DockerTemplate(
            name: "Laravel (LEMP)",
            description: "PHP-FPM, Nginx, and MariaDB ready for Laravel apps.",
            icon: "leaf",
            composeContent: """
services:
  app:
    image: bitnami/laravel:latest
    ports:
      - 8000:8000
    environment:
      DB_HOST: mariadb
      DB_PORT: 3306
      DB_USERNAME: bn_laravel
      DB_DATABASE: bitnami_laravel
    volumes:
      - .:/app
  mariadb:
    image: bitnami/mariadb:latest
    environment:
      ALLOW_EMPTY_PASSWORD: "yes"
      MARIADB_USER: bn_laravel
      MARIADB_DATABASE: bitnami_laravel
"""
        ),
        DockerTemplate(
            name: "Redis + Insight",
            description: "Redis server with Redis Insight UI for management.",
            icon: "bolt.fill",
            composeContent: """
services:
  redis:
    image: redis:latest
    ports:
      - 6379:6379
  insight:
    image: redislabs/redisinsight:latest
    ports:
      - 8001:8001
"""
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(selectedTemplate == nil ? "Deploy Template" : "Configure \(selectedTemplate!.name)")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if selectedTemplate != nil {
                // Configuration Screen
                VStack(spacing: AXSpacing.xl) {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXLabel("Project Name")
                        TextField("e.g. my-wp-blog", text: $projectName)
                            .textFieldStyle(AXTextFieldStyle())
                        
                        Text("This will create a directory at /opt/aevonx/docker-templates/\(projectName.lowercased())/")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .padding(AXSpacing.xl)
                    
                    if let error = errorMessage {
                        ErrorBanner(error: error)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Back") { selectedTemplate = nil }
                            .buttonStyle(AXSecondaryButtonStyle())
                        Spacer()
                        Button(action: deploy) {
                            HStack {
                                if isDeploying {
                                    ProgressView().controlSize(.small).padding(.trailing, 8)
                                }
                                Text("Deploy Now")
                            }
                        }
                        .buttonStyle(AXPrimaryButtonStyle())
                        .disabled(isDeploying || projectName.isEmpty)
                    }
                    .padding(AXSpacing.lg)
                }
            } else {
                // Selection Screen
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        ForEach(templates) { template in
                            TemplateCard(template: template) {
                                selectedTemplate = template
                                projectName = template.name.lowercased().replacingOccurrences(of: " ", with: "-")
                            }
                        }
                    }
                    .padding(AXSpacing.xl)
                }
            }
        }
        .frame(width: 550)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }
    
    private func deploy() {
        guard let template = selectedTemplate else { return }
        isDeploying = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerManager.shared.deployTemplate(
                    name: projectName,
                    composeContent: template.composeContent,
                    serverId: serverId
                )
                
                await MainActor.run {
                    isDeploying = false
                    onComplete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeploying = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct TemplateCard: View {
    let template: DockerTemplate
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.axAccentBlue)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(template.description)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(AXSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovered ? Color.axSurfaceHover : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isHovered ? Color.axAccentBlue.opacity(0.5) : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct AXLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(AXTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.axTextSecondary)
    }
}

private struct ErrorBanner: View {
    let error: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error)
        }
        .font(AXTypography.caption)
        .foregroundColor(.axError)
        .padding()
        .background(Color.axError.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
        .padding(.horizontal, AXSpacing.xl)
    }
}
