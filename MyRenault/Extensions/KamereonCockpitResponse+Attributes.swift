//
//  KamereonCockpitResponse+Attributes.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 16/11/25.
//

import SwiftUI

extension KamereonCockpitResponse.CockpitAttributes {
    var totalKmSoFar: String {
        guard let totalMileage else { return "--" }
        return "\(Int(totalMileage)) km"
    }
}
