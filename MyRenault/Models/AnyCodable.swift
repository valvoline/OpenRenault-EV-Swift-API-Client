//
//  AnyCodable.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

// MARK: - Helpers
//
// JSON helpers and utility types for encoding/decoding.

/// A type-erased `Codable` value.
public struct AnyCodable: Codable {}

/// A type-erased `Encodable` value.
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { self._encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

extension JSONDecoder {
    /// Returns a JSONDecoder configured for Renault API conventions (ISO8601 dates, snake_case).
    static func renault() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return dec
    }
}

extension JSONEncoder {
    /// Returns a JSONEncoder configured for Renault API conventions (ISO8601 dates, snake_case).
    static func renault(pretty: Bool = false) -> JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.keyEncodingStrategy = .convertToSnakeCase
        if pretty { enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes] }
        return enc
    }
}

