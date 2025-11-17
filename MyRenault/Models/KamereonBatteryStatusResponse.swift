//
//  KamereonBatteryStatusResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Battery status response.
public struct KamereonBatteryStatusResponse: Codable {
    public struct BatteryData: Codable {
        public let id: String?
        public let attributes: BatteryAttributes?
    }
    
    public struct BatteryAttributes: Codable {
        public let timestamp: String?
        public let batteryLevel: Double?
        public let batteryAutonomy: Double?
        public let v2lSystemStatusDisplay: Int?
        public let plugStatus: PlugStatus?
        public let chargingStatus: ChargingStatus?
        public let chargingRemainingTime: Int?
        
        enum CodingKeys: String, CodingKey {
            case timestamp
            case batteryLevel
            case batteryAutonomy
            case v2lSystemStatusDisplay = "V2L_SystemStatusDisplay"
            case plugStatus
            case chargingStatus
            case chargingRemainingTime
        }
    }
    
    public let data: BatteryData?
}
