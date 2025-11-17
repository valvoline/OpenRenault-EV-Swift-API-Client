//
//  RenaultAPIError.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import Foundation

public enum RenaultAPIError: Error, LocalizedError {
    case invalidURL(String)
    case http(Int, String)
    case decoding(Error)
    case encoding(Error)
    case missingAuthToken
    case missingCredentials
    case unexpected(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let s): return "Invalid URL: \(s)"
        case .http(let code, let body): return "HTTP \(code): \(body)"
        case .decoding(let e): return "Decoding error: \(e.localizedDescription)"
        case .encoding(let e): return "Encoding error: \(e.localizedDescription)"
        case .missingAuthToken: return "Missing authentication token"
        case .missingCredentials: return "Missing credentials"
        case .unexpected(let s): return "Unexpected error: \(s)"
        }
    }
}
