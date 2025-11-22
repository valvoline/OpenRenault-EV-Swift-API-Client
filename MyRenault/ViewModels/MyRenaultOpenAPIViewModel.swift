//
//  MyRenaultViewModel.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import SwiftUI
import Observation

/// Helpers that describe the current runtime environment (Preview vs. app).
public struct AppEnvironment {
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

/// Central state holder that orchestrates authentication and vehicle data loading.
/// Annotated with `@Observable` so SwiftUI views can bind directly to its values.
@Observable
@MainActor
final class MyRenaultOpenAPIViewModel {
    private let api: MyRenaultOpenAPI
    private let previewSnapshotService = "MyRenaultPreviewSnapshot"
    
    /// True when we are missing credentials/tokens and must display the login flow.
    var loginNeeded: Bool {
        let gigyaLoginTokenIsMissing = api.gigyaLoginToken == nil
        let gigyaJWTIsMissingOrInvalid = (api.gigyaJWT == nil) || ((try? api.gigyaJWT?.isJWTExpired()) ?? true)
        let usernameIsMissing = KeychainHelper.read(service: "MyRenault4API", account: "username") == nil
        let passwordIsMissing = KeychainHelper.read(service: "MyRenault4API", account: "password") == nil
        return gigyaLoginTokenIsMissing && gigyaJWTIsMissingOrInvalid && usernameIsMissing && passwordIsMissing
    }
    
    // MARK: - Published state
    /// Latest Gigya account info.
    var accountInfo: GigyaGetAccountInfoResponse?
    /// Accounts returned by the Kamereon "accountIds" endpoint.
    var accountIds: [Account]?
    /// Vehicles attached to the selected account.
    var vehicles: KamereonAccountVehiclesResponse?
    
    /// Currently selected Kamereon account ID. Persisted in the keychain.
    var selectedAccountId: Account? {
        didSet {
            if let newValue = selectedAccountId {
                KeychainHelper.saveCodable(newValue, service: "MyRenaultViewModel", account: "selectedAccountId")
            } else {
                KeychainHelper.delete(service: "MyRenaultViewModel", account: "selectedAccountId")
            }
        }
    }
    
    /// Currently selected vehicle. Persisted in the keychain.
    var selectedVehicle: VehicleLink? {
        didSet {
            if let newValue = selectedVehicle {
                KeychainHelper.saveCodable(newValue, service: "MyRenaultViewModel", account: "selectedVehicle")
            } else {
                KeychainHelper.delete(service: "MyRenaultViewModel", account: "selectedVehicle")
            }
        }
    }
    
    /// Cockpit snapshot returned by Kamereon.
    var cockpit: KamereonCockpitResponse?
    /// Battery status snapshot returned by Kamereon.
    var batteryStatus: KamereonBatteryStatusResponse?
    /// Latest known vehicle location.
    var location: KamereonLocationResponse?
    /// Latest HVAC status snapshot.
    var hvacStatus: KamereonHvacStatusResponse?
    /// Cached charging history for the selected period.
    var chargeHistory: KamereonChargesResponse?
    /// Current SoC level configuration.
    var socLevel: KamereonChargeSettings?
    /// Most recent API error surfaced to the UI.
    var apiError: RenaultAPIError?
    /// Human readable error message for toasts/alerts.
    var errorMessage: String?
    
    /// Temporary SoC adjustments staged by the user before saving.
    var adjustSocLevel: KamereonChargeSettings? {
        didSet {
            guard let newValue = adjustSocLevel,
                  let accountId = selectedAccountId?.accountId,
                  let vin = selectedVehicle?.vin else {
                return
            }
            Task { [weak self] in
                await self?.syncSocLevelWithServer(newValue, accountId: accountId, vin: vin)
            }
        }
    }
    
    /// Global loading flag used to drive spinners in the UI.
    var isLoading = false
    
    /// Creates a view model backed by the provided API client and attempts to
    /// restore persisted selections/snapshots.
    init(api: MyRenaultOpenAPI) {
        self.api = api
        self.selectedAccountId = KeychainHelper.readCodable(Account.self, service: "MyRenaultViewModel", account: "selectedAccountId")
        self.selectedVehicle = KeychainHelper.readCodable(VehicleLink.self, service: "MyRenaultViewModel", account: "selectedVehicle")
        if AppEnvironment.isPreview {
            // Preload cached snapshots to avoid network calls during Xcode Previews
            self.accountInfo = KeychainHelper.readCodable(GigyaGetAccountInfoResponse.self,
                                                          service: previewSnapshotService,
                                                          account: "accountInfo")
            self.accountIds = KeychainHelper.readCodable([Account].self,
                                                         service: previewSnapshotService,
                                                         account: "accountIds")
            self.vehicles = KeychainHelper.readCodable(KamereonAccountVehiclesResponse.self,
                                                       service: previewSnapshotService,
                                                       account: "vehicles")
            self.cockpit = KeychainHelper.readCodable(KamereonCockpitResponse.self,
                                                      service: previewSnapshotService,
                                                      account: "cockpit")
            self.batteryStatus = KeychainHelper.readCodable(KamereonBatteryStatusResponse.self,
                                                            service: previewSnapshotService,
                                                            account: "batteryStatus")
            self.location = KeychainHelper.readCodable(KamereonLocationResponse.self,
                                                       service: previewSnapshotService,
                                                       account: "location")
            self.hvacStatus = KeychainHelper.readCodable(KamereonHvacStatusResponse.self,
                                                         service: previewSnapshotService,
                                                         account: "hvacStatus")
            self.chargeHistory = KeychainHelper.readCodable(KamereonChargesResponse.self,
                                                            service: previewSnapshotService,
                                                            account: "chargeHistory")
            self.socLevel = KeychainHelper.readCodable(KamereonChargeSettings.self,
                                                       service: previewSnapshotService,
                                                       account: "socLevel")
        }
    }
    
    // MARK: - Actions
    
    /// Performs the Gigya login flow and populates the account list.
    @discardableResult
    func login(username: String, password: String) async -> Bool {
        isLoading = true
        apiError = nil
        errorMessage = nil
        defer { isLoading = false }
        do {
            // Perform login with the remote API.
            _ = try await api.gigyaLogin(loginID: username, password: password)
            
            // Update local state after a successful login.
            self.accountInfo = try await api.gigyaGetAccountInfo()
            
            guard let personId = accountInfo?.personId else {
                throw RenaultAPIError.unexpected("Missing personId after login")
            }
            self.accountIds = try await api.getAccountIds(personId: personId).accounts
            
            print("[Auth] Login successful for \(username)")
            return true
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Fetches Gigya account info and resolves the list of Kamereon account IDs.
    func fetchAccounts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let account = try await api.gigyaGetAccountInfo()
            self.accountInfo = account
            
            guard let personId = account.personId else {
                throw RenaultAPIError.unexpected("Missing personId")
            }
            accountIds = try await api.getAccountIds(personId: personId).accounts
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Loads the vehicles available for the given Kamereon account.
    func fetchVehicles(for accountId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            vehicles = try await api.getVehicles(accountId: accountId)
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Convenience method that requests all data blocks for the selected vehicle.
    /// Used during dashboard refreshes and previews.
    func refreshAllVehicleData(startDate: Date? = nil, endDate: Date? = nil, forceRefresh: Bool = false) async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        
        if AppEnvironment.isPreview,
           cockpit != nil || batteryStatus != nil || location != nil || socLevel != nil || hvacStatus != nil || chargeHistory != nil {
            // In Preview, if we already have any snapshot loaded, don't refetch to avoid rate limits
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let resolvedStartDate = startDate ?? calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let resolvedEndDate = endDate ?? today
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let startDateString = formatter.string(from: resolvedStartDate)
        let endDateString = formatter.string(from: resolvedEndDate)
        
        isLoading = true
        defer { isLoading = false }
        do {
            if self.cockpit == nil || forceRefresh {
                self.cockpit = try await api.getCockpit(accountId: accountId, vin: vin)
            }
            if self.batteryStatus == nil || forceRefresh {
                self.batteryStatus = try await api.getBatteryStatus(accountId: accountId, vin: vin)
            }
            if self.location == nil || forceRefresh {
                self.location = try await api.getLocation(accountId: accountId, vin: vin)
            }
            if self.socLevel == nil || forceRefresh {
                self.socLevel = try await api.getSocLevels(accountId: accountId, vin: vin)
            }
            if self.hvacStatus == nil || forceRefresh {
                self.hvacStatus = try await api.getHvacStatus(accountId: accountId, vin: vin)
            }
            if self.chargeHistory == nil || forceRefresh {
                self.chargeHistory = try await api.getChargingHistory(accountId: accountId, vin: vin, startDate: startDateString, endDate: endDateString)
            }
            // Persist snapshots for subsequent Preview reloads
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes the cockpit snapshot for the selected vehicle.
    func refreshCockpitForVehicle() async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        if AppEnvironment.isPreview, self.cockpit != nil { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.cockpit = try await api.getCockpit(accountId: accountId, vin: vin)
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes the battery status snapshot for the selected vehicle.
    func refreshBatteryStatusForVehicle() async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        if AppEnvironment.isPreview, self.batteryStatus != nil { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.batteryStatus = try await api.getBatteryStatus(accountId: accountId, vin: vin)
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes the last known GPS coordinates for the selected vehicle.
    func refreshLocationForVehicle() async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        if AppEnvironment.isPreview, self.location != nil { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.location = try await api.getLocation(accountId: accountId, vin: vin)
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes the SoC target/min levels for the selected vehicle.
    func refreshSocLevelForVehicle() async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        if AppEnvironment.isPreview, self.socLevel != nil { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.socLevel = try await api.getSocLevels(accountId: accountId, vin: vin)
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes the HVAC/climate state for the selected vehicle.
    func refreshHvacStatusForVehicle() async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        if AppEnvironment.isPreview, self.hvacStatus != nil { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.hvacStatus = try await api.getHvacStatus(accountId: accountId, vin: vin)
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Fetches the charging history for the selected vehicle within the provided range.
    func refreshChargeHistoryForVehicle(startDate: Date? = nil, endDate: Date? = nil) async {
        guard let accountId = selectedAccountId?.accountId,
              let vin = selectedVehicle?.vin else {
            errorMessage = "Missing account or vehicle info"
            apiError = RenaultAPIError.missingCredentials
            return
        }
        if AppEnvironment.isPreview,
           self.chargeHistory != nil,
           startDate == nil,
           endDate == nil {
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let resolvedStartDate = startDate ?? calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let resolvedEndDate = endDate ?? today
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let startDateString = formatter.string(from: resolvedStartDate)
        let endDateString = formatter.string(from: resolvedEndDate)
        
        isLoading = true
        defer { isLoading = false }
        do {
            self.chargeHistory = try await api.getChargingHistory(accountId: accountId, vin: vin, startDate: startDateString, endDate: endDateString)
            savePreviewSnapshots()
        } catch {
            if let renaultError = error as? RenaultAPIError {
                self.apiError = renaultError
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Clears cached tokens, selections, and preview snapshots.
    func logout() {
        api.logout()
        accountInfo = nil
        vehicles = nil
        cockpit = nil
        batteryStatus = nil
        errorMessage = nil
        selectedVehicle = nil
        selectedAccountId = nil
        clearPreviewSnapshots()
    }
    
    
    /// Computes the sum of the energy recovered across the cached charge history.
    public func totalRecoveredEnergy() -> Double {
        guard let chargeHistory = chargeHistory else { return 0.0 }
        let total = chargeHistory.data.attributes.charges.reduce(0.0) { partialResult, charge in
            partialResult + (charge.chargeEnergyRecovered)
        }
        return total
    }
    
    /// Persists a SoC configuration change on the backend and refreshes the snapshot.
    private func syncSocLevelWithServer(_ socLevel: KamereonChargeSettings, accountId: String, vin: String) async {
        do {
            let payload = KamereonChargeSettings(
                lastEnergyUpdateTimestamp: nil,
                socMin: socLevel.socMin,
                socTarget: socLevel.socTarget
            )
            _ = try await api.setSocLevels(accountId: accountId, vin: vin, payload: payload)
            self.socLevel = try await api.getSocLevels(accountId: accountId, vin: vin)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Persists the latest API snapshots so Xcode previews can reuse them offline.
    private func savePreviewSnapshots() {
        guard AppEnvironment.isPreview else { return }
        if let accountInfo { KeychainHelper.saveCodable(accountInfo, service: previewSnapshotService, account: "accountInfo") }
        if let accountIds { KeychainHelper.saveCodable(accountIds, service: previewSnapshotService, account: "accountIds") }
        if let vehicles { KeychainHelper.saveCodable(vehicles, service: previewSnapshotService, account: "vehicles") }
        if let cockpit { KeychainHelper.saveCodable(cockpit, service: previewSnapshotService, account: "cockpit") }
        if let batteryStatus { KeychainHelper.saveCodable(batteryStatus, service: previewSnapshotService, account: "batteryStatus") }
        if let location { KeychainHelper.saveCodable(location, service: previewSnapshotService, account: "location") }
        if let hvacStatus { KeychainHelper.saveCodable(hvacStatus, service: previewSnapshotService, account: "hvacStatus") }
        if let chargeHistory { KeychainHelper.saveCodable(chargeHistory, service: previewSnapshotService, account: "chargeHistory") }
        if let socLevel { KeychainHelper.saveCodable(socLevel, service: previewSnapshotService, account: "socLevel") }
    }
    
    /// Removes the cached snapshots used for previews.
    private func clearPreviewSnapshots() {
        KeychainHelper.delete(service: previewSnapshotService, account: "accountInfo")
        KeychainHelper.delete(service: previewSnapshotService, account: "accountIds")
        KeychainHelper.delete(service: previewSnapshotService, account: "vehicles")
        KeychainHelper.delete(service: previewSnapshotService, account: "cockpit")
        KeychainHelper.delete(service: previewSnapshotService, account: "batteryStatus")
        KeychainHelper.delete(service: previewSnapshotService, account: "location")
        KeychainHelper.delete(service: previewSnapshotService, account: "hvacStatus")
        KeychainHelper.delete(service: previewSnapshotService, account: "chargeHistory")
        KeychainHelper.delete(service: previewSnapshotService, account: "socLevel")
    }
}
