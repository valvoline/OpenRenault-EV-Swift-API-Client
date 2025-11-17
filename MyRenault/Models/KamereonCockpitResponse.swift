//
//  KamereonCockpitResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Cockpit data response.
public struct KamereonCockpitResponse: Codable {
    public struct CockpitData: Codable {
        public let type: String?
        public let id: String?
        public let attributes: CockpitAttributes?
    }
    public struct CockpitAttributes: Codable {
        public let totalMileage: Double?
        public let fuelAutonomy: Double?
        public let fuelQuantity: Double?
        public let batteryLevel: Double?
        public let plugStatus: Int?
        public let chargeStatus: ChargingStatus?
        public let autonomy: Double?
        public let timestamp: String?
    }
    public let data: CockpitData?
}
