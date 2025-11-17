//
//  KamereonChargeSettingsResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// SoC (State of Charge) settings.
public struct KamereonChargeSettings: Codable {
    public let lastEnergyUpdateTimestamp: String?
    public let socMin: Int
    public let socTarget: Int
}
