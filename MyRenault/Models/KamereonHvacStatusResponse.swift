//
//  KamereonHvacStatusResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// HVAC (climate) status response.
public struct KamereonHvacStatusResponse: Codable {
    public struct HvacData: Codable {
        public let type: String?
        public let id: String?
        public let attributes: HvacAttributes?
    }
    public struct HvacAttributes: Codable {
        public let externalTemperature: Double?
        public let airConditioning: Bool?
        public let heating: Bool?
        public let nextHvacStartDate: String?
        public let lastUpdateTime: String?
    }
    public let data: HvacData?
}
