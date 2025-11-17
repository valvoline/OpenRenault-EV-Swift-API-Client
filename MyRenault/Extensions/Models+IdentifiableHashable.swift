//
//  Models+IdentifiableHashable.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 11/11/25.
//
import Foundation

extension KamereonPersonResponse: Identifiable, Hashable {
    public var id: String { personId }
    public static func == (lhs: KamereonPersonResponse, rhs: KamereonPersonResponse) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension IDP: Identifiable, Hashable {
    public var id: String { idpId }
    public static func == (lhs: IDP, rhs: IDP) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Account: Identifiable, Hashable {
    public var id: String { accountId }
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Purpose: Identifiable, Hashable {
    public var id: String { purposeId }
    public static func == (lhs: Purpose, rhs: Purpose) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension VehicleLink: Identifiable, Hashable {
    public var id: String { vin }
    public static func == (lhs: VehicleLink, rhs: VehicleLink) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension VehicleDetails: Identifiable, Hashable {
    public var id: String { vin }
    public static func == (lhs: VehicleDetails, rhs: VehicleDetails) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
