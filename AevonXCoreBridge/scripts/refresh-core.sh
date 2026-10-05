#!/bin/bash
# ─────────────────────────────────────────────────────────────
# AevonXCoreBridge — refresh the pre-built Go Core framework
#
# FOR MAINTAINERS ONLY. Contributors never run this: the open repo already
# ships the compiled, closed-source framework at
#   AevonXCoreBridge/Frameworks/AevonXCore.xcframework
# and the app builds against it directly.
#
# When the private `core-go` source (expected as a sibling checkout of this
# repo) changes, run this to rebuild the hardened framework and copy the
# result back into Frameworks/. It is NOT part of the Xcode build — run it by
# hand, then commit the updated binary (tracked with Git LFS).
#
#   ./AevonXCoreBridge/scripts/refresh-core.sh
# ─────────────────────────────────────────────────────────────

set -euo pipefail

BRIDGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCFRAMEWORK_DEST="${BRIDGE_DIR}/Frameworks/AevonXCore.xcframework"

# The private Go source lives in a sibling checkout: <workspace>/core-go
CORE_GO_DIR="${BRIDGE_DIR}/../../core-go"

if [ ! -f "${CORE_GO_DIR}/go.mod" ]; then
    echo "error: private core-go source not found at ${CORE_GO_DIR}" >&2
    echo "       This script is for maintainers who have that checkout." >&2
    exit 1
fi

export PATH="/opt/homebrew/bin:/usr/local/go/bin:${HOME}/go/bin:${PATH}"
if ! command -v go >/dev/null 2>&1; then
    echo "error: Go is not installed. Install via: brew install go" >&2
    exit 1
fi

echo "→ Building hardened Go Core framework from ${CORE_GO_DIR}…"
cd "$CORE_GO_DIR"
# The obfuscating build is memory-hungry: compile one package at a time with
# a tighter GC so the machine stays responsive (slower, but no freezes).
export GOMAXPROCS=2
export GOFLAGS="-p=1"
export GOGC=50
make build                       # default target: hardened (obfuscated) XCFramework

echo "→ Refreshing ${XCFRAMEWORK_DEST}…"
rm -rf "$XCFRAMEWORK_DEST"
cp -R "${CORE_GO_DIR}/build/AevonXCore.xcframework" "$XCFRAMEWORK_DEST"

echo "✅ Done. Commit the updated binary:"
echo "   git add AevonXCoreBridge/Frameworks/AevonXCore.xcframework"
echo "   git commit -m 'chore: refresh AevonXCore framework'"
