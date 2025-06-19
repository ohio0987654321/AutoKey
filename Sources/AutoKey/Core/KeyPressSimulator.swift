//
//  KeyPressSimulator.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation
import CoreGraphics
import ApplicationServices

/// Handles keyboard input simulation using Core Graphics events
class KeyPressSimulator {
    
    // MARK: - Error Types
    
    /// Errors that can occur during key press simulation
    enum SimulationError: Error, LocalizedError {
        case permissionDenied
        case noTargetKeySet
        case eventSourceCreationFailed
        case eventCreationFailed
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Accessibility permission is required to simulate key presses"
            case .noTargetKeySet:
                return "No target key has been set"
            case .eventSourceCreationFailed:
                return "Failed to create event source"
            case .eventCreationFailed:
                return "Failed to create key event"
            }
        }
    }
    
    // MARK: - Static Properties
    
    static let shared = KeyPressSimulator()
    
    // MARK: - Private Properties
    
    private var clickTimer: Timer?
    private var isSimulating = false
    private let simulationQueue = DispatchQueue(label: "com.autokeyclick.simulator", qos: .userInitiated)
    private let stateQueue = DispatchQueue(label: "com.autokeyclick.state", qos: .userInitiated)
    
    // For state verification
    private var lastStateCorrection = Date(timeIntervalSince1970: 0)
    
    // MARK: - Public Properties
    
    /// Current simulation state
    var isActive: Bool {
        stateQueue.sync {
            return isSimulating && clickTimer != nil
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSimulationSettingsUpdated),
            name: .simulationSettingsUpdated,
            object: nil
        )
    }
    
    @objc private func handleSimulationSettingsUpdated() {
        updateSimulationSettings()
    }
    
    // MARK: - Public Methods
    
    /// Start simulating key presses with the current settings
    func startSimulation() {
        // Ensure we're on the main thread for UI updates
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                self.startSimulation()
            }
            return
        }
        
        // Check if already running
        guard !isActive else {
            return
        }
        
        // Check permissions
        guard PermissionManager.shared.hasAccessibilityPermission else {
            notifyError(.permissionDenied)
            return
        }
        
        let settings = AppSettings.shared
        
        // Ensure we have a target key
        guard let targetKeyCode = settings.targetKeyCode else {
            notifyError(.noTargetKeySet)
            return
        }
        
        // Make sure any existing timer is invalidated
        invalidateTimer()
        
        // Create local copies of the target key code and modifiers
        let keyCode = targetKeyCode
        let modifiers = settings.targetKeyModifiers
        
        // Get the current click interval
        let interval = settings.clickInterval
        
        // Start the timer on the main queue
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            self.simulateKeyPress(keyCode: keyCode, modifiers: modifiers)
        }
        
        // Store the timer reference
        self.clickTimer = timer
        
        // Update state
        stateQueue.sync {
            isSimulating = true
        }
        
        // Update settings
        settings.isClickingActive = true
        
        // Post notification about state change
        NotificationCenter.default.post(name: .simulationStateChanged, object: nil)
        
        // Fire first key press immediately in background
        simulationQueue.async { [weak self] in
            guard let self = self, self.isActive else { return }
            self.simulateKeyPress(keyCode: keyCode, modifiers: modifiers)
        }
    }
    
    /// Stop the key simulation
    func stopSimulation() {
        // Update state immediately
        stateQueue.sync {
            isSimulating = false
        }
        
        // Update app settings
        AppSettings.shared.isClickingActive = false
        
        // Invalidate timer on main thread
        if Thread.isMainThread {
            invalidateTimer()
        } else {
            DispatchQueue.main.sync {
                self.invalidateTimer()
            }
        }
        
        // Post notification about state change
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .simulationStateChanged, object: nil)
        }
    }
    
    /// Toggle simulation on/off
    func toggleSimulation() {
        // Ensure we're on the main thread for UI updates
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                self.toggleSimulation()
            }
            return
        }
        
        // Prevent rapid toggling
        let now = Date()
        if now.timeIntervalSince(lastStateCorrection) < 0.2 {
            return
        }
        
        lastStateCorrection = now
        
        if isActive {
            stopSimulation()
        } else {
            startSimulation()
        }
    }
    
    /// Simulate a single key press for testing purposes
    func simulateSingleKeyPress(keyCode: CGKeyCode, modifiers: UInt32 = 0) {
        guard PermissionManager.shared.hasAccessibilityPermission else {
            notifyError(.permissionDenied)
            return
        }
        
        simulateKeyPress(keyCode: keyCode, modifiers: modifiers)
    }
    
    /// Update simulation settings (restart if currently running)
    func updateSimulationSettings() {
        // Get current state before stopping
        let wasSimulating = isActive
        
        if wasSimulating {
            // Stop current simulation
            stopSimulation()
            
            // Restart with new settings
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.startSimulation()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Helper method to invalidate the timer
    private func invalidateTimer() {
        if let timer = clickTimer {
            timer.invalidate()
            self.clickTimer = nil
        }
    }
    
    /// Notify about an error
    private func notifyError(_ error: SimulationError) {
        print("KeyPressSimulator error: \(error.localizedDescription)")
        // Could add more sophisticated error handling here
    }
    
    /// Simulate a key press using Core Graphics events
    private func simulateKeyPress(keyCode: CGKeyCode, modifiers: UInt32 = 0) {
        simulationQueue.async {
            do {
                try self.performKeyPress(keyCode: keyCode, modifiers: modifiers)
            } catch let error as SimulationError {
                print("Key press simulation error: \(error.localizedDescription)")
            } catch {
                print("Unexpected error during key press simulation: \(error)")
            }
        }
    }
    
    /// Perform the actual key press with error handling
    private func performKeyPress(keyCode: CGKeyCode, modifiers: UInt32) throws {
        // Handle modifier keys properly
        var cgModifiers = CGEventFlags()
        
        // Convert Carbon modifiers to CGEventFlags
        if modifiers & 0x0100 != 0 {  // cmdKey
            cgModifiers.insert(.maskCommand)
        }
        if modifiers & 0x0200 != 0 {  // shiftKey
            cgModifiers.insert(.maskShift)
        }
        if modifiers & 0x0800 != 0 {  // optionKey
            cgModifiers.insert(.maskAlternate)
        }
        if modifiers & 0x1000 != 0 {  // controlKey
            cgModifiers.insert(.maskControl)
        }
        
        // Create event source
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw SimulationError.eventSourceCreationFailed
        }
        
        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) else {
            throw SimulationError.eventCreationFailed
        }
        
        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            throw SimulationError.eventCreationFailed
        }
        
        // Set event flags to include modifiers
        keyDownEvent.flags = cgModifiers
        keyUpEvent.flags = cgModifiers
        
        // Post the events to the system
        keyDownEvent.post(tap: .cghidEventTap)
        
        // Small delay between key down and key up to simulate realistic key press
        usleep(10000) // 10ms delay
        
        keyUpEvent.post(tap: .cghidEventTap)
    }
}

// MARK: - KeyPressSimulator State Management

extension KeyPressSimulator {
    
    /// Get current simulation statistics
    var simulationStats: (isActive: Bool, targetKey: String, clicksPerSecond: Double) {
        let settings = AppSettings.shared
        return (
            isActive: isActive,
            targetKey: settings.targetKeyDescription,
            clicksPerSecond: settings.clicksPerSecond
        )
    }
    
    /// Check if simulation can be started (permissions check)
    var canStartSimulation: Bool {
        return PermissionManager.shared.hasAccessibilityPermission && !isActive
    }
    
    /// Get human-readable status description
    var statusDescription: String {
        if isActive {
            let settings = AppSettings.shared
            return "Active - Pressing '\(settings.targetKeyDescription)' at \(Int(settings.clicksPerSecond)) CPS"
        } else {
            return "Stopped"
        }
    }
}
