//
//  GigyaGetJWTResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Response for Gigya JWT token.
public struct GigyaGetJWTResponse: Codable {
    public let idToken: String
    public let errorCode: Int?
    public let statusCode: Int?
    public let errorMessage: String?
}
