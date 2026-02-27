//
//  SiteConfigModels.swift
//  AevonX
//
//  Models for per-site Nginx/Apache configuration management
//

import Foundation

// MARK: - Config Template

enum SiteConfigTemplate: String, CaseIterable, Identifiable {
    case laravel = "Laravel"
    case wordpress = "WordPress"
    case react = "React (SPA)"
    case vue = "Vue.js (SPA)"
    case nextjs = "Next.js"
    case angular = "Angular"
    case reverseProxy = "Reverse Proxy"
    case staticSite = "Static Site"
    case djangoPython = "Django (Python)"
    case railsRuby = "Rails (Ruby)"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .laravel: return "PHP framework with public/ directory, try_files for routing"
        case .wordpress: return "WordPress with pretty permalinks support"
        case .react: return "Single Page Application with history fallback"
        case .vue: return "Vue.js SPA with HTML5 history mode"
        case .nextjs: return "Next.js SSR with Node.js reverse proxy"
        case .angular: return "Angular SPA with base-href routing"
        case .reverseProxy: return "Proxy requests to a backend application"
        case .staticSite: return "Simple static HTML/CSS/JS files"
        case .djangoPython: return "Django WSGI with static files"
        case .railsRuby: return "Rails with Puma/Unicorn reverse proxy"
        }
    }

    var icon: String {
        switch self {
        case .laravel: return "chevron.left.forwardslash.chevron.right"
        case .wordpress: return "w.circle.fill"
        case .react, .vue, .angular: return "arrow.triangle.branch"
        case .nextjs: return "n.circle.fill"
        case .reverseProxy: return "arrow.left.arrow.right"
        case .staticSite: return "doc.text"
        case .djangoPython: return "p.circle.fill"
        case .railsRuby: return "r.circle.fill"
        }
    }

    /// Generate nginx site config from template
    func generateNginxConfig(domain: String, port: Int = 80, docRoot: String, backendPort: Int = 3000) -> String {
        switch self {
        case .laravel:
            return """
            server {
                listen \(port);
                server_name \(domain);
                root \(docRoot)/public;
                index index.php index.html;

                location / {
                    try_files $uri $uri/ /index.php?$query_string;
                }

                location ~ \\.php$ {
                    fastcgi_pass unix:/run/php/php-fpm.sock;
                    fastcgi_index index.php;
                    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                    include fastcgi_params;
                }

                location ~ /\\.(?!well-known).* {
                    deny all;
                }
            }
            """
        case .wordpress:
            return """
            server {
                listen \(port);
                server_name \(domain);
                root \(docRoot);
                index index.php index.html;

                location / {
                    try_files $uri $uri/ /index.php?$args;
                }

                location ~ \\.php$ {
                    fastcgi_pass unix:/run/php/php-fpm.sock;
                    fastcgi_index index.php;
                    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                    include fastcgi_params;
                }

                location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
                    expires 30d;
                    add_header Cache-Control "public, no-transform";
                }

                location ~ /\\.ht {
                    deny all;
                }
            }
            """
        case .react, .vue, .angular:
            return """
            server {
                listen \(port);
                server_name \(domain);
                root \(docRoot);
                index index.html;

                location / {
                    try_files $uri $uri/ /index.html;
                }

                location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
                    expires 1y;
                    add_header Cache-Control "public, immutable";
                }
            }
            """
        case .nextjs:
            return """
            server {
                listen \(port);
                server_name \(domain);

                location / {
                    proxy_pass http://127.0.0.1:\(backendPort);
                    proxy_http_version 1.1;
                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection 'upgrade';
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                    proxy_cache_bypass $http_upgrade;
                }
            }
            """
        case .reverseProxy:
            return """
            server {
                listen \(port);
                server_name \(domain);

                location / {
                    proxy_pass http://127.0.0.1:\(backendPort);
                    proxy_http_version 1.1;
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                }
            }
            """
        case .staticSite:
            return """
            server {
                listen \(port);
                server_name \(domain);
                root \(docRoot);
                index index.html;

                location / {
                    try_files $uri $uri/ =404;
                }

                location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
                    expires 30d;
                    add_header Cache-Control "public, no-transform";
                }
            }
            """
        case .djangoPython:
            return """
            server {
                listen \(port);
                server_name \(domain);

                location /static/ {
                    alias \(docRoot)/static/;
                    expires 30d;
                }

                location /media/ {
                    alias \(docRoot)/media/;
                    expires 30d;
                }

                location / {
                    proxy_pass http://127.0.0.1:\(backendPort);
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                }
            }
            """
        case .railsRuby:
            return """
            server {
                listen \(port);
                server_name \(domain);
                root \(docRoot)/public;

                location / {
                    try_files $uri @app;
                }

                location @app {
                    proxy_pass http://127.0.0.1:\(backendPort);
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                }

                location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
                    expires 1y;
                    add_header Cache-Control "public, immutable";
                }
            }
            """
        }
    }
}

// MARK: - Config Backup

struct SiteConfigBackup: Identifiable, Hashable {
    let id = UUID()
    let filename: String
    let date: Date
    let path: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Custom Error Page

struct CustomErrorPage: Identifiable, Hashable {
    let id = UUID()
    var statusCode: Int
    var pagePath: String
    var enabled: Bool

    static var defaults: [CustomErrorPage] {
        [
            CustomErrorPage(statusCode: 403, pagePath: "/errors/403.html", enabled: false),
            CustomErrorPage(statusCode: 404, pagePath: "/errors/404.html", enabled: false),
            CustomErrorPage(statusCode: 500, pagePath: "/errors/500.html", enabled: false),
            CustomErrorPage(statusCode: 502, pagePath: "/errors/502.html", enabled: false),
            CustomErrorPage(statusCode: 503, pagePath: "/errors/503.html", enabled: false),
        ]
    }
}
