//
//  PermissionManager.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation
import ApplicationServices
import Cocoa

/// Manages accessibility and input monitoring permissions for the app
@available(macOS 10.15, *)
class PermissionManager: @unchecked Sendable {
    
    // MARK: - Error Types
    
    /// Errors that can occur during permission operations
    enum PermissionError: Error, LocalizedError {
        case accessibilityPermissionDenied
        case userCancelled
        
        var errorDescription: String? {
            switch self {
            case .accessibilityPermissionDenied:
                return "Accessibility permission is required for this app to function properly"
            case .userCancelled:
                return "Permission request was cancelled by the user"
            }
        }
    }
    
    // MARK: - Static Properties
    
    static let shared = PermissionManager()
    
    // MARK: - Private Properties
    
    private var permissionMonitorTimer: Timer?
    private var permissionCallbacks: [(Bool) -> Void] = []
    
    // MARK: - Initialization
    
    private init() {}
    
    deinit {
        permissionMonitorTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Check if accessibility permissions are granted
    var hasAccessibilityPermission: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Check if the app has all required permissions
    var hasAllRequiredPermissions: Bool {
        return hasAccessibilityPermission
    }
    
    /// Request accessibility permissions from the user
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Request all required permissions
    func requestAllPermissions() {
        if !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }
    
    /// Show permission alert if needed (completion-based API for backward compatibility)
    func showPermissionAlertIfNeeded(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let granted = try await requestPermissionsIfNeeded()
                DispatchQueue.main.async {
                    completion(granted)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Request permissions if needed using async/await
    @available(macOS 10.15, *)
    func requestPermissionsIfNeeded() async throws -> Bool {
        // If we already have permissions, return immediately
        if hasAllRequiredPermissions {
            return true
        }
        
        // Show alert and request permissions
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Permissions Required"
                alert.informativeText = """
                AutoKey needs accessibility permissions to:
                
                • Register global hotkeys
                • Simulate keyboard input
                • Function properly in the background
                
                Please click "Open System Preferences" and enable accessibility for AutoKey in Privacy & Security settings.
                """
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Cancel")
                
                let response = alert.runModal()
                
                if response == .alertFirstButtonReturn {
                    self.requestAccessibilityPermission()
                    
                    // Give user time to grant permission, then check again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if self.hasAllRequiredPermissions {
                            continuation.resume(returning: true)
                        } else {
                            // Start monitoring for permission changes
                            self.startPermissionMonitoring { granted in
                                if granted {
                                    continuation.resume(returning: true)
                                    // Stop monitoring once granted
                                    self.stopPermissionMonitoring()
                                }
                            }
                            
                            // Also set a timeout to avoid waiting forever
                            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                                if !self.hasAllRequiredPermissions {
                                    continuation.resume(throwing: PermissionError.accessibilityPermissionDenied)
                                    self.stopPermissionMonitoring()
                                }
                            }
                        }
                    }
                } else {
                    continuation.resume(throwing: PermissionError.userCancelled)
                }
            }
        }
    }
    
    /// Register a callback to be notified when permission status changes
    func onPermissionStatusChanged(callback: @escaping (Bool) -> Void) {
        permissionCallbacks.append(callback)
        
        // Start monitoring if not already monitoring
        if permissionMonitorTimer == nil {
            startPermissionMonitoring(callback: callback)
        } else {
            // Immediately call with current status
            callback(hasAllRequiredPermissions)
        }
    }
    
    // MARK: - Private Methods
    
    /// Periodically check permissions and notify when they change
    private func startPermissionMonitoring(callback: @escaping (Bool) -> Void) {
        // Store the initial permission state
        let initialState = hasAllRequiredPermissions
        
        // Call the callback with the initial state
        DispatchQueue.main.async {
            callback(initialState)
        }
        
        // Start a timer to check for changes
        permissionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentState = self.hasAllRequiredPermissions
            
            // If the state has changed, notify all callbacks
            if currentState != initialState {
                DispatchQueue.main.async {
                    for callback in self.permissionCallbacks {
                        callback(currentState)
                    }
                }
            }
        }
    }
    
    /// Stop monitoring for permission changes
    private func stopPermissionMonitoring() {
        permissionMonitorTimer?.invalidate()
        permissionMonitorTimer = nil
        permissionCallbacks.removeAll()
    }
}

// MARK: - NSAlert Extension

extension NSAlert {
    /// Convenience method to run alert on main thread
    func runModalOnMainThread() -> NSApplication.ModalResponse {
        if Thread.isMainThread {
            return runModal()
        } else {
            var response: NSApplication.ModalResponse = .alertFirstButtonReturn
            DispatchQueue.main.sync {
                response = self.runModal()
            }
            return response
        }
    }
}
