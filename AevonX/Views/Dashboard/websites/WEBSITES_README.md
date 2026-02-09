# Websites Module

**Production-ready website management module following AevonX architecture patterns**

## 📁 Architecture

This module follows the exact same 3-tier architecture as the `databases` module:

```
websites/
├── Models/           # Domain models
├── ViewModels/       # @MainActor ViewModels
├── Services/         # UI-layer services
└── Views/            # Pure SwiftUI views
    └── Components/   # Reusable components
```

## 🏗️ Architecture Layers

### **Models Layer** - Domain Logic
- `WebsiteInfo.swift` - Main website entity with all metadata
- `SSLInfo.swift` - SSL certificate information
- `WebsiteHealthIssue.swift` - Health monitoring models

**Key Features:**
- Strong typing with enums (`WebsiteStatus`, `RuntimeType`, `DeploymentStatus`)
- Computed properties for formatting (`formattedDiskUsage`, `isHealthy`)
- No networking or business logic
- Codable for persistence

### **ViewModels Layer** - State Management
- `WebsiteManagementViewModel.swift` - Main ViewModel coordinating all operations
- `AddWebsiteViewModel.swift` - Website creation with validation

**Key Features:**
- `@MainActor` for thread safety
- `@Published` properties for reactive UI
- Interfaces with `CoreWebsiteService` from AevonXCore
- NEVER executes SSH commands directly
- Comprehensive error handling
- Loading states and connection management

### **Services Layer** - Business Operations
- `WebsiteOperationService.swift` - Website lifecycle operations
- `CoreWebsiteService+Stub.swift` - Temporary stub (to be moved to AevonXCore)

**Key Features:**
- Singleton pattern
- Operation progress tracking
- Health checks and SSL management
- All operations go through Core layer

### **Views Layer** - UI Components
- `ModernWebsitesTab.swift` - Main tab view
- `WebsiteDetailView.swift` - Individual website details
- `AddWebsiteView.swift` - Website creation modal
- `Components/` - Reusable UI components

**Key Features:**
- Pure SwiftUI, no business logic
- State driven by ViewModels
- Loading/error/empty states
- Accessibility support

## 🔄 Data Flow

```
User Action
    ↓
SwiftUI View
    ↓
ViewModel (@Published)
    ↓
CoreWebsiteService (AevonXCore)
    ↓
SSH/API Execution
    ↓
Server Response
    ↓
Core Models → UI Models
    ↓
ViewModel Updates
    ↓
SwiftUI View Updates
```

## 🚫 No Mock Data

**This module contains ZERO mock data:**
- ❌ No hardcoded arrays
- ❌ No fake UI state
- ❌ No placeholder models
- ✅ All data from `CoreWebsiteService.shared`
- ✅ Real server operations
- ✅ Proper error handling

## 🔌 Backend Integration

### CoreWebsiteService (AevonXCore)

The UI layer depends on `CoreWebsiteService` from AevonXCore package:

```swift
public final class CoreWebsiteService {
    public static let shared: CoreWebsiteService

    // Website CRUD
    func listWebsites(serverId: String) async throws -> [CoreWebsiteInfo]
    func createWebsite(...) async throws
    func deleteWebsite(...) async throws

    // Lifecycle
    func startWebsite(...) async throws
    func stopWebsite(...) async throws
    func restartWebsite(...) async throws

    // Deployment
    func deployWebsite(...) async throws

    // SSL
    func enableSSL(...) async throws
    func renewSSL(...) async throws

    // Health
    func checkWebsiteHealth(...) async throws -> CoreWebsiteHealth
}
```

### Current Status

⚠️ **CoreWebsiteService is currently stubbed** in `CoreWebsiteService+Stub.swift`

This temporary stub:
- Logs warnings when methods are called
- Returns empty arrays or throws `notImplemented` errors
- Will be moved to AevonXCore package with real SSH implementation

### TODO: Implement in AevonXCore

1. Move all `Core*` models to AevonXCore
2. Implement SSH command execution for each operation
3. Parse server responses into Core models
4. Handle errors and edge cases
5. Add caching and optimization

## 📊 Comparison with Databases Module

| Aspect | Databases Module | Websites Module |
|--------|-----------------|-----------------|
| **Architecture** | 3-tier (Models/ViewModels/Services) | ✅ Same |
| **ViewModel Pattern** | `DatabaseManagementViewModel` | ✅ `WebsiteManagementViewModel` |
| **Core Service** | `CoreDatabaseService.shared` | ✅ `CoreWebsiteService.shared` |
| **Loading States** | Full loading/error/empty | ✅ Same |
| **Connection Check** | Required `ServerConnectionViewModel` | ✅ Same |
| **Domain Models** | `DatabaseInfo`, `DatabaseStatus` | ✅ `WebsiteInfo`, `WebsiteStatus` |
| **Detail View** | `DatabaseDetailView` | ✅ `WebsiteDetailView` |
| **Create Modal** | `AddDatabaseView` | ✅ `AddWebsiteView` |
| **No Mock Data** | ✅ Real data only | ✅ Real data only |

## 🎯 Usage

### In Dashboard Navigation

Replace the old `WebsitesTab` with `ModernWebsitesTab`:

```swift
// OLD (mock data):
WebsitesTab()

// NEW (production):
ModernWebsitesTab(
    server: selectedServer,
    serverId: selectedServer?.id.uuidString,
    connectionViewModel: connectionViewModel
)
```

### Creating a Website

```swift
// User clicks "Add Website"
viewModel.showAddWebsite = true

// AddWebsiteView appears
// User fills form and clicks "Create"
// AddWebsiteViewModel validates and calls:
try await CoreWebsiteService.shared.createWebsite(...)

// On success, WebsiteManagementViewModel reloads:
await viewModel.loadData()
```

### Toggling Website Status

```swift
// User toggles switch in WebsiteRow
try await viewModel.toggleWebsite(website)

// WebsiteManagementViewModel calls:
if website.status == .online {
    try await CoreWebsiteService.shared.stopWebsite(...)
} else {
    try await CoreWebsiteService.shared.startWebsite(...)
}

// Reloads data to reflect new state
await viewModel.loadData()
```

## 🧪 Testing Strategy

### Unit Tests (ViewModels)
```swift
// Test ViewModel logic without UI
func testFilterWebsites() {
    let viewModel = WebsiteManagementViewModel(...)
    viewModel.allWebsites = mockWebsites
    viewModel.searchText = "api"
    XCTAssertEqual(viewModel.filteredWebsites.count, 2)
}
```

### Integration Tests (Services)
```swift
// Test Core service integration
func testLoadWebsites() async {
    let viewModel = WebsiteManagementViewModel(...)
    await viewModel.loadData()
    XCTAssertFalse(viewModel.allWebsites.isEmpty)
}
```

### UI Tests (Views)
```swift
// Test user interactions
func testCreateWebsite() {
    app.buttons["Add Website"].tap()
    app.textFields["Domain Name"].typeText("example.com")
    app.buttons["Create Website"].tap()
    // Assert success
}
```

## 📝 Migration Checklist

When moving from old `WebsitesTab.swift` to this module:

- [x] ✅ Create folder structure matching databases module
- [x] ✅ Implement all domain models without mock data
- [x] ✅ Create ViewModels with Core service integration
- [x] ✅ Build UI layer with loading/error states
- [x] ✅ Stub CoreWebsiteService for compilation
- [ ] ⚠️ Implement CoreWebsiteService in AevonXCore (TODO)
- [ ] ⚠️ Update dashboard navigation to use ModernWebsitesTab
- [ ] ⚠️ Remove old WebsitesTab.swift file
- [ ] ⚠️ Test all operations with real server

## 🚀 Next Steps

1. **Implement CoreWebsiteService in AevonXCore**
   - Move Core models to package
   - Implement SSH commands for each operation
   - Add proper error handling

2. **Update Navigation**
   - Replace `WebsitesTab` with `ModernWebsitesTab`
   - Pass server and connection ViewModels

3. **Test with Real Server**
   - Connect to actual server
   - Test all CRUD operations
   - Verify SSL operations
   - Test deployment flow

4. **Add Advanced Features**
   - Log streaming
   - Real-time metrics
   - Deployment pipelines
   - SSL auto-renewal

## 📚 Related Files

- Reference: `Views/Dashboard/databases/` - Architecture template
- Old file: `Views/Dashboard/Tabs/WebsitesTab.swift` - To be deprecated
- Core: `AevonXCore/Sources/CoreWebsiteService.swift` - To be implemented

## 🤝 Contributing

When adding features to this module:

1. ✅ Follow the same patterns as databases module
2. ✅ Keep UI and business logic separated
3. ✅ Use Core services for all server operations
4. ✅ Add loading states and error handling
5. ✅ Never use mock data
6. ✅ Write comprehensive tests

---

**Architecture Status:** ✅ Production-Ready (pending CoreWebsiteService implementation)

**Mock Data:** ❌ None (100% real data flow)

**Consistency:** ✅ Matches databases module architecture
