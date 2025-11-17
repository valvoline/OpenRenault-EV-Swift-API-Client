//
//  GigyaGetAccountInfoResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Response for Gigya account info.
public struct GigyaGetAccountInfoResponse: Codable {
    public struct Data: Codable { public let personId: String? }
    public let data: Data?
    public let errorCode: Int?
    public let statusCode: Int?
    public let errorMessage: String?
    public var personId: String? { data?.personId }
}
