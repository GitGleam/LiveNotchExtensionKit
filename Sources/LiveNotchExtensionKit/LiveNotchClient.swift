//
//  LiveNotchClient.swift
//  LiveNotchExtensionKit
//
//  Main client interface for third-party apps to communicate with LiveNotch.
//

import Foundation

/// Main client class for interacting with LiveNotch.
@MainActor
public final class LiveNotchClient: @unchecked Sendable {
    /// Shared singleton instance
    public static let shared = LiveNotchClient()
    
    private let connectionManager: LiveNotchXPCConnectionManager
    private var authorizationCallbacks: [(Bool) -> Void] = []
    private var activityDismissalHandlers: [String: () -> Void] = [:]
    private var widgetDismissalHandlers: [String: () -> Void] = [:]
    private var notchDismissalHandlers: [String: () -> Void] = [:]
    
    /// Initialize a new LiveNotchClient instance.
    /// For most use cases, use `LiveNotchClient.shared` instead.
    public init() {
        self.connectionManager = LiveNotchXPCConnectionManager()
        setupNotificationHandlers()
    }
    
    // MARK: - Installation & Version Checks
    
    /// Check if LiveNotch is installed on this system.
    public var isLiveNotchInstalled: Bool {
        connectionManager.isLiveNotchInstalled
    }
    
    /// Get the installed LiveNotch version (nil if not installed).
    public func getLiveNotchVersion() async throws -> String {
        try await connectionManager.getVersion()
    }
    
    /// Check version compatibility.
    public func checkCompatibility(minimumVersion: String = "1.0.0") async throws {
        let installedVersion = try await getLiveNotchVersion()
        if !isVersionCompatible(installed: installedVersion, required: minimumVersion) {
            throw LiveNotchExtensionKitError.incompatibleVersion(required: minimumVersion, found: installedVersion)
        }
    }
    
    // MARK: - Authorization
    
    /// Request authorization to display live activities.
    /// This will prompt the user if not already authorized.
    public func requestAuthorization() async throws -> Bool {
        try await connectionManager.requestAuthorization()
    }
    
    /// Check if the app is currently authorized.
    public func checkAuthorization() async throws -> Bool {
        try await connectionManager.checkAuthorization()
    }
    
    /// Register a callback for authorization status changes.
    public func onAuthorizationChange(_ callback: @escaping (Bool) -> Void) {
        authorizationCallbacks.append(callback)
    }
    
    // MARK: - Live Activities
    
    /// Present a live activity.
    /// - Parameter descriptor: The activity descriptor
    /// - Throws: LiveNotchExtensionKitError if presentation fails
    public func presentLiveActivity(_ descriptor: LiveNotchLiveActivityDescriptor) async throws {
        guard descriptor.isValid else {
            throw LiveNotchExtensionKitError.invalidDescriptor(reason: "Descriptor validation failed")
        }
        
        let isAuthorized = try await checkAuthorization()
        guard isAuthorized else {
            throw LiveNotchExtensionKitError.notAuthorized
        }
        
        try await connectionManager.presentLiveActivity(descriptor)
    }
    
    /// Update an existing live activity.
    /// - Parameter descriptor: Updated descriptor (must have same ID)
    /// - Throws: LiveNotchExtensionKitError if update fails
    public func updateLiveActivity(_ descriptor: LiveNotchLiveActivityDescriptor) async throws {
        guard descriptor.isValid else {
            throw LiveNotchExtensionKitError.invalidDescriptor(reason: "Descriptor validation failed")
        }
        
        try await connectionManager.updateLiveActivity(descriptor)
    }
    
    /// Dismiss a live activity.
    /// - Parameter activityID: The activity identifier to dismiss
    /// - Throws: LiveNotchExtensionKitError if dismissal fails
    public func dismissLiveActivity(activityID: String) async throws {
        try await connectionManager.dismissLiveActivity(activityID: activityID)
    }
    
    /// Register a callback for when an activity is dismissed (by user or system).
    /// - Parameter activityID: The activity to monitor
    /// - Parameter callback: Called when activity is dismissed
    public func onActivityDismiss(activityID: String, callback: @escaping () -> Void) {
        activityDismissalHandlers[activityID] = callback
    }
    
    // MARK: - Lock Screen Widgets
    
    /// Present a lock screen widget.
    /// - Parameter descriptor: The widget descriptor
    /// - Throws: LiveNotchExtensionKitError if presentation fails
    public func presentLockScreenWidget(_ descriptor: LiveNotchLockScreenWidgetDescriptor) async throws {
        guard descriptor.isValid else {
            throw LiveNotchExtensionKitError.invalidDescriptor(reason: "Widget descriptor validation failed")
        }
        
        let isAuthorized = try await checkAuthorization()
        guard isAuthorized else {
            throw LiveNotchExtensionKitError.notAuthorized
        }
        
        try await connectionManager.presentLockScreenWidget(descriptor)
    }
    
    /// Update an existing lock screen widget.
    /// - Parameter descriptor: Updated descriptor (must have same ID)
    /// - Throws: LiveNotchExtensionKitError if update fails
    public func updateLockScreenWidget(_ descriptor: LiveNotchLockScreenWidgetDescriptor) async throws {
        guard descriptor.isValid else {
            throw LiveNotchExtensionKitError.invalidDescriptor(reason: "Widget descriptor validation failed")
        }
        
        try await connectionManager.updateLockScreenWidget(descriptor)
    }
    
    /// Dismiss a lock screen widget.
    /// - Parameter widgetID: The widget identifier to dismiss
    /// - Throws: LiveNotchExtensionKitError if dismissal fails
    public func dismissLockScreenWidget(widgetID: String) async throws {
        try await connectionManager.dismissLockScreenWidget(widgetID: widgetID)
    }
    
    /// Register a callback for when a widget is dismissed.
    /// - Parameter widgetID: The widget to monitor
    /// - Parameter callback: Called when widget is dismissed
    public func onWidgetDismiss(widgetID: String, callback: @escaping () -> Void) {
        widgetDismissalHandlers[widgetID] = callback
    }

    // MARK: - Notch Experiences

    /// Present a notch experience (standard + minimalistic layouts).
    /// - Parameter descriptor: The notch descriptor
    public func presentNotchExperience(_ descriptor: LiveNotchNotchExperienceDescriptor) async throws {
        guard descriptor.isValid else {
            throw LiveNotchExtensionKitError.invalidDescriptor(reason: "Notch descriptor validation failed")
        }

        let isAuthorized = try await checkAuthorization()
        guard isAuthorized else {
            throw LiveNotchExtensionKitError.notAuthorized
        }

        try await connectionManager.presentNotchExperience(descriptor)
    }

    /// Update a notch experience.
    /// - Parameter descriptor: Updated descriptor (must match ID)
    public func updateNotchExperience(_ descriptor: LiveNotchNotchExperienceDescriptor) async throws {
        guard descriptor.isValid else {
            throw LiveNotchExtensionKitError.invalidDescriptor(reason: "Notch descriptor validation failed")
        }

        try await connectionManager.updateNotchExperience(descriptor)
    }

    /// Dismiss a notch experience.
    /// - Parameter experienceID: Identifier of the notch experience
    public func dismissNotchExperience(experienceID: String) async throws {
        try await connectionManager.dismissNotchExperience(experienceID: experienceID)
    }

    /// Register a callback for notch experience dismissal events.
    public func onNotchExperienceDismiss(experienceID: String, callback: @escaping () -> Void) {
        notchDismissalHandlers[experienceID] = callback
    }
    
    // MARK: - Private Helpers
    
    private func setupNotificationHandlers() {
        connectionManager.onAuthorizationChange = { [weak self] isAuthorized in
            Task { @MainActor in
                self?.authorizationCallbacks.forEach { $0(isAuthorized) }
            }
        }
        
        connectionManager.onActivityDismiss = { [weak self] activityID in
            Task { @MainActor in
                self?.activityDismissalHandlers[activityID]?()
                self?.activityDismissalHandlers.removeValue(forKey: activityID)
            }
        }
        
        connectionManager.onWidgetDismiss = { [weak self] widgetID in
            Task { @MainActor in
                self?.widgetDismissalHandlers[widgetID]?()
                self?.widgetDismissalHandlers.removeValue(forKey: widgetID)
            }
        }

        connectionManager.onNotchExperienceDismiss = { [weak self] experienceID in
            Task { @MainActor in
                self?.notchDismissalHandlers[experienceID]?()
                self?.notchDismissalHandlers.removeValue(forKey: experienceID)
            }
        }
    }
    
    private func isVersionCompatible(installed: String, required: String) -> Bool {
        let installedParts = installed.split(separator: ".").compactMap { Int($0) }
        let requiredParts = required.split(separator: ".").compactMap { Int($0) }
        
        for (index, requiredPart) in requiredParts.enumerated() {
            guard index < installedParts.count else { return false }
            if installedParts[index] < requiredPart {
                return false
            } else if installedParts[index] > requiredPart {
                return true
            }
        }
        return true
    }
}
