//
//  VehicleLink.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation


/// Details for a single vehicle link.
struct VehicleLink: Codable {
    let brand: String
    let vin: String
    let status: String
    let linkType: String
    let garageBrand: String?
    let startDate: String?
    let endDate: String?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let ownershipStartDate: String?
    let ownershipEndDate: String?
    let cancellationReason: CancellationReason?
    let preferredDealer: Dealer?
    let connectedDriver: ConnectedDriver?
    let vehicleDetails: VehicleDetails?
}

/// Reason why a vehicle link was cancelled/expired.
struct CancellationReason: Codable {
    let code: String?
    let label: String?
}

/// Driver profile associated with the vehicle link.
struct ConnectedDriver: Codable {
    let role: String?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let createdBy: String?
    let lastModifiedBy: String?
}

/// Preferred dealer metadata.
struct Dealer: Codable {
    let name: String?
    let code: String?
    let country: String?
}

/// Static metadata describing the vehicle configuration.
struct VehicleDetails: Codable {
    let vin: String
    let registrationDate: String?
    let firstRegistrationDate: String?
    let engineType: String?
    let engineRatio: String?
    let modelSCR: String?
    let passToSalesDate: String?
    let deliveryCountry: CodeLabel?
    let family: CodeLabel?
    let tcu: CodeLabel?
    let navigationAssistanceLevel: CodeLabel?
    let battery: CodeLabel?
    let radioType: CodeLabel?
    let registrationCountry: CodeLabel?
    let brand: CodeLabel?
    let model: CodeLabel?
    let gearbox: CodeLabel?
    let version: CodeLabel?
    let energy: CodeLabel?
    let bodyType: CodeLabel?
    let steeringSide: CodeLabel?
    let additionalEngineType: CodeLabel?
    let hybridation: CodeLabel?
    let registrationNumber: String?
    let vcd: String?
    let manufacturingDate: String?
    let assets: [VehicleAsset]?
    let deliveryDate: String?
    let connectivityTechnology: String?
    let easyConnectStore: Bool?
    let electrical: Bool?
    let engineEnergyType: String?
    let radioCode: String?
    let premiumSubscribed: Bool?
    let batteryType: String?
}

/// Generic code/label tuple returned by the API.
struct CodeLabel: Codable {
    let code: String?
    let label: String?
    let group: String?
}

/// Media assets (images/renders) referencing the vehicle.
struct VehicleAsset: Codable {
    let assetType: String
    let assetRole: String?
    let title: String?
    let description: String?
    let viewpoint: String?
    let renditions: [Rendition]?
    let viewPointInLowerCase: String?
}

/// Specific resolution of a vehicle asset.
struct Rendition: Codable {
    let resolutionType: String?
    let resolution: String?
    let url: String
    let size: String?
}
