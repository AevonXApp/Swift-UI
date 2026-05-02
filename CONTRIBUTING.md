# Contributing to the AevonX UI

Thanks for considering a contribution! A few rules keep the open-source UI
useful long-term.

## The hard rules (CI enforces these)

These three audits run on every PR. If any of them fails, the PR is blocked.

```bash
bash scripts/oss-audit.sh   # must end with "0 critical"
bash scripts/l10n-audit.sh  # must end with "0 missing-decl, 0 hardcoded"
xcodebuild ... build        # must succeed
```

### 1. No raw networking in the UI

The UI is a renderer. All HTTP, TLS, and request signing happen in
`AevonXCoreBridge` / `core-go`. If you need a new endpoint:

1. Add a Go function in `core-go/pkg/api/`.
2. Expose it via a `bridge/exports_*.go` C symbol.
3. Wrap it in `core-go/swift-bridge/Sources/AevonXCoreBridge/.../*Bridge.swift`.
4. Call the wrapper from your `Services/` or `ViewModels/` Swift code via
   `APIBridge.shared.<method>Async(...)`.

Never reach for `URLSession`, `URLRequest`, or `HTTPURLResponse` directly.
The audit will reject the PR.

### 2. No raw crypto in the UI

`CryptoKit` primitives (`AES.GCM`, `HKDF`, `Curve25519`, `SHA256.hash`, etc.)
must stay inside `AevonXCoreBridge`. The lone exception is
`Services/LockPasswordService.swift`, which hashes the local app-lock
password before storing it in the Keychain — that data never leaves the
device, never crosses the bridge, and is intentionally allowlisted.

### 3. Every user-facing string goes through `L10n`

```swift
// ❌ Don't
Text("Connection failed")

// ✅ Do
Text(L10n.Status.connectionFailed)
```

If the right enum case doesn't exist, add one to the relevant
`Localization/L10n+<Namespace>.swift` file:

```swift
static let connectionFailed = s("status.connectionFailed", "Connection Failed")
```

The `s(...)` helper provides an English `defaultValue`, so the app keeps
working even before translators fill in `Resources/<lang>.lproj/*.strings`.

You can run the codemod for big sweeps:

```bash
python3 scripts/l10n-codemod.py path/to/YourView.swift
```

### 4. No hardcoded internal hosts

`api.aevonx.io`, `app.aevonx.io`, `admin.aevonx.com`, etc. must not appear
in source. The base URL is read from `ConfigurationManager.shared` at
runtime, which gets it from the bridge. Use `*.example.com` /
`example-1.test` for sample/demo data.

### 5. Don't reference a user's location

Per the project privacy policy, do not log, render, or otherwise mention
country/city/GeoIP data anywhere in the UI. The backend may use IP-based
location for anomaly detection internally; that data must never reach the
client UI.

## Patterns we like

- **Thin ViewModels.** `func login(...) async { let json = await APIBridge.shared.loginAsync(...); applyResult(json) }`. The orchestration belongs in Go.
- **Shared `CoreResult` helper.** Every Go bridge call returns a JSON envelope `{success, data, error}`. Use `CoreResult.parse(...)`, `CoreResult.ensureSuccess(...)`, or `CoreResult.decodePayload(...)` instead of re-implementing the parser.
- **`AXSpacing` / `AXCornerRadius` / `AXTypography` / `AXColors`.** Don't hardcode numeric padding or hex colors; use the design tokens.
- **Full-page detail views, not sheets.** Per project convention, domain detail screens are inline pages with charts and filters, not `.sheet()` popups.
- **One `static let` per L10n key.** The codemod dedupes within a file but the prune script removes orphans within a single namespace — keep declarations clean.

## Patterns we don't want

- `if #available(macOS 13.0, *)` guards — minimum target is macOS 14, so they're dead code.
- Backwards-compatibility shims (`@available(deprecated)` re-exports, renamed `_oldVar` placeholders, "removed in v3" comment markers). Just delete.
- `#if DEBUG` feature flags or "experimental" toggles. Ship it or don't.
- Hardcoded year strings (e.g. copyright `"© 2024"`). Use a dynamic year. The audit will eventually flag these.

## How to localize a missing key

```swift
// 1. Add the case in the right L10n+<NS>.swift file:
static let myNewLabel = s("namespace.myNewLabel", "My New Label")

// 2. Reference it in the view:
Text(L10n.MyNamespace.myNewLabel)

// 3. (Later, when translating) add to Resources/ar.lproj/MyNamespace.strings:
//    "namespace.myNewLabel" = "تسمية جديدة";
```

Until step 3 happens, the app shows the English `defaultValue`. That's fine.

## Filing a PR

1. Fork, branch, write the change.
2. Run the three audits + Xcode build.
3. Open a PR with:
   - **What** — the user-visible change.
   - **Why** — what motivated it (link an issue, describe the bug, etc.).
   - **How verified** — manual test plan or a screenshot of the audits passing.
4. A maintainer reviews, runs full integration tests against a staging
   `AevonXCoreBridge`, and merges or asks for changes.

## Getting unstuck

- **Build fails because `AevonXCoreBridge` is missing.** You need access
  to a pre-built XCFramework in `../core-go/build/AevonXCore.xcframework`.
  That repo is closed-source; ask a maintainer if you don't have it.
- **Codesigning errors.** Build with the env overrides shown in the README
  to skip signing locally.
- **`L10n.Foo.bar` doesn't compile.** The case is missing — add it to
  `Localization/L10n+<NS>.swift`. The codemod will do it for you on a
  whole file: `python3 scripts/l10n-codemod.py path/to/file.swift`.
