//
//  KamereonLockStatusResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Lock status response.
public struct KamereonLockStatusResponse: Codable {
    public struct LockData: Codable {
        public let type: String?
        public let id: String?
        public let attributes: LockAttributes?
    }
    public struct LockAttributes: Codable {
        public let lockStatus: String?
        public let lastUpdateTime: String?
    }
    public let data: LockData?
}
