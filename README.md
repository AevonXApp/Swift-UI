# AevonX (macOS UI)

AevonX is a native macOS server-management app: SSH, databases, websites,
Docker, plugins, and more from a single dashboard. This repository holds
the **open-source UI layer** — the SwiftUI views, view models, and a thin
Swift bridge that talks to the closed-source `AevonXCoreBridge` framework.

> **Scope of this repository.** Everything in `AevonX/AevonX/` is the
> open-source UI. All proprietary logic — networking, cryptography,
> SSH client, database adapters, license verification, etc. — lives in
> `AevonXCoreBridge` (a binary framework) and the AevonX backend, neither
> of which are part of this repository.

## What lives here

```
AevonX/
├── AevonX.xcodeproj/         # Xcode project
├── AevonX/                   # Source root
│   ├── Views/                # SwiftUI views (Dashboard, Settings, Profile…)
│   ├── ViewModels/           # @MainActor ObservableObject orchestrators
│   ├── Services/             # Keychain, biometrics, app-lock, OS-only stuff
│   ├── Helpers/              # CoreResult, error response mapping, etc.
│   ├── Localization/         # L10n.* enums + en.lproj/*.strings
│   ├── Components/           # Shared UI building blocks
│   └── Resources/            # Assets, icons, .strings files
├── LICENSE                   # MIT
└── README.md                 # this file
```

## What does NOT live here

| Concern | Where it lives | Why |
|---|---|---|
| HTTP requests / TLS / cert pinning | `AevonXCoreBridge` (Go-backed) | Network code stays in Go for cross-platform reuse and to keep server endpoints out of public source. |
| AES-GCM / HKDF / ECDH / Ed25519 | `AevonXCoreBridge` | Crypto stays in Go for the same reason. |
| SSH client + connection pool | `AevonXCoreBridge` | Same. |
| Database adapters (MySQL, PostgreSQL, MongoDB, …) | `AevonXCoreBridge` | Same. |
| License / subscription validation | Backend (`AevonX-Web`) | Authoritative server-side; the UI only renders the result. |
| Plugin marketplace + binary protection | Backend + `AevonXCoreBridge` | Tamper-resistant pipeline. |

## What the UI is allowed to do

- Render data and forward user actions to `AevonXCoreBridge`.
- Read from / write to the macOS Keychain via `Services/SecureSettingsStore.swift`,
  `Services/HostKeyStore.swift`, `Services/LockPasswordService.swift`.
- Handle biometric / app-lock prompts (`Services/BiometricAuthManager.swift`,
  `Services/LockPasswordService.swift`).
- Cache SSH command results (`Services/SSHResultCache.swift`).
- Manage in-app settings, theming, and navigation state.
- Localize strings via the `L10n.*` enums.

What the UI is NOT allowed to do — anywhere — is open a network socket,
construct an HTTP request, perform a cryptographic operation outside the
Keychain, or hardcode an API endpoint. These constraints are enforced by
`scripts/oss-audit.sh`; CI fails on a single critical violation.

## Building locally

```bash
# 1. Make sure the AevonXCoreBridge XCFramework is built (closed-source
#    repo; you'll need credentials for that one). Pre-built XCFrameworks
#    are published as binaryTargets under `core-go/build/AevonXCore.xcframework`.
# 2. Open AevonX.xcodeproj in Xcode 16 or later, macOS 14+ destination.
# 3. Build the AevonX scheme.
```

For headless / CI builds:

```bash
xcodebuild -project AevonX.xcodeproj -scheme AevonX \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

## Audits and pre-commit hygiene

Three scripts live in `../scripts/` (the parent of this UI repo):

- `oss-audit.sh` — fails CI if the UI grows a `URLSession`, `URLRequest`,
  raw crypto primitive, or hardcoded internal hostname. **Must stay at
  `0 critical`.**
- `l10n-audit.sh` — fails if any `L10n.X.y` reference points at a missing
  declaration, or if any user-facing `Text("…")` / `navigationTitle("…")`
  literal sneaks back in. **Must stay at `0 missing-decl, 0 hardcoded`.**
- `migration-parity.sh` — utility for comparing ViewModel state snapshots
  across migration phases.

Run them all:

```bash
bash scripts/oss-audit.sh && bash scripts/l10n-audit.sh
```

## Architecture in 60 seconds

```
SwiftUI View
    ↓  reads @Published state, dispatches actions
ViewModel (@MainActor ObservableObject)
    ↓  calls APIBridge.shared.<method>Async(...)
AevonXCoreBridge (Swift wrapper, closed source)
    ↓  CGo FFI
core-go (Go backend, closed source)
    ↓  HTTPS + ECDH secure channel
AevonX-Web backend (Laravel)
```

Everything below the second arrow is closed source. Everything above it is
in this repository.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE). The AevonXCoreBridge binary framework and the AevonX-Web
backend are NOT covered by this license — they are distributed separately.
