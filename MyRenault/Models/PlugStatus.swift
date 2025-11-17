//
//  PlugStatus.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Physical connector status for the vehicle.
public enum PlugStatus: Int, Codable {
    case unplugged = 0
    case plugged = 1
    case plugError = 2
    
    /// Human readable label suitable for UI.
    public var description: String {
        switch self {
        case .unplugged: return "Unplugged"
        case .plugged: return "Plugged"
        case .plugError: return "Plug error"
        }
    }
}
