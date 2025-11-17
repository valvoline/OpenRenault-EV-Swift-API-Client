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
}
