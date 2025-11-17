//
//  KamereonBatteryStatusResponse+Battery.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 16/11/25.
//

import SwiftUI

extension KamereonBatteryStatusResponse.BatteryAttributes {
    var batteryAutonomyInKm: String {
        guard let batteryAutonomy else { return "--"}
        return "\(Int(batteryAutonomy)) km"
    }
    var batteryIcon: Image {
        guard let batteryLevel else { return Image(systemName: "battery.0percent") }
        if batteryLevel > 0 && batteryLevel <= 25 {
            return Image(systemName: "battery.25percent")
        } else if batteryLevel > 25 && batteryLevel <= 50 {
            return Image(systemName: "battery.50percent")
        } else if batteryLevel > 50 && batteryLevel <= 75 {
            return Image(systemName: "battery.75percent")
        } else {
            return Image(systemName: "battery.100percent")
        }
    }
}
