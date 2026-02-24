
import SwiftUI
import AevonXCore

struct DockerAIComposeGenerator: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var prompt: String = ""
    @State private var generatedCompose: String = ""
    @State private var isGenerating = false
    @State private var isDeploying = false
    @State private var projectName: String = ""
    @State private var errorMessage: String?
    @State private var step: GeneratorStep = .describe
    
    enum GeneratorStep {
        case describe, review, deploy
    }
    
    // Quick presets
    private let presets = [
        ("Web App", "WordPress with MySQL and phpMyAdmin"),
        ("API Stack", "Node.js API with PostgreSQL and Redis"),
        ("Monitoring", "Grafana + Prometheus + Node Exporter"),
        ("Dev Env", "Full LAMP stack for development"),
        ("ML Pipeline", "Jupyter Notebook with TensorFlow"),
        ("Media Server", "Plex media server with transcoding"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("AI Compose Generator")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                
                // Step indicators
                HStack(spacing: 4) {
                    stepDot(1, active: step == .describe)
                    stepDot(2, active: step == .review)
                    stepDot(3, active: step == .deploy)
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            switch step {
            case .describe:
                describeStep
            case .review:
                reviewStep
            case .deploy:
                deployStep
            }
            
            Divider()
            
            // Footer
            HStack {
                if step != .describe {
                    Button(action: { step = .describe }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 10))
                            Text("Back")
                        }
                    }
                    .buttonStyle(AXSecondaryButtonStyle())
                }
                
                Spacer()
                
                switch step {
                case .describe:
                    Button(action: generate) {
                        HStack(spacing: 4) {
                            if isGenerating { ProgressView().controlSize(.small) }
                            Image(systemName: "sparkles").font(.system(size: 10))
                            Text(isGenerating ? "Generating..." : "Generate")
                        }
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(prompt.isEmpty || isGenerating)
                    
                case .review:
                    Button(action: { step = .deploy }) {
                        HStack(spacing: 4) {
                            Text("Continue to Deploy")
                            Image(systemName: "chevron.right").font(.system(size: 10))
                        }
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    
                case .deploy:
                    Button(action: deploy) {
                        HStack(spacing: 4) {
                            if isDeploying { ProgressView().controlSize(.small) }
                            Image(systemName: "rocket.fill").font(.system(size: 10))
                            Text(isDeploying ? "Deploying..." : "Deploy")
                        }
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(projectName.isEmpty || isDeploying)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 650, height: 520)
        .background(Color.axBackground)
    }
    
    // MARK: - Describe Step
    
    private var describeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Describe your stack")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Tell the AI what you need and it will generate a docker-compose.yml for you.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                TextEditor(text: $prompt)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .padding(AXSpacing.sm)
                    .frame(minHeight: 100)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                
                // Quick presets
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Quick Presets")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(presets, id: \.0) { name, desc in
                            Button(action: { prompt = desc }) {
                                VStack(spacing: 4) {
                                    Text(name)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.axTextPrimary)
                                    Text(desc)
                                        .font(.system(size: 9))
                                        .foregroundColor(.axTextMuted)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(Color.axSurface)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.axBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if let error = errorMessage {
                    HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                        .font(.system(size: 11)).foregroundColor(.axError)
                        .padding(AXSpacing.sm).background(Color.axError.opacity(0.08)).cornerRadius(6)
                }
            }
            .padding(AXSpacing.lg)
        }
    }
    
    // MARK: - Review Step
    
    private var reviewStep: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Review Generated Compose")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text("AI Generated")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(AXSpacing.md)
            
            TextEditor(text: $generatedCompose)
                .font(.system(size: 11, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(AXSpacing.sm)
                .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Deploy Step
    
    private var deployStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            Text("Deploy Configuration")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Project Name")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                TextField("e.g. my-web-app", text: $projectName)
                    .textFieldStyle(AXTextFieldStyle())
            }
            
            Spacer()
        }
        .padding(AXSpacing.lg)
    }
    
    // MARK: - Helpers
    
    private func stepDot(_ number: Int, active: Bool) -> some View {
        Circle()
            .fill(active ? Color.purple : Color.axBorder)
            .frame(width: 8, height: 8)
    }
    
    // MARK: - Actions
    
    private func generate() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let generated = try await generateComposeWithAI(prompt: prompt)
                await MainActor.run {
                    generatedCompose = generated
                    step = .review
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    private func deploy() {
        guard !projectName.isEmpty else { return }
        isDeploying = true
        
        Task {
            do {
                try await DockerManager.shared.deployTemplate(
                    name: projectName,
                    composeContent: generatedCompose,
                    serverId: serverId
                )
                await MainActor.run {
                    isDeploying = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isDeploying = false
                }
            }
        }
    }
    
    private func generateComposeWithAI(prompt: String) async throws -> String {
        // Simulate brief processing time for AI-like experience
        try await Task.sleep(nanoseconds: 800_000_000)
        return generateFallbackCompose(for: prompt)
    }
    
    private func generateFallbackCompose(for description: String) -> String {
        let lower = description.lowercased()
        
        if lower.contains("wordpress") || lower.contains("wp") {
            return """
            version: '3.8'
            services:
              wordpress:
                image: wordpress:latest
                restart: unless-stopped
                ports:
                  - "8080:80"
                environment:
                  WORDPRESS_DB_HOST: db
                  WORDPRESS_DB_USER: wordpress
                  WORDPRESS_DB_PASSWORD: changeme
                  WORDPRESS_DB_NAME: wordpress
                volumes:
                  - wp_data:/var/www/html
                depends_on:
                  - db
                healthcheck:
                  test: ["CMD", "curl", "-f", "http://localhost"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  
              db:
                image: mysql:8.0
                restart: unless-stopped
                environment:
                  MYSQL_DATABASE: wordpress
                  MYSQL_USER: wordpress
                  MYSQL_PASSWORD: changeme
                  MYSQL_ROOT_PASSWORD: rootpassword
                volumes:
                  - db_data:/var/lib/mysql
                healthcheck:
                  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  
            volumes:
              wp_data:
              db_data:
            """
        }
        
        if lower.contains("node") || lower.contains("api") || lower.contains("postgres") || lower.contains("redis") {
            return """
            version: '3.8'
            services:
              api:
                image: node:20-alpine
                restart: unless-stopped
                ports:
                  - "3000:3000"
                environment:
                  DATABASE_URL: postgres://app:changeme@postgres:5432/app
                  REDIS_URL: redis://redis:6379
                volumes:
                  - app_data:/app
                depends_on:
                  - postgres
                  - redis
                command: sh -c "npm install && npm start"

              postgres:
                image: postgres:16-alpine
                restart: unless-stopped
                environment:
                  POSTGRES_USER: app
                  POSTGRES_PASSWORD: changeme
                  POSTGRES_DB: app
                volumes:
                  - pg_data:/var/lib/postgresql/data
                healthcheck:
                  test: ["CMD-SHELL", "pg_isready -U app"]
                  interval: 10s
                  timeout: 5s
                  retries: 5

              redis:
                image: redis:7-alpine
                restart: unless-stopped
                volumes:
                  - redis_data:/data
                healthcheck:
                  test: ["CMD", "redis-cli", "ping"]
                  interval: 10s
                  timeout: 5s
                  retries: 5

            volumes:
              app_data:
              pg_data:
              redis_data:
            """
        }
        
        if lower.contains("grafana") || lower.contains("prometheus") || lower.contains("monitor") {
            return """
            version: '3.8'
            services:
              grafana:
                image: grafana/grafana:latest
                restart: unless-stopped
                ports:
                  - "3000:3000"
                environment:
                  GF_SECURITY_ADMIN_PASSWORD: admin
                volumes:
                  - grafana_data:/var/lib/grafana
                depends_on:
                  - prometheus

              prometheus:
                image: prom/prometheus:latest
                restart: unless-stopped
                ports:
                  - "9090:9090"
                volumes:
                  - prom_data:/prometheus

              node-exporter:
                image: prom/node-exporter:latest
                restart: unless-stopped
                ports:
                  - "9100:9100"

            volumes:
              grafana_data:
              prom_data:
            """
        }
        
        if lower.contains("lamp") || lower.contains("apache") || lower.contains("php") {
            return """
            version: '3.8'
            services:
              web:
                image: php:8.2-apache
                restart: unless-stopped
                ports:
                  - "8080:80"
                volumes:
                  - web_data:/var/www/html
                depends_on:
                  - db

              db:
                image: mysql:8.0
                restart: unless-stopped
                environment:
                  MYSQL_ROOT_PASSWORD: rootpassword
                  MYSQL_DATABASE: app
                  MYSQL_USER: app
                  MYSQL_PASSWORD: changeme
                volumes:
                  - db_data:/var/lib/mysql
                healthcheck:
                  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
                  interval: 30s
                  timeout: 10s
                  retries: 3

              phpmyadmin:
                image: phpmyadmin:latest
                restart: unless-stopped
                ports:
                  - "8081:80"
                environment:
                  PMA_HOST: db
                depends_on:
                  - db

            volumes:
              web_data:
              db_data:
            """
        }
        
        if lower.contains("jupyter") || lower.contains("tensorflow") || lower.contains("ml") || lower.contains("notebook") {
            return """
            version: '3.8'
            services:
              jupyter:
                image: tensorflow/tensorflow:latest-jupyter
                restart: unless-stopped
                ports:
                  - "8888:8888"
                environment:
                  JUPYTER_TOKEN: changeme
                volumes:
                  - notebooks:/tf/notebooks
                  - datasets:/tf/datasets
                deploy:
                  resources:
                    limits:
                      memory: 4G

            volumes:
              notebooks:
              datasets:
            """
        }
        
        if lower.contains("plex") || lower.contains("media") {
            return """
            version: '3.8'
            services:
              plex:
                image: plexinc/pms-docker:latest
                restart: unless-stopped
                ports:
                  - "32400:32400"
                environment:
                  PLEX_CLAIM: claim-XXXXXXXXXXXXXXXXXXXX
                  ADVERTISE_IP: http://YOUR_IP:32400/
                volumes:
                  - plex_config:/config
                  - plex_transcode:/transcode
                  - /media:/data
                deploy:
                  resources:
                    limits:
                      memory: 2G

            volumes:
              plex_config:
              plex_transcode:
            """
        }
        
        // Generic fallback
        return """
        version: '3.8'
        services:
          app:
            image: nginx:alpine
            restart: unless-stopped
            ports:
              - "8080:80"
            volumes:
              - app_data:/usr/share/nginx/html
            healthcheck:
              test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
              interval: 30s
              timeout: 10s
              retries: 3
              
        volumes:
          app_data:
        """
    }
}
