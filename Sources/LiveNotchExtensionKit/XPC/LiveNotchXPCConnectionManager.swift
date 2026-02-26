//
//  LiveNotchXPCConnectionManager.swift
//  LiveNotchExtensionKit
//
//  Manages XPC connection to LiveNotch service.
//

import AppKit
import Foundation

final class LiveNotchXPCConnectionManager: NSObject, @unchecked Sendable {
    private static let serviceName = "com.ebullioscopic.LiveNotch.xpc"
    private static let LiveNotchBundleIdentifier = "com.ebullioscopic.LiveNotch"
    private var connection: NSXPCConnection?
    private let queue = DispatchQueue(label: "com.LiveNotch.xpc.connection")
    
    var onAuthorizationChange: ((Bool) -> Void)?
    var onActivityDismiss: ((String) -> Void)?
    var onWidgetDismiss: ((String) -> Void)?
    var onNotchExperienceDismiss: ((String) -> Void)?
    
    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }
    
    var isLiveNotchInstalled: Bool {
        if isLiveNotchRunning {
            return true
        }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.LiveNotchBundleIdentifier) {
            return FileManager.default.fileExists(atPath: appURL.path)
        }

        let fallbackPaths = [
            "/Applications/LiveNotch.app",
            NSString(string: NSHomeDirectory()).appendingPathComponent("Applications/LiveNotch.app")
        ]
        return fallbackPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private var isLiveNotchRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Self.LiveNotchBundleIdentifier).isEmpty
    }
    
    // MARK: - Connection Management
    
    private func getConnection() throws -> NSXPCConnection {
        if let existing = connection {
            return existing
        }
        
        guard isLiveNotchInstalled else {
            throw LiveNotchExtensionKitError.LiveNotchNotInstalled
        }
        
        let newConnection = NSXPCConnection(machServiceName: Self.serviceName, options: [])
        newConnection.remoteObjectInterface = NSXPCInterface(with: LiveNotchXPCServiceProtocol.self)
        newConnection.exportedInterface = NSXPCInterface(with: LiveNotchXPCClientProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.invalidationHandler = { [weak self] in
            self?.connection = nil
        }
        
        newConnection.interruptionHandler = { [weak self] in
            self?.connection = nil
        }
        
        newConnection.resume()
        connection = newConnection
        return newConnection
    }
    
    private func getService() throws -> LiveNotchXPCServiceProtocol {
        let connection = try getConnection()
        
        guard let service = connection.remoteObjectProxyWithErrorHandler({ error in
            print("XPC Error: \(error)")
        }) as? LiveNotchXPCServiceProtocol else {
            throw LiveNotchExtensionKitError.serviceUnavailable
        }
        
        return service
    }
    
    // MARK: - Service Methods
    
    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let service = try getService()
                service.requestAuthorization(bundleIdentifier: bundleIdentifier) { authorized, error in
                    if let error {
                        continuation.resume(throwing: LiveNotchExtensionKitError.connectionFailed(underlying: error))
                    } else {
                        continuation.resume(returning: authorized)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func checkAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let service = try getService()
                service.checkAuthorization(bundleIdentifier: bundleIdentifier) { authorized in
                    continuation.resume(returning: authorized)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getVersion() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let service = try getService()
                service.getVersion { version in
                    continuation.resume(returning: version)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func presentLiveActivity(_ descriptor: LiveNotchLiveActivityDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.presentLiveActivity(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to present activity"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateLiveActivity(_ descriptor: LiveNotchLiveActivityDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.updateLiveActivity(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to update activity"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func dismissLiveActivity(activityID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.dismissLiveActivity(activityID: activityID, bundleIdentifier: bundleIdentifier) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to dismiss activity"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func presentLockScreenWidget(_ descriptor: LiveNotchLockScreenWidgetDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.presentLockScreenWidget(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to present widget"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateLockScreenWidget(_ descriptor: LiveNotchLockScreenWidgetDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.updateLockScreenWidget(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to update widget"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func dismissLockScreenWidget(widgetID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.dismissLockScreenWidget(widgetID: widgetID, bundleIdentifier: bundleIdentifier) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to dismiss widget"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func presentNotchExperience(_ descriptor: LiveNotchNotchExperienceDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.presentNotchExperience(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to present notch experience"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func updateNotchExperience(_ descriptor: LiveNotchNotchExperienceDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.updateNotchExperience(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to update notch experience"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func dismissNotchExperience(experienceID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.dismissNotchExperience(experienceID: experienceID, bundleIdentifier: bundleIdentifier) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? LiveNotchExtensionKitError.unknown("Failed to dismiss notch experience"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    deinit {
        connection?.invalidate()
    }
}

// MARK: - Client Protocol Implementation

extension LiveNotchXPCConnectionManager: LiveNotchXPCClientProtocol {
    func authorizationDidChange(isAuthorized: Bool) {
        onAuthorizationChange?(isAuthorized)
    }
    
    func activityDidDismiss(activityID: String) {
        onActivityDismiss?(activityID)
    }
    
    func widgetDidDismiss(widgetID: String) {
        onWidgetDismiss?(widgetID)
    }
    
    func notchExperienceDidDismiss(experienceID: String) {
        onNotchExperienceDismiss?(experienceID)
    }
}
