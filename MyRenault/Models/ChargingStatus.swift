//
//  ChargingStatus.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Possible charging states reported by Kamereon.
public enum ChargingStatus: Double, Codable {
    case notInCharge = 0.0
    case inCharge = 0.1
    case waitingForPlannedCharge = 0.2
    case chargeEnded = 0.3
    case chargeError = 0.4
    case waitingForCurrentCharge = 0.5
    case energyFlow = 0.6
    
    /// Human readable label suitable for UI.
    public var description: String {
        switch self {
        case .notInCharge: return "Not in charge"
        case .inCharge: return "Charging"
        case .waitingForPlannedCharge: return "Waiting for planned charge"
        case .chargeEnded: return "Charge ended"
        case .chargeError: return "Charge error"
        case .waitingForCurrentCharge: return "Waiting for current charge"
        case .energyFlow: return "Energy flow (V2L)"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(Double.self)
        // Some backends return integer-like values (1, 2, ...) instead of tenths (0.1, 0.2, ...).
        let normalized = decoded > 0.9 ? decoded / 10.0 : decoded
        if let status = ChargingStatus(rawValue: normalized) {
            self = status
            return
        }
        throw DecodingError.dataCorruptedError(in: container,
                                               debugDescription: "Cannot initialize ChargingStatus from invalid value \(decoded)")
    }
}
