//
//  KamereonPersonResponse.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

/// Person/account info from Kamereon.
public struct KamereonPersonResponse: Codable {
    let personId: String
    let type: String
    let context: String?
    let country: String
    let firstName: String?
    let lastName: String?
    let idp: IDP?
    let addresses: [Address]?
    let emails: [Email]?
    let phones: [Phone]?
    let identities: [Identity]?
    let myrRequest: Bool?
    let accounts: [Account]?
    let purposes: [Purpose]?
    let partyId: String?
    let mdmId: String?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let functionalCreationDate: Date?
    let functionalModificationDate: Date?
    let locale: String?
    let originApplicationName: String?
    let originUserId: String?
    let agreements: [Agreement]?
    let parentPersonsLinks: [String]?
    let childPersonsLinks: [String]?
    let trackingId: String?
}

/// Identity provider metadata used by Kamereon.
struct IDP: Codable {
    let idpId: String
    let idpType: String
    let idpStatus: String
    let login: String
    let loginType: String
    let lastLoginDate: Date?
    let termsConditionAcceptance: Bool?
    let termsConditionLastAcceptanceDate: Date?
    let functionalCreationDate: Date?
    let functionalValidationDate: Date?
    let originUserId: String?
    let originApplicationName: String?
    let registerBrand: String?
    let registerData: RegisterData?
}

/// Custom registration metadata grouped by purpose/event.
struct RegisterData: Codable {
    let purposes: [String]?
    let events: [String]?
}

/// Postal address associated with the person.
struct Address: Codable {
    let addressType: String?
    let addressLine1: String?
    let city: String?
    let postalCode: String?
    let country: String?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let functionalCreationDate: Date?
    let functionalModificationDate: Date?
}

/// Email contact entry for the person.
struct Email: Codable {
    let emailType: String?
    let emailValue: String?
    let validityFlag: Bool?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let functionalCreationDate: Date?
    let functionalModificationDate: Date?
}

/// Phone contact entry for the person.
struct Phone: Codable {
    let phoneType: String?
    let phoneValue: String?
    let areaCode: String?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let functionalCreationDate: Date?
    let functionalModificationDate: Date?
}

/// Placeholder for future identity metadata.
struct Identity: Codable {}

/// Account link returned by Kamereon.
struct Account: Codable {
    let accountId: String
    let accountType: String
    let accountStatus: String
    let country: String
    let personId: String
    let relationType: String
}

/// Purpose/consent bundle entries.
struct Purpose: Codable {
    let purposeId: String
    let country: String
    let purposeType: String
    let purposeStartDate: String?
    let purposeEndDate: String?
    let forceEndDate: Bool?
    let consents: [Consent]?
    let createdDate: Date?
    let lastModifiedDate: Date?
}

/// Consent details tied to a specific purpose.
struct Consent: Codable {
    let consentId: String?
    let scopeType: String?
    let agreements: [AgreementDetail]?
    let createdDate: Date?
    let lastModifiedDate: Date?
}

/// Individual agreement metadata and tracking info.
struct AgreementDetail: Codable {
    let type: String?
    let value: String?
    let displayValue: String?
    let lastUpdateSourceType: String?
    let lastUpdateSubSourceType: String?
    let createdDate: Date?
    let lastModifiedDate: Date?
    let functionalCreationDate: Date?
    let functionalModificationDate: Date?
}

/// Placeholder for agreement metadata returned by the API.
struct Agreement: Codable {}
