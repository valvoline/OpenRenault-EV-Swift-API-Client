//
//  GigyaLoginResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Response for Gigya login.
public struct GigyaLoginResponse: Codable {
    public struct SessionInfo: Codable {
        public let cookieName: String?
        public let cookieValue: String?
        public let loginToken: String?
    }
    public let sessionInfo: SessionInfo?
    public let callId: String?
    public let errorCode: Int?
    public let statusCode: Int?
    public let errorMessage: String?
    public var effectiveLoginToken: String? { sessionInfo?.loginToken ?? sessionInfo?.cookieValue }
}
