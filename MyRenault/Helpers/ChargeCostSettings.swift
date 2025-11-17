//
//  ChargeCostSettings.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 18/11/25.
//

import Foundation

enum ChargeCostSettingsKey {
    static let energyCostPerKW = "chargeSettings.energyCostPerKW"
    static let gasolineCostPerLiter = "chargeSettings.gasolineCostPerLiter"
    static let averageKmPerLiter = "chargeSettings.averageKmPerLiter"
}

enum ChargeCostSettingsDefault {
    static let energyCostPerKW: Double = 0.35
    static let gasolineCostPerLiter: Double = 1.75
    static let averageKmPerLiter: Double = 16.0
}
