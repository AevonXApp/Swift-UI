# AevonX UI — SwiftUI Guidelines

> **For AI assistants working on the AevonX SwiftUI app.**
> Breaking these rules causes compilation errors and inconsistent UI.

> [!CAUTION]
> **NEVER deviate from user instructions.** Read existing code before creating anything new.
> **NEVER write fake progress.** No hardcoded percentages.

---

## 1. Architecture — Views ↔ ViewModels ↔ Go Core

```
View (SwiftUI)  →  ViewModel (@Published)  →  Go Core Bridge  →  Remote Server
                                             ← BridgeResponse ←
```

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Views** | `Views/Dashboard/{Feature}/` | UI-only — display data, call VM methods |
| **ViewModels** | `Views/Dashboard/{Feature}/ViewModels/` | Hold `@Published` state, call bridge |
| **Go Core Bridge** | `AevonXCoreBridge` (SPM) | Swift wrappers around Go C exports |

### Rules
- Views do NOT execute SSH commands, parse output, or contain business logic
- ViewModels use `SSHBridge.shared.executeAsync()` + bridge command builders
- Use `@StateObject` for ownership, `@ObservedObject` for passed-in VMs
- All server operations go through Go Core — no direct SSH in Views

---

## 2. Path Resolution — NEVER Hardcode

```swift
// ❌ FORBIDDEN:
let log = "/var/log/nginx/access.log"
let config = "/etc/nginx/sites-available/"

// ✅ CORRECT:
await detectPathsIfNeeded()
let config = serverPaths.nginxSitesAvailable
let log = serverPaths.nginxLogDir
let mainConf = serverPaths.nginxMainConf
```

### `resolveConfigPath()` — BT Panel `.conf` Extension
```swift
private func resolveConfigPath() -> String {
    let sa = serverPaths.nginxSitesAvailable
    if serverPaths.serverType == "bt_panel" || sa.contains("/www/server") ||
       sa.contains("/conf.d") || sa.contains("/vhost") {
        return "\(sa)/\(domain).conf"
    }
    return "\(sa)/\(domain)"
}
```

Every ViewModel that touches server paths MUST call `detectPathsIfNeeded()` first.

---

## 3. Design System — AX Tokens Only

All UI uses tokens from `AevonX/Views/Components/AXDesignSystem.swift` and `Theme/AevonXColors.swift`.

### Typography — `AXTypography`
```swift
// ❌ FORBIDDEN:
.font(.system(size: 14, weight: .medium))

// ✅ CORRECT:
.font(AXTypography.body)
.font(AXTypography.caption)
.font(AXTypography.headline)
.font(AXTypography.monoMd)      // Code/logs
```

### Spacing — `AXSpacing`
```swift
// ❌ .padding(8)  ✅ .padding(AXSpacing.sm)
// ❌ .padding(16) ✅ .padding(AXSpacing.lg)
```

### Corner Radius — `AXCornerRadius`
```swift
// ❌ .cornerRadius(8)  ✅ .cornerRadius(AXCornerRadius.md)
// ❌ .cornerRadius(12) ✅ .cornerRadius(AXCornerRadius.lg)
```

### Colors — `Color.axXxx`
```swift
.foregroundColor(.axTextPrimary)
.background(Color.axSurface)
Color.axSuccess / .axWarning / .axError / .axAccentBlue
```

---

## 4. Reusable Components

### Global (`Views/Components/`)
| Component | Usage |
|-----------|-------|
| `AXGlassCard` | Glassmorphic card container |
| `AXStatusBadge` | Online/offline/warning indicators |
| `AXPrimaryButton` | Primary action buttons |
| `AXTextField` | Styled input with validation |
| `GlobalToastManager` | Toast notifications |
| `SkeletonLoadingView` | Loading skeleton placeholders |

### Dashboard (`Views/Dashboard/Components/`)
| Component | Usage |
|-----------|-------|
| `AXLogTable` | Flexible log table — caller defines columns/rows |
| `AXTabs` | Tab bar component |
| `AXCodeEditor` | Code editor view |

### Skeleton Loading
Use `AXSkeletonRow`, `AXSkeletonBlock`, `AXSkeletonStatCard` for loading states.
**Never** use bare `ProgressView()` in content areas.

---

## 5. Installation System — Quick Install

All long-running installs (PHP, Nginx, databases) go through `QuickInstallViewModel`:
- nohup scripts — survives SSH disconnect
- State file polling every 3s
- `QuickInstallBubble` — floating progress across tabs

Fast operations (uninstall, toggle) can use direct bridge calls.

---

## 6. File Organization

```
Views/Dashboard/{Feature}/
├── Views/
│   ├── Sections/{Category}/     → Section views
│   └── Components/              → Feature-specific components
├── ViewModels/
│   ├── Core/                    → Main VMs
│   ├── Config/                  → Config-related VMs
│   ├── Security/                → Security VMs
│   └── Tools/                   → Tool VMs
└── Models/                      → UI-specific models
```

> Each struct gets its own file. Never put multiple section structs in one file.

---

## 7. Connection to Go Core

The UI connects to Go Core via `AevonXCoreBridge` (Swift Package at `core-go/swift-bridge/`).

### Bridge Pattern
```swift
let bridge = WebsitesBridge.shared
let cmd = bridge.createSiteCmd(config: siteConfig)
let result = await SSHBridge.shared.executeAsync(serverID: id, command: cmd)
let parsed = bridge.parseCreateResult(output: result)
```

### Path Detection
```swift
let cmd = PathResolverBridge.shared.detectCmd()
let output = await SSHBridge.shared.executeAsync(serverID: id, command: cmd)
serverPaths = PathResolverBridge.shared.parse(output: output)
```

---

## 8. Common Mistakes

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `result.exitStatus` | `result.exitCode` or `.isSuccess` |
| Raw `.font(.system(size: N))` | `AXTypography.xxx` tokens |
| Hardcoded `/etc/nginx/` paths | `serverPaths.nginxSitesAvailable` |
| SSH in Views | SSH only in ViewModels via bridge |
| `ProgressView()` for loading | Skeleton components |
| Copy-paste SSH logic | Shared bridge methods |

---

## 9. Build Checklist

- [ ] Compiles without errors (`Cmd+B`)
- [ ] No raw design values — all AX tokens
- [ ] No hardcoded server paths
- [ ] Views are UI-only — no business logic
- [ ] Existing components reused
- [ ] `detectPathsIfNeeded()` called before path use

---

## 8. Activity Logging API

Log client-side events to the backend via Go Core bridge (encrypted binary).
Fire-and-forget — never blocks the caller. Silent failure if network is unavailable.

### Usage (via Go Core — encrypted)

```swift
Task {
    guard let token = await AevonXCoreBridge.AuthService.shared.getToken() else { return }
    let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
    _ = await APIBridge.shared.logActivityAsync(
        baseURL: baseURL, token: token,
        type: "ssh_command",
        description: "Executed command",
        context: "apt update"
    )
}
```

### Supported Types

| Type | Description | Icon | Color |
|------|-------------|------|-------|
| `ssh_connect` | Server connection | bolt.fill | green |
| `ssh_disconnect` | Server disconnection | bolt.slash | gray |
| `ssh_command` | SSH command executed | terminal | cyan |
| `ssh_error` | SSH error occurred | exclamationmark.triangle | red |
| `registration` | Account created | person.badge.plus | blue |
| `login` | User signed in | arrow.right.circle | green |
| `logout` | User signed out | arrow.left.circle | gray |
| `password_changed` | Password changed | lock.rotation | orange |
| `server_added` | Server added | server.rack | blue |
| `server_deleted` | Server deleted | trash | red |

### Backend

- **Endpoint:** `POST /api/v1/user/activity`
- **Body:** `{ "type": string, "description": string, "context"?: string }`
- Custom types are accepted — add icon/color mapping in `ActivityLog.php`

---

> **Last Updated:** 2026-03-21

