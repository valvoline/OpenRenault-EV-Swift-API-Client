//
//  KamereonLocationResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Vehicle location response.
public struct KamereonLocationResponse: Codable {
    public struct LocationData: Codable {
        public let type: String?
        public let id: String?
        public let attributes: LocationAttributes?
    }
    public struct LocationAttributes: Codable {
        public let latitude: Double?
        public let longitude: Double?
        public let speed: Double?
        public let heading: Double?
        public let timestamp: String?
        
        enum CodingKeys: String, CodingKey {
            case latitude = "gpsLatitude"
            case longitude = "gpsLongitude"
            case speed
            case heading
            case timestamp = "lastUpdateTime"
        }
    }
    public let data: LocationData?
}
