//
//  KamereonCommandResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Response for Kamereon command endpoints.
public struct KamereonCommandResponse: Codable {
    public let commandId: String
    public let type: String
    public let status: String
}
