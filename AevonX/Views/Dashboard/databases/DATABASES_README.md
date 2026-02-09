# AevonX Database Management System

## Overview

The Database Management System in AevonX provides comprehensive control over server databases with AI-assisted installation capabilities. This module follows the three-layer architecture (UI → Core → Backend) to ensure security, modularity, and scalability.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer (AevonX)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Views     │  │ ViewModels  │  │   UI Services           │  │
│  │  - Cards    │  │  - State    │  │  - Installation Coord.  │  │
│  │  - Forms    │  │  - Logic    │  │  - User Actions         │  │
│  │  - Sheets   │  │  - Binding  │  │  - Event Handling       │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼────────────────────┼────────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Core Layer (AevonXCore)                   │
│  ┌─────────────────┐  ┌──────────────────────────────────────┐  │
│  │  AIInstallation │  │         SSHConnectionService         │  │
│  │    API Service  │  │  - Command execution on remote servers│  │
│  │  - Backend API  │  │  - Connection pooling                │  │
│  │  - AI requests  │  │  - Security enforcement                │  │
│  └────────┬────────┘  └──────────────────┬───────────────────┘  │
└───────────┼──────────────────────────────┼──────────────────────┘
            │                              │
            ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Backend Layer (AevonX-Web)                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              AI Installation Controller                   │   │
│  │  - Receives server data from Core                         │   │
│  │  - Sends to Gemini AI for analysis                        │   │
│  │  - Returns OS-compatible recommendations                  │   │
│  │  - Generates installation commands                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
databases/
├── Models/
│   ├── DatabaseType.swift          # Database type definitions and metadata
│   ├── DatabaseInfo.swift          # Database instance information
│   └── AIInstallationModels.swift  # AI installation request/response models
├── ViewModels/
│   └── DatabaseManagementViewModel.swift  # Main ViewModel for database management
├── Services/
│   ├── DatabaseCommandService.swift       # Server command execution
│   └── DatabaseInstallationService.swift  # Installation coordination
├── Views/
│   ├── DatabaseTypeCard.swift     # Database type card component
│   └── AIInstallationView.swift   # AI installation interface
├── Components/                     # Shared UI components
├── Installation/                   # Installation-specific components
└── README.md                       # This file
```

## Layer Responsibilities

### 1. UI Layer (AevonX)

**Files:**
- `Views/DatabaseTypeCard.swift` - Shows database type with install/manage actions
- `Views/AIInstallationView.swift` - AI installation wizard interface
- `ViewModels/DatabaseManagementViewModel.swift` - State management and business logic
- `Services/DatabaseInstallationService.swift` - Coordinates installation flow

**Responsibilities:**
- Display database information and status
- Handle user interactions (install, manage, configure)
- Coordinate with Core layer for server operations
- Manage UI state and navigation

**Key Classes:**
- `DatabaseManagementViewModel` - Main ViewModel exposing database data and operations
- `DatabaseInstallationService` - Handles installation workflow

### 2. Core Layer (AevonXCore)

**Files:**
- `Services/AIInstallationAPIService.swift` - Backend API communication
- `Services/SSHConnectionService.swift` - SSH command execution

**Responsibilities:**
- Execute SSH commands on remote servers securely
- Communicate with backend API for AI recommendations
- Handle encryption/decryption of sensitive data
- Enforce security policies

**Key Classes:**
- `AIInstallationAPIService` - Gets AI recommendations from backend
- `SSHConnectionService` - Executes commands on remote servers

### 3. Backend Layer (AevonX-Web)

**Responsibilities:**
- Receive server OS and resource information from Core
- Send data to Gemini AI for analysis
- Return OS-compatible database versions
- Generate installation commands for detected package managers

**API Endpoints (to be implemented):**
- `POST /api/v1/ai-installation/recommendations` - Get AI recommendations
- `POST /api/v1/ai-installation/start` - Start installation tracking
- `POST /api/v1/ai-installation/progress/{id}` - Update installation progress
- `GET /api/v1/ai-installation/progress/{id}` - Get installation progress

## Features

### 1. Database Type Detection

The system automatically detects which database engines are installed on the server:

```swift
let states = await commandService.detectInstalledDatabases(serverId: serverId)
// Returns: [MySQL: Installed, PostgreSQL: Not Installed, Redis: Installed, ...]
```

### 2. AI-Assisted Installation

When a database is not installed, the AI system:

1. **Gathers Server Information:**
   - OS type and version
   - Package manager (apt, yum, dnf, etc.)
   - Available resources (RAM, disk, CPU)
   - Existing databases

2. **Sends to Backend:**
   ```swift
   let request = AIInstallationRequest(
       databaseType: .redis,
       serverOSInfo: osInfo,
       serverResources: resources,
       useCase: .caching
   )
   ```

3. **Receives Recommendations:**
   - Compatible database versions
   - Installation commands for the specific OS
   - Post-installation configuration
   - Security warnings

4. **Executes Installation:**
   - Runs commands step-by-step
   - Reports progress to backend
   - Validates each step

### 3. Database Management

For installed databases, users can:
- View database list and statistics
- Start/stop/restart services
- Create/delete databases
- Manage users and permissions
- Configure settings

## Usage Examples

### Check Installation Status

```swift
let viewModel = DatabaseManagementViewModel(serverId: "server-123")
await viewModel.loadData()

// Check if MySQL is installed
if viewModel.isDatabaseInstalled(.mysql) {
    // Show manage button
} else {
    // Show install button
}
```

### Get AI Recommendations

```swift
let recommendations = try await viewModel.getInstallationRecommendations(
    for: .redis,
    useCase: .caching
)

// Show recommended versions to user
for version in recommendations.recommendations {
    print("Version: \(version.version)")
    print("Compatibility: \(version.compatibilityScore)%")
    print("Reasoning: \(version.reasoning)")
}
```

### Start Installation

```swift
try await installationService.startInstallation(
    databaseType: .redis,
    version: "7.2.0",
    serverId: "server-123",
    recommendation: aiResponse
)

// Monitor progress
installationService.$currentInstallation
    .sink { progress in
        print("Progress: \(progress?.progressPercentage ?? 0)%")
    }
```

### Service Management

```swift
// Start MySQL service
try await viewModel.startService(type: .mysql)

// Stop PostgreSQL
try await viewModel.stopService(type: .postgresql)

// Restart Redis
try await viewModel.restartService(type: .redis)
```

## Supported Database Types

| Database | Category | Default Port | Service Names |
|----------|----------|--------------|---------------|
| MySQL | Relational | 3306 | mysql, mysqld |
| PostgreSQL | Relational | 5432 | postgresql, postgres |
| Redis | Cache | 6379 | redis, redis-server |
| MongoDB | Document | 27017 | mongodb, mongod |
| MariaDB | Relational | 3306 | mariadb, mysql |
| SQLite | Relational | - | File-based |
| CockroachDB | Relational | 5432 | cockroach |
| Cassandra | Document | 9042 | cassandra |
| Elasticsearch | Search | 9200 | elasticsearch |

## Security Considerations

1. **Command Templates:** All commands use predefined templates to prevent injection
2. **Input Sanitization:** All user inputs are sanitized before execution
3. **SSH Security:** Connections use CAT (Connection Authorization Tokens)
4. **Zero-Knowledge:** Backend never sees server credentials
5. **Validation:** Each installation step is validated before proceeding

## Future Enhancements

- [ ] Database backup and restore
- [ ] Replication configuration
- [ ] Performance monitoring
- [ ] Query analyzer
- [ ] Automated security updates
- [ ] Multi-node cluster management

## Contributing

When adding new database types:

1. Add to `DatabaseType.swift` enum
2. Define package names for each package manager
3. Add service detection patterns
4. Update AI models if needed
5. Add UI components for the new type

## License

This module is part of the AevonX project and follows the same licensing terms.