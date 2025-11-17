//
//  String+JWT.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//
import Foundation

extension String {
    /// Checks if the JWT token is expired based on the `exp` field.
    /// - Parameter leeway: Time interval to allow before expiration (default: 30 seconds).
    /// - Returns: True if the token is expired or about to expire.
    public func isJWTExpired(leeway: TimeInterval = 30) throws -> Bool {
        let payload = try decodeJWTPayload()
        guard let exp = payload["exp"] as? Double ?? (payload["exp"] as? Int).map(Double.init) else {
            throw RenaultAPIError.unexpected("Invalid or missing exp claim")
        }
        let expirationDate = Date(timeIntervalSince1970: exp)
        return Date().addingTimeInterval(leeway) >= expirationDate
    }
    
    /// Decodes a JWT string and returns its payload as a dictionary.
    /// - Returns: The decoded payload as [String: Any].
    public func decodeJWTPayload() throws -> [String: Any] {
        let segments = self.split(separator: ".")
        guard segments.count >= 2 else {
            throw RenaultAPIError.unexpected("Invalid JWT format")
        }
        let payloadSegment = String(segments[1])
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            throw RenaultAPIError.unexpected("Invalid Base64 in JWT")
        }
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = json as? [String: Any] else {
            throw RenaultAPIError.unexpected("JWT payload not a dictionary")
        }
        return dict
    }
    
    /// Decodes a JWT token and returns its payload as a strongly typed object.
    /// - Parameters:
    ///   - token: The JWT string.
    ///   - type: The type to decode to.
    /// - Returns: The decoded payload.
    public func decodeJWT<T: Decodable>(token: String, as type: T.Type) throws -> T {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else {
            throw RenaultAPIError.unexpected("Invalid JWT format")
        }
        let payloadSegment = String(segments[1])
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            throw RenaultAPIError.unexpected("Invalid Base64 in JWT")
        }
        return try JSONDecoder.renault().decode(T.self, from: data)
    }
}
