// swift-tools-version:5.9
import PackageDescription

// AevonXCoreBridge
// ================
// Open-source Swift bridge over the AevonX Go Core.
//
//   • Sources/AevonXCoreBridge  — this is OPEN SOURCE. Thin, auditable Swift
//     wrappers around the C FFI exported by the Go Core. They contain no
//     secrets: every endpoint, key, and protocol lives behind the bridge.
//
//   • Frameworks/AevonXCore.xcframework — this is a CLOSED, pre-built binary.
//     It is the compiled (hardened) Go Core, shipped as a static library so
//     the open UI can build and run without access to the private Go source.
//     The Go source is NOT part of this repository and is distributed under
//     separate terms.
//
// Rebuilding the binary requires the private `core-go` repository. A normal
// contributor never needs to: the pre-built framework in Frameworks/ is all
// the open UI links against.
let package = Package(
    name: "AevonXCoreBridge",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AevonXCoreBridge",
            targets: ["AevonXCoreBridge"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "AevonXCoreLib",
            path: "Frameworks/AevonXCore.xcframework"
        ),
        .target(
            name: "AevonXCoreBridge",
            dependencies: ["AevonXCoreLib"],
            path: "Sources/AevonXCoreBridge"
        ),
    ]
)
