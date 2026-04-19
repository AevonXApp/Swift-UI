import Foundation

/// Smart error sanitizer — classifies raw Go-core errors into localized user messages
/// using weighted keyword scoring instead of brittle static pattern matching.
///
/// Usage:
///   let msg = ErrorResponseHelper.sanitize(rawError)
///   let msg = ErrorResponseHelper.sanitize(rawError, context: "DatabaseVM")
enum ErrorResponseHelper {

    // MARK: - Public API

    static func sanitize(_ rawError: String) -> String {
        // Fast path: exact match
        if let exact = exactMatches[rawError] { return exact }

        // Smart path: tokenize → score → best category
        let tokens = tokenize(rawError)
        var best: (msg: String, score: Int, pri: Int)?

        for cat in categories {
            let score = cat.keywords.reduce(0) { sum, kw in
                sum + (tokens.contains(kw) ? kw.count : 0) // longer keywords = stronger signal
            }
            guard score > 0 else { continue }
            if best == nil || score > (best?.score ?? -1) || (score == best?.score && cat.pri > (best?.pri ?? -1)) {
                best = (cat.msg, score, cat.pri)
            }
        }

        return best?.msg ?? L10n.Error.generic
    }

    static func sanitize(_ rawError: String, context: String?) -> String {
        #if DEBUG
        if let context { print("[\(context)] Raw error: \(rawError)") }
        #endif
        return sanitize(rawError)
    }

    // MARK: - Tokenizer

    private static func tokenize(_ error: String) -> Set<String> {
        Set(error.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
    }

    // MARK: - Exact Matches (zero-cost for known strings)

    private static let exactMatches: [String: String] = [
        "Not connected to server":              L10n.Error.notConnected,
        "Not connected to SSH server":          L10n.Error.notConnected,
        "Invalid credentials":                  L10n.Error.invalidCredentials,
        "Host key verification failed":         L10n.Error.hostKeyChanged,
        "Connection timed out":                 L10n.Error.timeout,
        "Network is unreachable":               L10n.Error.networkUnreachable,
        "Already connected to server":          L10n.Error.alreadyConnected,
        "Invalid API URL":                      L10n.Error.invalidApiUrl,
        "Server limit reached":                 L10n.Error.serverLimitReached,
        "Not authenticated":                    L10n.Error.sessionExpired,
        "SQL content is empty":                 L10n.Error.sqlEmpty,
        "Installation was cancelled":           L10n.Error.installCancelled,
        "CAT validation failed":                L10n.Error.authFailed,
    ]

    // MARK: - Categories (scored by keyword weight)

    private struct Cat {
        let keywords: [String]
        let msg: String
        let pri: Int // priority tiebreaker (higher = preferred)
    }

    private static let categories: [Cat] = [
        // Security (highest priority — never suppress)
        Cat(keywords: ["signature", "invalid", "mitm"],                     msg: L10n.Error.securityThreat,       pri: 100),
        Cat(keywords: ["hostkey", "identity", "changed"],                   msg: L10n.Error.hostKeyChanged,       pri: 95),
        Cat(keywords: ["decryption", "failed"],                             msg: L10n.Error.decryptionFailed,     pri: 90),
        Cat(keywords: ["encryption", "encrypt", "ecdh", "ephemeral"],       msg: L10n.Error.encryptionFailed,     pri: 85),
        Cat(keywords: ["device", "fingerprint", "mismatch"],                msg: L10n.Error.deviceChanged,        pri: 80),

        // Auth & Session
        Cat(keywords: ["expired", "token", "session"],                      msg: L10n.Error.sessionExpired,       pri: 75),
        Cat(keywords: ["authentication", "unauthorized", "cat"],            msg: L10n.Error.authFailed,           pri: 70),
        Cat(keywords: ["credentials", "password", "login"],                 msg: L10n.Error.invalidCredentials,   pri: 65),

        // Connection & Network
        Cat(keywords: ["timeout", "timed"],                                 msg: L10n.Error.timeout,              pri: 60),
        Cat(keywords: ["unreachable", "network"],                           msg: L10n.Error.networkUnreachable,   pri: 55),
        Cat(keywords: ["connection", "connect", "failed"],                  msg: L10n.Error.connectionFailed,     pri: 50),
        Cat(keywords: ["ssh", "handshake"],                                 msg: L10n.Error.sshFailed,            pri: 48),

        // Rate Limiting
        Cat(keywords: ["rate", "limit", "throttle"],                        msg: L10n.Error.rateLimited,          pri: 45),

        // Plugin
        Cat(keywords: ["plugin", "notfound", "missing"],                    msg: L10n.Error.pluginNotFound,       pri: 42),
        Cat(keywords: ["plugin", "setup", "failed"],                        msg: L10n.Error.pluginSetupFailed,    pri: 41),
        Cat(keywords: ["plugin", "binary"],                                 msg: L10n.Error.pluginBinaryMissing,  pri: 40),
        Cat(keywords: ["plugin", "health", "check"],                        msg: L10n.Error.pluginHealthFailed,   pri: 39),
        Cat(keywords: ["incompatible", "version", "plugin"],                msg: L10n.Error.pluginIncompatible,   pri: 38),

        // Installation
        Cat(keywords: ["installation", "install", "failed"],                msg: L10n.Error.installFailed,        pri: 35),
        Cat(keywords: ["uninstall", "failed"],                              msg: L10n.Error.uninstallFailed,      pri: 34),
        Cat(keywords: ["extract", "failed", "package"],                     msg: L10n.Error.extractFailed,        pri: 33),

        // AI
        Cat(keywords: ["ai", "service", "unavailable"],                     msg: L10n.Error.aiUnavailable,        pri: 30),
        Cat(keywords: ["ai", "unsupported", "database"],                    msg: L10n.Error.aiUnsupportedDB,      pri: 29),

        // Config
        Cat(keywords: ["configuration", "config", "invalid"],               msg: L10n.Error.invalidConfig,        pri: 25),
        Cat(keywords: ["config", "update", "failed"],                       msg: L10n.Error.configUpdateFailed,   pri: 24),

        // Download
        Cat(keywords: ["download", "expired"],                              msg: L10n.Error.downloadExpired,      pri: 22),
        Cat(keywords: ["download", "used", "already"],                      msg: L10n.Error.downloadUsed,         pri: 21),

        // SSL
        Cat(keywords: ["ssl", "certificate", "tls"],                        msg: L10n.Error.sslFailed,            pri: 20),

        // Services
        Cat(keywords: ["service", "installed"],                             msg: L10n.Error.serviceNotInstalled,  pri: 15),
        Cat(keywords: ["unsupported", "operation"],                         msg: L10n.Error.unsupportedOperation, pri: 14),

        // Server / API (low priority — catch-all for server issues)
        Cat(keywords: ["server", "accessible"],                             msg: L10n.Error.serverNotAccessible,  pri: 12),
        Cat(keywords: ["decode", "response", "invalid"],                    msg: L10n.Error.serverError,          pri: 10),
        Cat(keywords: ["command", "exec", "exit"],                          msg: L10n.Error.commandFailed,        pri: 8),
        Cat(keywords: ["determine", "detect"],                              msg: L10n.Error.detectionFailed,      pri: 5),
    ]
}

// MARK: - OperationResult Extension

extension OperationResult {
    static func sanitizedFailure(_ rawError: String) -> OperationResult {
        .failure(message: ErrorResponseHelper.sanitize(rawError))
    }
}
