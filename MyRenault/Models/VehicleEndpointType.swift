//
//  VehicleEndpointType.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Host the endpoint belongs to (Kamereon Customer API vs. Manufacturing API).
public enum VehicleEndpointType: String {
    case kcm
    case kca
}

/// Concrete resource identifiers used when calling the Renault APIs.
public enum VehicleEndpoint: String {
    case cockpit = "cockpit"
    case batteryStatus = "battery-status"
    case hvacStatus = "hvac-status"
    case location = "location"
    case lockStatus = "lock-status"
    case chargingSettings = "charging-settings"
    case chargeMode = "charge-mode"
    case chargeSchedule = "charge-schedule"
    case resState = "res-state"
    case charges = "charges"
    case socLevels = "soc-levels"
}
