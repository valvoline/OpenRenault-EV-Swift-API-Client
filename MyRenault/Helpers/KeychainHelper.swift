//
//  KeychainHelper.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//


import Foundation
import Security

enum KeychainHelper {
    // MARK: - Base Methods (String)
    static func save(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        saveData(data, service: service, account: account)
    }
    
    static func read(service: String, account: String) -> String? {
        guard let data = readData(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func delete(service: String, account: String) {
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
    }
    
    // MARK: - Data-level primitives
    private static func saveData(_ data: Data, service: String, account: String) {
        // Rimuove eventuale valore esistente
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
        
        // Salva nuovo dato
        SecItemAdd([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary, nil)
    }
    
    private static func readData(service: String, account: String) -> Data? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary, &item)
        
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
    
    // MARK: - Codable support 🧩
    static func saveCodable<T: Codable>(_ object: T, service: String, account: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            saveData(data, service: service, account: account)
        } catch {
            print("❌ KeychainHelper: Encoding error - \(error)")
        }
    }
    
    static func readCodable<T: Codable>(_ type: T.Type, service: String, account: String) -> T? {
        guard let data = readData(service: service, account: account) else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("❌ KeychainHelper: Decoding error - \(error)")
            return nil
        }
    }
}
