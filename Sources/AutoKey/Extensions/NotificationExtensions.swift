//
//  NotificationExtensions.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the simulation state changes (started/stopped)
    static let simulationStateChanged = Notification.Name("simulationStateChanged")
    
    /// Posted when application settings are changed
    static let settingsChanged = Notification.Name("settingsChanged")
    
    /// Posted when permission status changes
    static let permissionsChanged = Notification.Name("permissionsChanged")
    
    /// Posted when simulation settings are updated (e.g., clicks per second)
    static let simulationSettingsUpdated = Notification.Name("simulationSettingsUpdated")
}
