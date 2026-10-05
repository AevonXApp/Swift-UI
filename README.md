# AevonX (macOS UI)

AevonX is a native macOS server-management app: SSH, databases, websites,
Docker, plugins, and more from a single dashboard. This repository holds
the **open-source client** — the SwiftUI app, its view models and services,
and the Swift bridge that talks to the AevonX Go Core.

> **What is open here.** The entire macOS client is open source: the SwiftUI
> views, the `@MainActor` view models, the on-device services, and the
> `AevonXCoreBridge` Swift wrappers. The one closed component is the Go Core
> itself, which ships as a **pre-built binary framework** (`AevonXCore.xcframework`)
> committed to this repo so the app builds and runs with no extra access. Its
> Go source, and the AevonX backend, are distributed under separate terms.

## What lives here

```
AevonX/
├── AevonX.xcodeproj/             # Xcode project
├── AevonX/                       # App source root
│   ├── Views/                    # SwiftUI views (Dashboard, Settings, Profile…)
│   ├── ViewModels/               # @MainActor ObservableObject orchestrators
│   ├── Services/                 # Keychain, biometrics, app-lock, OS-only stuff
│   ├── Helpers/                  # CoreResult, error response mapping, etc.
│   ├── Localization/             # L10n.* enums + en.lproj/*.strings
│   ├── Components/               # Shared UI building blocks
│   └── Resources/                # Assets, icons, .strings files
├── AevonXCoreBridge/             # Local Swift package — the Core bridge
│   ├── Package.swift             #   binary Go Core + open Swift wrappers
│   ├── Sources/AevonXCoreBridge/ #   OPEN SOURCE: thin FFI wrappers (Swift)
│   └── Frameworks/
│       └── AevonXCore.xcframework/  # CLOSED binary: compiled, hardened Go Core (Git LFS)
├── LICENSE                       # MIT
└── README.md                     # this file
```

## The Core bridge — open wrappers over a closed binary

`AevonXCoreBridge/` is a local Swift package with two halves:

| Half | What it is | Source? |
|---|---|---|
| `Sources/AevonXCoreBridge/*.swift` | Thin, auditable Swift wrappers around the Go Core's C FFI. No secrets — every endpoint, key, and protocol lives on the far side of the bridge. | **Open** |
| `Frameworks/AevonXCore.xcframework` | The compiled Go Core, built hardened (symbol/string obfuscation, anti-tamper) and shipped as a static library. | **Closed binary** |

The binary is tracked with **Git LFS**. A normal checkout pulls it
automatically and the app builds — you never need the Go source.

## What does NOT live here

| Concern | Where it lives | Why |
|---|---|---|
| Go Core **source** (HTTP/TLS, crypto, SSH client, DB adapters, license, plugin pipeline) | Private `core-go` repo; shipped here only as a compiled binary | Kept in Go for cross-platform reuse and to keep endpoints/keys out of source. |
| License / subscription validation | Backend (`AevonX-Web`) | Authoritative server-side; the UI only renders the result. |
| Plugin marketplace + binary protection | Backend + Go Core | Tamper-resistant pipeline. |

## What the UI is allowed to do

- Render data and forward user actions through `AevonXCoreBridge`.
- Read from / write to the macOS Keychain via `Services/SecureSettingsStore.swift`,
  `Services/HostKeyStore.swift`, `Services/LockPasswordService.swift`.
- Handle biometric / app-lock prompts (`Services/BiometricAuthManager.swift`,
  `Services/LockPasswordService.swift`).
- Cache SSH command results (`Services/SSHResultCache.swift`).
- Manage in-app settings, theming, and navigation state.
- Localize strings via the `L10n.*` enums.

What the app code is NOT allowed to do — anywhere — is open a network socket,
construct an HTTP request, perform a cryptographic operation outside the
Keychain, or hardcode an API endpoint. All of that happens inside the Go Core,
reached only through the bridge.

## Building locally

You need **Xcode 16+** on **macOS 14+**, and **Git LFS** (so the Core binary
comes down with the clone):

```bash
brew install git-lfs && git lfs install   # once per machine
git clone <this-repo> && cd AevonX
git lfs pull                               # fetch AevonXCore.xcframework
open AevonX.xcodeproj                       # build the AevonX scheme
```

That's it — the pre-built `AevonXCore.xcframework` is already in the repo, so
there are no credentials or extra downloads to build the app.

For headless / CI builds:

```bash
xcodebuild -project AevonX.xcodeproj -scheme AevonX \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

> **Maintainers with Go source.** The Xcode build never rebuilds the Core —
> it always uses the committed binary. When the private `core-go` checkout
> sits beside this repo and its Go source changes, run
> `AevonXCoreBridge/scripts/refresh-core.sh` by hand to rebuild the hardened
> framework and refresh it in `Frameworks/`, then commit the updated binary.

## Architecture in 60 seconds

```
SwiftUI View                          ┐
    ↓  reads @Published state,        │
       dispatches actions             │  open source
ViewModel (@MainActor ObservableObject)│  (this repo)
    ↓  calls Service / Bridge         │
AevonXCoreBridge (Swift wrappers)     ┘
    ↓  C FFI
AevonXCore.xcframework (compiled Go)  ┐  closed binary (shipped here)
    ↓  HTTPS + ECDH secure channel    ┘
AevonX-Web backend (Laravel)             closed service
```

Everything above the FFI line is open source and in this repository. The Go
Core below it is a compiled binary; its source and the backend are separate.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) — covers the source in this repository: the macOS client and
the `AevonXCoreBridge` Swift wrappers. The `AevonXCore.xcframework` binary and
the AevonX backend are NOT covered by this license and are distributed under
separate terms.
