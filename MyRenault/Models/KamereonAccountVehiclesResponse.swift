//
//  KamereonAccountVehiclesResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Vehicles list for a Kamereon account.
public struct KamereonAccountVehiclesResponse: Codable {
    let accountId: String
    let country: String
    let vehicleLinks: [VehicleLink]
    let activeOrders: [String]?
}
