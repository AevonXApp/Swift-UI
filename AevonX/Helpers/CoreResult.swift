//
//  CoreResult.swift
//  AevonX
//
//  Shared helpers for parsing the JSON envelope produced by Go's
//  `marshalResult(api.AuthServiceResult)`. Every Go bridge HTTP call returns:
//
//      { "success": Bool, "data": <RawMessage>, "error": { "code", "message", "status" } }
//
//  Every Swift Service that consumes such a result goes through this helper
//  so we have one place to evolve error handling, logging, and (later) error
//  code → localized string mapping.
//

import Foundation

enum CoreResult {

    /// Domain used for `NSError`s that originate in core-go.
    static let errorDomain = "AevonXCore"

    /// Parse the envelope and either return the dictionary or throw an `NSError`.
    @discardableResult
    static func parse(_ json: String) throws -> [String: Any] {
        guard let raw = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
            throw makeError(code: 0, message: "Invalid response from core")
        }
        let success = dict["success"] as? Bool ?? false
        if !success {
            let errDict = dict["error"] as? [String: Any]
            let message = (errDict?["message"] as? String) ?? "Request failed"
            let status  = (errDict?["status"] as? Int) ?? 0
            throw makeError(code: status, message: message)
        }
        return dict
    }

    /// Throws if the envelope indicates failure, ignoring the data.
    static func ensureSuccess(_ json: String) throws {
        _ = try parse(json)
    }

    /// Returns the `data` field as a loosely-typed value (dictionary, array, or scalar).
    static func data(_ json: String) throws -> Any {
        let dict = try parse(json)
        guard let data = dict["data"] else {
            throw makeError(code: 0, message: "Empty response from server")
        }
        return data
    }

    /// Decode the `data` field directly into a `Decodable` value using the supplied decoder.
    static func decodePayload<T: Decodable>(
        _ json: String,
        as type: T.Type,
        decoder: JSONDecoder = .iso8601()
    ) throws -> T {
        let raw = try data(json)
        let payload = try JSONSerialization.data(withJSONObject: raw)
        return try decoder.decode(T.self, from: payload)
    }

    static func makeError(code: Int, message: String) -> NSError {
        NSError(domain: errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

extension JSONDecoder {
    /// Decoder pre-configured for the ISO-8601 timestamps the backend emits
    /// (with and without fractional seconds).
    static func iso8601() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }
}
