
import SwiftUI
import AevonXCore

// MARK: - Template Models

enum DockerTemplateCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case databases = "Databases"
    case webProxy = "Web & Proxy"
    case devops = "DevOps"
    case monitoring = "Monitoring"
    case apps = "Apps"
    case messaging = "Messaging"
    case search = "Search"
    case cache = "Cache"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .databases: return "cylinder.fill"
        case .webProxy: return "globe"
        case .devops: return "hammer.fill"
        case .monitoring: return "chart.xyaxis.line"
        case .apps: return "app.fill"
        case .messaging: return "envelope.fill"
        case .search: return "magnifyingglass"
        case .cache: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .axAccentBlue
        case .databases: return .purple
        case .webProxy: return .blue
        case .devops: return .orange
        case .monitoring: return .green
        case .apps: return .pink
        case .messaging: return .teal
        case .search: return .yellow
        case .cache: return .red
        }
    }
}

struct DockerTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: DockerTemplateCategory
    let isPopular: Bool
    let composeContent: String
}

// MARK: - Template Catalog

struct DockerTemplateCatalog {
    static let all: [DockerTemplate] = [
        
        // ── Databases ──────────────────────────────
        
        DockerTemplate(
            name: "PostgreSQL",
            description: "Advanced open-source relational database with pgAdmin web UI.",
            icon: "cylinder.fill",
            category: .databases,
            isPopular: true,
            composeContent: """
services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: app
    ports:
      - 5432:5432
    volumes:
      - pg_data:/var/lib/postgresql/data

  pgadmin:
    image: dpage/pgadmin4:latest
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - 5050:80
    depends_on:
      - postgres

volumes:
  pg_data:
"""
        ),
        
        DockerTemplate(
            name: "MySQL 8",
            description: "Popular relational database with phpMyAdmin management UI.",
            icon: "cylinder.fill",
            category: .databases,
            isPopular: true,
            composeContent: """
services:
  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: app
      MYSQL_USER: user
      MYSQL_PASSWORD: changeme
    ports:
      - 3306:3306
    volumes:
      - mysql_data:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin:latest
    restart: unless-stopped
    environment:
      PMA_HOST: mysql
      MYSQL_ROOT_PASSWORD: rootpass
    ports:
      - 8081:80
    depends_on:
      - mysql

volumes:
  mysql_data:
"""
        ),
        
        DockerTemplate(
            name: "MongoDB",
            description: "NoSQL document database with Mongo Express web admin.",
            icon: "leaf.fill",
            category: .databases,
            isPopular: true,
            composeContent: """
services:
  mongo:
    image: mongo:7
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: changeme
    ports:
      - 27017:27017
    volumes:
      - mongo_data:/data/db

  mongo-express:
    image: mongo-express:latest
    restart: unless-stopped
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: root
      ME_CONFIG_MONGODB_ADMINPASSWORD: changeme
      ME_CONFIG_MONGODB_URL: mongodb://root:changeme@mongo:27017/
    ports:
      - 8082:8081
    depends_on:
      - mongo

volumes:
  mongo_data:
"""
        ),
        
        DockerTemplate(
            name: "MariaDB",
            description: "MySQL-compatible database, lightweight and fast.",
            icon: "cylinder.fill",
            category: .databases,
            isPopular: false,
            composeContent: """
services:
  mariadb:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: rootpass
      MARIADB_DATABASE: app
      MARIADB_USER: user
      MARIADB_PASSWORD: changeme
    ports:
      - 3306:3306
    volumes:
      - mariadb_data:/var/lib/mysql

volumes:
  mariadb_data:
"""
        ),
        
        DockerTemplate(
            name: "CockroachDB",
            description: "Distributed SQL database built for cloud scale.",
            icon: "arrow.triangle.branch",
            category: .databases,
            isPopular: false,
            composeContent: """
services:
  cockroach:
    image: cockroachdb/cockroach:latest
    command: start-single-node --insecure
    restart: unless-stopped
    ports:
      - 26257:26257
      - 8083:8080
    volumes:
      - cockroach_data:/cockroach/cockroach-data

volumes:
  cockroach_data:
"""
        ),
        
        DockerTemplate(
            name: "InfluxDB",
            description: "Time-series database optimized for metrics and IoT data.",
            icon: "chart.line.uptrend.xyaxis",
            category: .databases,
            isPopular: false,
            composeContent: """
services:
  influxdb:
    image: influxdb:2
    restart: unless-stopped
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: changeme123
      DOCKER_INFLUXDB_INIT_ORG: myorg
      DOCKER_INFLUXDB_INIT_BUCKET: mybucket
    ports:
      - 8086:8086
    volumes:
      - influx_data:/var/lib/influxdb2

volumes:
  influx_data:
"""
        ),
        
        // ── Web & Proxy ──────────────────────────────
        
        DockerTemplate(
            name: "Nginx Reverse Proxy",
            description: "Nginx Proxy Manager with Let's Encrypt SSL and web UI.",
            icon: "globe",
            category: .webProxy,
            isPopular: true,
            composeContent: """
services:
  nginx-proxy:
    image: jc21/nginx-proxy-manager:latest
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
      - 81:81
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt

volumes:
  npm_data:
  npm_letsencrypt:
"""
        ),
        
        DockerTemplate(
            name: "Traefik v3",
            description: "Modern reverse proxy with auto SSL, dashboard, and service discovery.",
            icon: "arrow.triangle.swap",
            category: .webProxy,
            isPopular: true,
            composeContent: """
services:
  traefik:
    image: traefik:v3.0
    restart: unless-stopped
    command:
      - --api.dashboard=true
      - --api.insecure=true
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
    ports:
      - 80:80
      - 443:443
      - 8084:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_certs:/certs

volumes:
  traefik_certs:
"""
        ),
        
        DockerTemplate(
            name: "Caddy",
            description: "Automatic HTTPS web server with zero config SSL.",
            icon: "lock.shield.fill",
            category: .webProxy,
            isPopular: false,
            composeContent: """
services:
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
      - 2019:2019
    volumes:
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
"""
        ),
        
        // ── DevOps ──────────────────────────────
        
        DockerTemplate(
            name: "Gitea",
            description: "Lightweight self-hosted Git service, GitHub alternative.",
            icon: "arrow.triangle.branch",
            category: .devops,
            isPopular: true,
            composeContent: """
services:
  gitea:
    image: gitea/gitea:latest
    restart: unless-stopped
    environment:
      USER_UID: 1000
      USER_GID: 1000
    ports:
      - 3000:3000
      - 2222:22
    volumes:
      - gitea_data:/data

volumes:
  gitea_data:
"""
        ),
        
        DockerTemplate(
            name: "Jenkins",
            description: "Leading open-source CI/CD automation server.",
            icon: "gearshape.2.fill",
            category: .devops,
            isPopular: true,
            composeContent: """
services:
  jenkins:
    image: jenkins/jenkins:lts
    restart: unless-stopped
    ports:
      - 8085:8080
      - 50000:50000
    volumes:
      - jenkins_data:/var/jenkins_home
    environment:
      JAVA_OPTS: -Xmx512m

volumes:
  jenkins_data:
"""
        ),
        
        DockerTemplate(
            name: "Drone CI",
            description: "Container-native CI/CD platform with YAML pipelines.",
            icon: "airplane",
            category: .devops,
            isPopular: false,
            composeContent: """
services:
  drone:
    image: drone/drone:latest
    restart: unless-stopped
    environment:
      DRONE_SERVER_HOST: localhost
      DRONE_SERVER_PROTO: http
      DRONE_RPC_SECRET: supersecret
    ports:
      - 8086:80
    volumes:
      - drone_data:/data

  runner:
    image: drone/drone-runner-docker:latest
    restart: unless-stopped
    environment:
      DRONE_RPC_HOST: drone
      DRONE_RPC_PROTO: http
      DRONE_RPC_SECRET: supersecret
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  drone_data:
"""
        ),
        
        DockerTemplate(
            name: "Portainer",
            description: "Docker management UI with containers, images, and stacks.",
            icon: "square.stack.3d.up.fill",
            category: .devops,
            isPopular: true,
            composeContent: """
services:
  portainer:
    image: portainer/portainer-ce:latest
    restart: unless-stopped
    ports:
      - 9443:9443
      - 9000:9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
"""
        ),
        
        // ── Monitoring ──────────────────────────────
        
        DockerTemplate(
            name: "Grafana + Prometheus",
            description: "Full monitoring stack with metrics collection and dashboards.",
            icon: "chart.bar.fill",
            category: .monitoring,
            isPopular: true,
            composeContent: """
services:
  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    ports:
      - 9090:9090
    volumes:
      - prom_data:/prometheus

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    ports:
      - 3001:3000
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus

volumes:
  prom_data:
  grafana_data:
"""
        ),
        
        DockerTemplate(
            name: "Uptime Kuma",
            description: "Self-hosted monitoring tool with status pages and alerts.",
            icon: "heart.fill",
            category: .monitoring,
            isPopular: true,
            composeContent: """
services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    restart: unless-stopped
    ports:
      - 3002:3001
    volumes:
      - kuma_data:/app/data

volumes:
  kuma_data:
"""
        ),
        
        DockerTemplate(
            name: "Netdata",
            description: "Real-time performance monitoring with beautiful dashboards.",
            icon: "waveform.path.ecg",
            category: .monitoring,
            isPopular: false,
            composeContent: """
services:
  netdata:
    image: netdata/netdata:latest
    restart: unless-stopped
    ports:
      - 19999:19999
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - netdata_data:/var/lib/netdata

volumes:
  netdata_data:
"""
        ),
        
        // ── Apps ──────────────────────────────
        
        DockerTemplate(
            name: "WordPress",
            description: "WordPress with MySQL database and persistent volumes.",
            icon: "globe",
            category: .apps,
            isPopular: true,
            composeContent: """
services:
  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wp_password
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    restart: unless-stopped
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wp_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html
    depends_on:
      - db

volumes:
  db_data:
  wp_data:
"""
        ),
        
        DockerTemplate(
            name: "Ghost Blog",
            description: "Modern publishing platform for blogs and newsletters.",
            icon: "book.fill",
            category: .apps,
            isPopular: false,
            composeContent: """
services:
  ghost:
    image: ghost:5-alpine
    restart: unless-stopped
    ports:
      - 2368:2368
    environment:
      url: http://localhost:2368
      database__client: sqlite3
    volumes:
      - ghost_data:/var/lib/ghost/content

volumes:
  ghost_data:
"""
        ),
        
        DockerTemplate(
            name: "Nextcloud",
            description: "Self-hosted cloud storage with file sync, calendar, and contacts.",
            icon: "cloud.fill",
            category: .apps,
            isPopular: true,
            composeContent: """
services:
  nextcloud:
    image: nextcloud:latest
    restart: unless-stopped
    ports:
      - 8088:80
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: changeme
    volumes:
      - nc_data:/var/www/html
    depends_on:
      - db

  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: rootpass
      MARIADB_DATABASE: nextcloud
      MARIADB_USER: nextcloud
      MARIADB_PASSWORD: changeme
    volumes:
      - nc_db:/var/lib/mysql

volumes:
  nc_data:
  nc_db:
"""
        ),
        
        DockerTemplate(
            name: "Minio S3",
            description: "S3-compatible object storage with web console.",
            icon: "externaldrive.fill",
            category: .apps,
            isPopular: false,
            composeContent: """
services:
  minio:
    image: minio/minio:latest
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - 9000:9000
      - 9001:9001
    volumes:
      - minio_data:/data

volumes:
  minio_data:
"""
        ),
        
        DockerTemplate(
            name: "n8n",
            description: "Workflow automation tool — self-hosted Zapier alternative.",
            icon: "arrow.triangle.merge",
            category: .apps,
            isPopular: false,
            composeContent: """
services:
  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - 5678:5678
    environment:
      N8N_BASIC_AUTH_ACTIVE: "true"
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: changeme
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
"""
        ),
        
        // ── Messaging ──────────────────────────────
        
        DockerTemplate(
            name: "RabbitMQ",
            description: "Message broker with management web UI and AMQP support.",
            icon: "envelope.fill",
            category: .messaging,
            isPopular: true,
            composeContent: """
services:
  rabbitmq:
    image: rabbitmq:3-management-alpine
    restart: unless-stopped
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: changeme
    ports:
      - 5672:5672
      - 15672:15672
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq

volumes:
  rabbitmq_data:
"""
        ),
        
        DockerTemplate(
            name: "NATS",
            description: "High-performance cloud-native messaging system.",
            icon: "bolt.horizontal.fill",
            category: .messaging,
            isPopular: false,
            composeContent: """
services:
  nats:
    image: nats:latest
    restart: unless-stopped
    ports:
      - 4222:4222
      - 8222:8222
    command: --jetstream --http_port 8222
    volumes:
      - nats_data:/data

volumes:
  nats_data:
"""
        ),
        
        // ── Search ──────────────────────────────
        
        DockerTemplate(
            name: "Meilisearch",
            description: "Lightning-fast, typo-tolerant search engine — Algolia alternative.",
            icon: "magnifyingglass",
            category: .search,
            isPopular: true,
            composeContent: """
services:
  meilisearch:
    image: getmeili/meilisearch:latest
    restart: unless-stopped
    environment:
      MEILI_MASTER_KEY: changeme
      MEILI_ENV: development
    ports:
      - 7700:7700
    volumes:
      - meili_data:/meili_data

volumes:
  meili_data:
"""
        ),
        
        DockerTemplate(
            name: "Typesense",
            description: "Open-source search engine, fast and typo-tolerant.",
            icon: "text.magnifyingglass",
            category: .search,
            isPopular: false,
            composeContent: """
services:
  typesense:
    image: typesense/typesense:latest
    restart: unless-stopped
    environment:
      TYPESENSE_API_KEY: changeme
      TYPESENSE_DATA_DIR: /data
    ports:
      - 8108:8108
    volumes:
      - typesense_data:/data

volumes:
  typesense_data:
"""
        ),
        
        // ── Cache ──────────────────────────────
        
        DockerTemplate(
            name: "Redis + Insight",
            description: "In-memory data store with Redis Insight management UI.",
            icon: "bolt.fill",
            category: .cache,
            isPopular: true,
            composeContent: """
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - 6379:6379
    volumes:
      - redis_data:/data

  insight:
    image: redis/redisinsight:latest
    restart: unless-stopped
    ports:
      - 5540:5540
    depends_on:
      - redis

volumes:
  redis_data:
"""
        ),
        
        DockerTemplate(
            name: "Memcached",
            description: "High-performance distributed memory caching system.",
            icon: "memorychip",
            category: .cache,
            isPopular: false,
            composeContent: """
services:
  memcached:
    image: memcached:alpine
    restart: unless-stopped
    ports:
      - 11211:11211
    command: memcached -m 256
"""
        ),
    ]
}

// MARK: - Deploy View

struct DockerTemplateDeployView: View {
    let serverId: String
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTemplate: DockerTemplate?
    @State private var selectedCategory: DockerTemplateCategory = .all
    @State private var searchText = ""
    @State private var projectName = ""
    @State private var isDeploying = false
    @State private var errorMessage: String?
    
    private var filteredTemplates: [DockerTemplate] {
        var result = DockerTemplateCatalog.all
        
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Popular first
        return result.sorted { $0.isPopular && !$1.isPopular }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if selectedTemplate != nil {
                    Button(action: { selectedTemplate = nil }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.axTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(selectedTemplate == nil ? "Template Marketplace" : "Deploy \(selectedTemplate!.name)")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                if selectedTemplate == nil {
                    Text("\(DockerTemplateCatalog.all.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.axAccentBlue.opacity(0.15))
                        .cornerRadius(AXCornerRadius.md)
                }
                
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
            
            if let template = selectedTemplate {
                // ── Configuration Screen ──
                configurationView(for: template)
            } else {
                // ── Browse Screen ──
                VStack(spacing: 0) {
                    // Search
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.axTextMuted)
                            .font(.system(size: 12))
                        TextField("Search templates...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 12))
                    }
                    .padding(10)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.top, AXSpacing.md)
                    
                    // Category Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(DockerTemplateCategory.allCases) { cat in
                                Button(action: { selectedCategory = cat }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 10))
                                        Text(cat.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? cat.color.opacity(0.15) : Color.axSurface)
                                    .foregroundColor(selectedCategory == cat ? cat.color : .axTextSecondary)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedCategory == cat ? cat.color.opacity(0.4) : Color.axBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                    }
                    
                    // Templates Grid
                    ScrollView {
                        if filteredTemplates.isEmpty {
                            VStack(spacing: AXSpacing.md) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(.axTextMuted)
                                Text("No templates found")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                                ForEach(filteredTemplates) { template in
                                    TemplateCard(template: template) {
                                        selectedTemplate = template
                                        projectName = template.name.lowercased()
                                            .replacingOccurrences(of: " ", with: "-")
                                            .replacingOccurrences(of: "+", with: "-")
                                    }
                                }
                            }
                            .padding(AXSpacing.lg)
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
    }
    
    // MARK: - Configuration View
    
    @ViewBuilder
    private func configurationView(for template: DockerTemplate) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Template info card
                    HStack(spacing: AXSpacing.md) {
                        Image(systemName: template.icon)
                            .font(.system(size: 24))
                            .foregroundColor(template.category.color)
                            .frame(width: 44, height: 44)
                            .background(template.category.color.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            Text(template.description)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    
                    // Project name
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Project Name")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextSecondary)
                        
                        TextField("e.g. my-project", text: $projectName)
                            .textFieldStyle(AXTextFieldStyle())
                        
                        Text("Directory: /opt/aevonx/docker-templates/\(projectName.lowercased())/")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                    }
                    
                    // Compose preview
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Compose Configuration")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextSecondary)
                        
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(template.composeContent)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AXSpacing.sm)
                        }
                        .frame(maxHeight: 200)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .padding()
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            Divider()
            
            // Deploy button
            HStack {
                Button("Cancel") { selectedTemplate = nil }
                    .buttonStyle(AXSecondaryButtonStyle())
                Spacer()
                Button(action: deploy) {
                    HStack(spacing: 6) {
                        if isDeploying {
                            ProgressView().controlSize(.small)
                        }
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 12))
                        Text(isDeploying ? "Deploying..." : "Deploy Now")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(isDeploying || projectName.isEmpty)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
    }
    
    // MARK: - Deploy
    
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

// MARK: - Template Card

private struct TemplateCard: View {
    let template: DockerTemplate
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.system(size: 20))
                        .foregroundColor(template.category.color)
                        .frame(width: 36, height: 36)
                        .background(template.category.color.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                    
                    Spacer()
                    
                    if template.isPopular {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                            Text("Popular")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    
                    Text(template.description)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Category tag
                Text(template.category.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(template.category.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(template.category.color.opacity(0.08))
                    .cornerRadius(4)
            }
            .padding(AXSpacing.md)
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
