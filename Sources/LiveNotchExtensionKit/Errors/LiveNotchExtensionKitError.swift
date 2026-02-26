//
//  LiveNotchExtensionKitError.swift
//  LiveNotchExtensionKit
//
//  Error types for LiveNotchExtensionKit.
//

import Foundation

/// Errors that can occur when using LiveNotchExtensionKit.
public enum LiveNotchExtensionKitError: LocalizedError, Sendable {
    /// LiveNotch is not installed on this system
    case LiveNotchNotInstalled
    
    /// LiveNotch version is incompatible with this SDK version
    case incompatibleVersion(required: String, found: String)
    
    /// App is not authorized to use LiveNotch
    case notAuthorized
    
    /// Invalid descriptor data
    case invalidDescriptor(reason: String)
    
    /// XPC connection failed
    case connectionFailed(underlying: Error?)
    
    /// XPC service is unavailable
    case serviceUnavailable
    
    /// Activity limit exceeded
    case limitExceeded(limit: Int)
    
    /// Unknown error
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .LiveNotchNotInstalled:
            return "LiveNotch is not installed. Please install LiveNotch to use live activities."
        case .incompatibleVersion(let required, let found):
            return "LiveNotch version \(found) is incompatible. Required version: \(required) or later."
        case .notAuthorized:
            return "App is not authorized to display live activities. User must grant permission in LiveNotch Settings."
        case .invalidDescriptor(let reason):
            return "Invalid descriptor: \(reason)"
        case .connectionFailed(let error):
            if let error {
                return "Failed to connect to LiveNotch: \(error.localizedDescription)"
            }
            return "Failed to connect to LiveNotch."
        case .serviceUnavailable:
            return "LiveNotch service is temporarily unavailable. Please try again later."
        case .limitExceeded(let limit):
            return "Activity limit exceeded. Maximum \(limit) concurrent activities allowed."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
