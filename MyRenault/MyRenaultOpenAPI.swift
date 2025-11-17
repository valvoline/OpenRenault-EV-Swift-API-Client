//
//  MyRenaultOpenAPI.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

// MARK: - RenaultAPI Client

/// Main API client for interacting with Renault's Gigya and Kamereon endpoints.
public final class MyRenaultOpenAPI {
    /// Configuration for the RenaultAPI client.
    public struct Config {
        /// The root URL for Gigya endpoints.
        public var gigyaRootURL: URL
        /// The API key for Gigya.
        public var gigyaApiKey: String
        /// The root URL for Kamereon endpoints.
        public var kamereonRootURL: URL
        /// The API key for Kamereon.
        public var kamereonApiKey: String
        /// Country code (e.g. "IT").
        public var country: String
        /// Optional language (e.g. "it-IT").
        public var language: String?
        /// Initializes a new configuration.
        public init(gigyaRootURL: URL, gigyaApiKey: String, kamereonRootURL: URL, kamereonApiKey: String, country: String, language: String? = nil) {
            self.gigyaRootURL = gigyaRootURL
            self.gigyaApiKey = gigyaApiKey
            self.kamereonRootURL = kamereonRootURL
            self.kamereonApiKey = kamereonApiKey
            self.country = country
            self.language = language
        }
    }
    
    /// The configuration used by the API client.
    public let cfg: Config
    private let urlSession: URLSession
    /// Reentrancy flag to prevent recursive JWT refresh
    private var isRefreshingJWT = false
    private var refreshingContinuations: [CheckedContinuation<Void, Never>] = []
    
    /// The current Gigya login token, if available.
    public private(set) var gigyaLoginToken: String?
    /// The current Gigya JWT, if available.
    public private(set) var gigyaJWT: String?
    
    /// Initializes a new RenaultAPI client.
    /// - Parameters:
    ///   - config: The configuration to use.
    ///   - session: The URLSession to use (default: .shared).
    public init(config: Config, session: URLSession = .shared) {
        self.cfg = config
        self.urlSession = session
        
        if let sessionInfo = KeychainHelper.readCodable(GigyaLoginResponse.SessionInfo.self,
                                                        service: "MyRenault4API",
                                                        account: "sessionInfo")
        {
            self.gigyaLoginToken = sessionInfo.loginToken ?? sessionInfo.cookieValue
        }
    }
    
    // MARK: - Low-level HTTP
    //
    // Internal: HTTP request helpers.
    
    /// Performs a URLRequest and returns the response Data, throwing on HTTP errors.
    private func data(for request: URLRequest) async throws -> Data {
        let (data, resp) = try await urlSession.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw RenaultAPIError.unexpected("No HTTPURLResponse") }
        if (200..<300).contains(http.statusCode) { return data }
        let body = String(data: data, encoding: .utf8) ?? ""
        throw RenaultAPIError.http(http.statusCode, body)
    }
    
    /// Builds a URLRequest with the specified method, URL, headers, and optional JSON body.
    private func makeRequest(
        method: String,
        url: URL,
        headers: [String: String] = [:],
        jsonBody: Encodable? = nil
    ) throws -> URLRequest {
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        req.httpMethod = method
        // Default Accept header
        req.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        // Only set Content-Type when sending a body
        if jsonBody != nil {
            req.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        }
        headers.forEach { req.addValue($1, forHTTPHeaderField: $0) }
        if let body = jsonBody {
            do {
                req.httpBody = try JSONEncoder.renault().encode(AnyEncodable(body))
            } catch {
                throw RenaultAPIError.encoding(error)
            }
        }
        return req
    }
    
    // MARK: - Gigya API
    //
    // Authentication and account management via Gigya.
    
    @discardableResult public func gigyaLogin(loginID: String? = nil, password: String? = nil) async throws -> GigyaLoginResponse {
        /// Logs in to Gigya and returns the login response.
        let url = cfg.gigyaRootURL.appendingPathComponent("accounts.login")
        
        guard let username = loginID ?? KeychainHelper.read(service: "MyRenault4API", account: "username"),
              let password = password ?? KeychainHelper.read(service: "MyRenault4API", account: "password")
        else {
            throw RenaultAPIError.missingCredentials
        }
        
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "apikey", value: cfg.gigyaApiKey),
            .init(name: "loginID", value: username),
            .init(name: "password", value: password)
        ]
        guard let finalURL = comps.url else { throw RenaultAPIError.invalidURL(comps.string ?? "") }
        var req = URLRequest(url: finalURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data = try await data(for: req)
        let resp = try JSONDecoder.renault().decode(GigyaLoginResponse.self, from: data)
        if let code = resp.errorCode, code != 0 {
            throw RenaultAPIError.http(code, resp.errorMessage ?? "Gigya login failed")
        }
        guard let session = resp.sessionInfo else {
            throw RenaultAPIError.unexpected("Missing session info after login")
        }
        
        // Save token from either loginToken or cookieValue only after success.
        KeychainHelper.save(loginID ?? username, service: "MyRenault4API", account: "username")
        KeychainHelper.save(password, service: "MyRenault4API", account: "password")
        KeychainHelper.saveCodable(session, service: "MyRenault4API", account: "sessionInfo")
        self.gigyaLoginToken = session.loginToken ?? session.cookieValue
        return resp
    }
    
    public func gigyaGetAccountInfo(loginToken: String? = nil) async throws -> GigyaGetAccountInfoResponse {
        /// Retrieves Gigya account info for the current login token.
        return try await withAuthRetry { [self] in
            let loginToken = try loginToken ?? self.gigyaLoginToken ?? {
                throw RenaultAPIError.missingAuthToken
            }()
            let url = cfg.gigyaRootURL.appendingPathComponent("accounts.getAccountInfo")
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                .init(name: "apikey", value: cfg.gigyaApiKey),
                .init(name: "login_token", value: loginToken)
            ]
            guard let finalURL = comps.url else { throw RenaultAPIError.invalidURL(comps.string ?? "") }
            var req = URLRequest(url: finalURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let data = try await data(for: req)
            return try JSONDecoder.renault().decode(GigyaGetAccountInfoResponse.self, from: data)
        }
    }
    
    public func gigyaGetJWT(loginToken: String? = nil) async throws -> GigyaGetJWTResponse {
        let token = try loginToken ?? self.gigyaLoginToken ?? {
            throw RenaultAPIError.missingAuthToken
        }()
        let url = cfg.gigyaRootURL.appendingPathComponent("accounts.getJWT")
        let bodyParams = [
            "login_token": token,
            "APIKey": cfg.gigyaApiKey,
            "fields": "data.personId,data.gigyaDataCenter,data.cookieRefresh",
            "expiration": "900",
            "site": "renaultprod"
        ]
        let formBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = formBody.data(using: .utf8)
        let data = try await data(for: req)
        do {
            let resp = try JSONDecoder.renault().decode(GigyaGetJWTResponse.self, from: data)
            self.gigyaJWT = resp.idToken
            return resp
        } catch {
            if error is DecodingError {
                throw RenaultAPIError.missingCredentials
            } else {
                throw error
            }
        }
    }
    
    /// Logs out the user and clears all credentials and tokens.
    public func logout() {
        KeychainHelper.delete(service: "MyRenault4API", account: "username")
        KeychainHelper.delete(service: "MyRenault4API", account: "password")
        KeychainHelper.delete(service: "MyRenault4API", account: "sessionInfo")
        self.gigyaLoginToken = nil
        self.gigyaJWT = nil
    }
    
    // MARK: - Kamereon API
    //
    // Helpers and endpoints for Kamereon vehicle data and commands.
    
    /// Builds standard Kamereon headers for authenticated requests.
    private func kamereonHeaders() throws -> [String:String] {
        guard let jwt = self.gigyaJWT else {
            throw RenaultAPIError.missingAuthToken
        }
        return [
            "apikey": cfg.kamereonApiKey,
            "x-gigya-id_token": jwt,
            "x-kamereon-authorization": "Bearer \(jwt)",
            "Content-Type": "application/vnd.api+json",
            "Accept": "application/vnd.api+json",
            "Accept-Encoding": "gzip, deflate",
            "User-Agent": "okhttp/4.9.3", /// mimics Android MyRenault client
            "Connection": "Keep-Alive"
        ]
    }
    
    /// Builds a URL by appending the given path components to the Kamereon root URL.
    private func buildURL(_ parts: [String]) -> URL {
        parts.reduce(cfg.kamereonRootURL) { $0.appendingPathComponent($1) }
    }
    
    // MARK: - Kamereon endpoints
    
    /// Helper: Retry an operation on authentication error by refreshing credentials once.
    private func withAuthRetry<T>(operation: @escaping () async throws -> T) async throws -> T {
        // ✅ Check credentials; do not attempt refresh if there are no credentials.
        let storedUsername = KeychainHelper.read(service: "MyRenault4API", account: "username")
        let storedPassword = KeychainHelper.read(service: "MyRenault4API", account: "password")
        guard storedUsername != nil, storedPassword != nil else {
            print("[Auth] No stored credentials — requesting manual login")
            throw RenaultAPIError.missingCredentials
        }
        
        // 🔐 If we have stored credentials but no Gigya session token, perform a login first.
        if self.gigyaLoginToken == nil {
            print("[Auth] Missing login token but credentials exist — performing background login")
            _ = try await self.gigyaLogin()
        }
        
        // 🔁 Standard retry logic with reentrancy guard for JWT refresh
        if (try? self.gigyaJWT?.isJWTExpired()) ?? true {
            if isRefreshingJWT {
                // Wait for the current refresh to complete
                print("[Auth] Waiting for ongoing JWT refresh...")
                await withCheckedContinuation { continuation in
                    refreshingContinuations.append(continuation)
                }
            } else {
                isRefreshingJWT = true
                print("[Auth] JWT missing or expired, refreshing (single instance)...")
                do {
                    _ = try await self.gigyaGetJWT(loginToken: self.gigyaLoginToken)
                } catch {
                    // Notify all waiting tasks and propagate error
                    isRefreshingJWT = false
                    for cont in refreshingContinuations { cont.resume() }
                    refreshingContinuations.removeAll()
                    throw error
                }
                // Notify all waiting tasks that refresh completed
                isRefreshingJWT = false
                for cont in refreshingContinuations { cont.resume() }
                refreshingContinuations.removeAll()
            }
        }
        
        do {
            return try await operation()
        } catch let error as RenaultAPIError {
            switch error {
            case .http(let code, _) where code == 401:
                print("[Auth] 401 received, attempting JWT refresh then retry...")
                if !isRefreshingJWT {
                    isRefreshingJWT = true
                    defer { isRefreshingJWT = false }
                    do {
                        _ = try await self.gigyaGetJWT(loginToken: self.gigyaLoginToken)
                        return try await operation()
                    } catch {
                        print("[Auth] JWT refresh failed, attempting full login and retry...")
                        _ = try await self.gigyaLogin()
                        _ = try await self.gigyaGetJWT(loginToken: self.gigyaLoginToken)
                        return try await operation()
                    }
                } else {
                    throw error
                }
            case .missingCredentials:
                print("[Auth] Missing credentials — trigger captive login UI")
                throw RenaultAPIError.missingCredentials
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    /// Retrieves person/account info from Kamereon.
    /// - Parameter personId: The person ID.
    public func getAccountIds(personId: String) async throws -> KamereonPersonResponse {
        return try await withAuthRetry { [weak self] in
            guard let self = self else {
                throw RenaultAPIError.unexpected("Self deallocated")
            }
            
            // Build the URL
            let url = self.cfg.kamereonRootURL.appendingPathComponent("/commerce/v1/persons/\(personId)")
            guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw RenaultAPIError.invalidURL(url.absoluteString)
            }
            comps.queryItems = [URLQueryItem(name: "country", value: self.cfg.country)]
            guard let headers = try? self.kamereonHeaders() else {
                throw RenaultAPIError.missingAuthToken
            }
            guard let finalURL = comps.url else {
                throw RenaultAPIError.invalidURL(comps.string ?? "")
            }
            let req = try self.makeRequest(method: "GET", url: finalURL, headers: headers)
            let data = try await self.data(for: req)
            return try JSONDecoder.renault().decode(KamereonPersonResponse.self, from: data)
        }
    }
    
    /// Retrieves the list of vehicles for a Kamereon account.
    /// - Parameter accountId: The Kamereon account ID.
    public func getVehicles(accountId: String) async throws -> KamereonAccountVehiclesResponse {
        return try await withAuthRetry { [weak self] in
            guard let self = self else { throw RenaultAPIError.unexpected("Self deallocated") }
            let base = self.buildURL(["commerce", "v1", "accounts", accountId, "vehicles"])
            guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
                throw RenaultAPIError.invalidURL(base.absoluteString)
            }
            comps.queryItems = [.init(name: "country", value: self.cfg.country)]
            guard let headers = try? self.kamereonHeaders() else {
                throw RenaultAPIError.missingAuthToken
            }
            guard let finalURL = comps.url else {
                throw RenaultAPIError.invalidURL(comps.string ?? "")
            }
            let req = try self.makeRequest(method: "GET", url: finalURL, headers: headers)
            let data = try await self.data(for: req)
            return try JSONDecoder.renault().decode(KamereonAccountVehiclesResponse.self, from: data)
        }
    }
    
    /// Generic GET for car-adapter and vehicles endpoints based on endpointType.
    /// - Parameters:
    ///   - accountId: Kamereon account ID.
    ///   - vin: Vehicle VIN.
    ///   - endpoint: Vehicle API endpoint.
    ///   - endpointType: The endpoint type (.kcm or .kca).
    ///   - startDate: Optional start date (for history endpoints).
    ///   - endDate: Optional end date (for history endpoints).
    ///   - version: API version (default: 1).
    public func getVehicleData<T: Decodable>(accountId: String, vin: String, endpoint: VehicleEndpoint, endpointType: VehicleEndpointType, startDate: String? = nil, endDate: String? = nil, version: Int = 1) async throws -> T {
        return try await withAuthRetry { [weak self] in
            guard let self = self else { throw RenaultAPIError.unexpected("Self deallocated") }
            let base: URL!
            if endpointType == .kcm {
                base = self.buildURL(["commerce", "v1", "accounts", accountId, "kamereon", endpointType.rawValue, "v\(version)", "vehicles", vin, "ev", endpoint.rawValue])
            } else {
                base = self.buildURL(["commerce", "v1", "accounts", accountId, "kamereon", endpointType.rawValue, "car-adapter", "v\(version)", "cars", vin, endpoint.rawValue])
            }
            guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
                throw RenaultAPIError.invalidURL(base.absoluteString)
            }
            comps.queryItems = [.init(name: "country", value: self.cfg.country)]
            if let startDate {
                comps.queryItems?.append(.init(name: "start", value: startDate))
            }
            if let endDate {
                comps.queryItems?.append(.init(name: "end", value: endDate))
            }
            guard let headers = try? self.kamereonHeaders() else {
                throw RenaultAPIError.missingAuthToken
            }
            guard let finalURL = comps.url else {
                throw RenaultAPIError.invalidURL(comps.string ?? "")
            }
            do {
                let req = try self.makeRequest(method: "GET", url: finalURL, headers: headers)
                let data = try await self.data(for: req)
                print(String(data: data, encoding: .utf8) ?? "")
                return try JSONDecoder.renault().decode(T.self, from: data)
            } catch {
                print(error)
                throw error
            }
        }
    }
    
    /// Generic POST for car-adapter and vehicles endpoints based on endpointType.
    /// - Parameters:
    ///   - accountId: Kamereon account ID.
    ///   - vin: Vehicle VIN.
    ///   - endpoint: Vehicle API endpoint.
    ///   - endpointType: The endpoint type (.kcm or .kca).
    ///   - payload: The payload to send.
    ///   - version: API version (default: 1).
    public func setVehicleData(accountId: String, vin: String, endpoint: VehicleEndpoint, endpointType: VehicleEndpointType, payload: Codable, version: Int = 1) async throws -> KamereonCommandResponse {
        return try await withAuthRetry { [weak self] in
            guard let self = self else { throw RenaultAPIError.unexpected("Self deallocated") }
            let base: URL!
            if endpointType == .kcm {
                base = self.buildURL(["commerce", "v1", "accounts", accountId, "kamereon", endpointType.rawValue, "v\(version)", "vehicles", vin, "ev", endpoint.rawValue])
            } else {
                base = self.buildURL(["commerce", "v1", "accounts", accountId, "kamereon", endpointType.rawValue, "car-adapter", "v\(version)", "cars", vin, endpoint.rawValue])
            }
            guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
                throw RenaultAPIError.invalidURL(base.absoluteString)
            }
            comps.queryItems = [.init(name: "country", value: self.cfg.country)]
            
            guard let headers = try? self.kamereonHeaders() else {
                throw RenaultAPIError.missingAuthToken
            }
            guard let finalURL = comps.url else {
                throw RenaultAPIError.invalidURL(comps.string ?? "")
            }
            
            var req = try self.makeRequest(method: "POST", url: finalURL, headers: headers)
            req.httpBody = try? JSONEncoder().encode(payload)
            let data = try await self.data(for: req)
            print(String(data: data, encoding: .utf8) ?? "")
            return try JSONDecoder.renault().decode(KamereonCommandResponse.self, from: data)
        }
    }
}

// MARK: - Convenience Endpoints

/// Syntactic sugar for common vehicle API endpoints.
public extension MyRenaultOpenAPI {
    /// Retrieves cockpit information for a vehicle.
    func getCockpit(accountId: String, vin: String) async throws -> KamereonCockpitResponse {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .cockpit, endpointType: .kca, version: 1)
    }
    /// Retrieves battery status for a vehicle.
    func getBatteryStatus(accountId: String, vin: String) async throws -> KamereonBatteryStatusResponse {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .batteryStatus, endpointType: .kca, version: 2)
    }
    /// Retrieves SoC (State of Charge) levels for a vehicle.
    func getSocLevels(accountId: String, vin: String) async throws -> KamereonChargeSettings {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .socLevels, endpointType: .kcm, version: 1)
    }
    /// Retrieves HVAC (climate) status for a vehicle.
    func getHvacStatus(accountId: String, vin: String) async throws -> KamereonHvacStatusResponse {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .hvacStatus, endpointType: .kca, version: 1)
    }
    /// Retrieves vehicle location.
    func getLocation(accountId: String, vin: String) async throws -> KamereonLocationResponse {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .location, endpointType: .kca, version: 1)
    }
    /// Retrieves lock status for a vehicle.
    func getLockStatus(accountId: String, vin: String) async throws -> KamereonLockStatusResponse {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .lockStatus, endpointType: .kca, version: 1)
    }
    /// Retrieves vehicle charging history.
    func getChargingHistory(accountId: String, vin: String, startDate: String, endDate: String) async throws -> KamereonChargesResponse {
        try await getVehicleData(accountId: accountId, vin: vin, endpoint: .charges, endpointType: .kca, startDate: startDate, endDate: endDate, version: 1)
    }
    /// Sets SoC (State of Charge) levels for a vehicle.
    func setSocLevels(accountId: String, vin: String, payload: KamereonChargeSettings) async throws -> KamereonCommandResponse {
        try await setVehicleData(accountId: accountId, vin: vin, endpoint: .socLevels, endpointType: .kcm, payload: payload)
    }
    
    /// An empty request body for endpoints that require a body but no parameters.
    struct EmptyBody: Codable {}
}
