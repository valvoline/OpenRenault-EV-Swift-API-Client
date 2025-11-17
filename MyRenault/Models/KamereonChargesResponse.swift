//
//  KamereonChargesResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Charging history response.
public struct KamereonChargesResponse: Codable {
    public struct ChargeAttributes: Codable {
        public struct Charge: Codable {
            public let chargeStartDate: String
            public let chargeEndDate: String
            public let chargeEndStatus: String
            public let chargeStartBatteryLevel: Int
            public let chargeEndBatteryLevel: Int
            public let chargeEnergyRecovered: Double
            public let chargeDuration: Int
        }
        
        public let charges: [Charge]
    }
    
    public struct ChargeData: Codable {
        public let type: String
        public let id: String
        public let attributes: ChargeAttributes
    }
    
    public let data: ChargeData
}
