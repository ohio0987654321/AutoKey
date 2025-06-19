//
//  GlobalHotkeyManager.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation
import AppKit
import Carbon

/// Manages global hotkey registration and detection using Carbon Event Manager
class GlobalHotkeyManager {
    
    // MARK: - Error Types
    
    /// Errors that can occur during hotkey registration
    enum HotkeyError: Error, LocalizedError {
        case permissionDenied
        case registrationFailed(OSStatus)
        case eventHandlerSetupFailed(OSStatus)
        case invalidHotkey
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Accessibility permission is required to register global hotkeys"
            case .registrationFailed(let status):
                return "Failed to register hotkey (error code: \(status))"
            case .eventHandlerSetupFailed(let status):
                return "Failed to set up event handler (error code: \(status))"
            case .invalidHotkey:
                return "Invalid hotkey configuration"
            }
        }
    }
    
    // MARK: - Static Properties
    
    static let shared = GlobalHotkeyManager()
    
    // MARK: - Private Properties
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var isHotkeyRegistered = false
    private var currentKeyCode: CGKeyCode?
    private var currentModifiers: UInt32 = 0
    
    // Debouncing properties
    private var registrationTimer: Timer?
    private var pendingKeyCode: CGKeyCode?
    private var pendingModifiers: UInt32?
    
    // MARK: - Callback Properties
    
    /// Callback triggered when the registered hotkey is pressed
    var hotkeyPressedCallback: (() -> Void)?
    
    /// Optional callback for registration status updates
    var registrationStatusCallback: ((Result<Void, HotkeyError>) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        do {
            try setupCarbonEventHandler()
        } catch let error as HotkeyError {
            print("Failed to initialize GlobalHotkeyManager: \(error.localizedDescription)")
        } catch {
            print("Unexpected error during GlobalHotkeyManager initialization: \(error)")
        }
    }
    
    deinit {
        unregisterHotkey()
        if let handlerRef = eventHandlerRef {
            RemoveEventHandler(handlerRef)
        }
    }
    
    // MARK: - Public Methods
    
    /// Register a global hotkey with the given key code and modifiers (debounced)
    /// - Parameters:
    ///   - keyCode: The key code to register
    ///   - modifiers: The modifier keys (shift, cmd, option, control)
    /// - Returns: True if registration process was initiated successfully
    @discardableResult
    func registerHotkey(keyCode: CGKeyCode?, modifiers: UInt32) -> Bool {
        // If keyCode is nil, unregister any existing hotkey
        if keyCode == nil {
            unregisterHotkey()
            return true
        }
        
        // Check if we're trying to register the same hotkey
        if isHotkeyRegistered && currentKeyCode == keyCode && currentModifiers == modifiers {
            return true
        }
        
        // Store pending registration
        pendingKeyCode = keyCode
        pendingModifiers = modifiers
        
        // Cancel any existing timer
        registrationTimer?.invalidate()
        
        // Debounce the registration by 250ms to prevent rapid system calls
        registrationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.performActualRegistration()
        }
        
        return true
    }
    
    /// Unregister the currently registered hotkey
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
            isHotkeyRegistered = false
            
            // Clear current registration info
            currentKeyCode = nil
            currentModifiers = 0
            
            print("Hotkey unregistered successfully")
        }
    }
    
    /// Check if a hotkey is currently registered
    var hasRegisteredHotkey: Bool {
        return isHotkeyRegistered && hotKeyRef != nil
    }
    
    /// Update the registered hotkey with new settings
    func updateHotkey() {
        let settings = AppSettings.shared
        
        // Only register if we have both a key code and modifiers
        if let keyCode = settings.toggleHotkeyKeyCode, settings.toggleHotkeyModifiers != 0 {
            registerHotkey(
                keyCode: keyCode,
                modifiers: settings.toggleHotkeyModifiers
            )
        } else {
            // If either is missing, unregister any existing hotkey
            unregisterHotkey()
        }
    }
    
    /// Get the current hotkey configuration
    var currentHotkeyConfiguration: (keyCode: CGKeyCode?, modifiers: UInt32) {
        return (currentKeyCode, currentModifiers)
    }
    
    // MARK: - Private Methods
    
    /// Perform the actual hotkey registration (called after debounce delay)
    private func performActualRegistration() {
        guard let keyCode = pendingKeyCode,
              let modifiers = pendingModifiers else {
            return
        }
        
        // Clear pending registration
        pendingKeyCode = nil
        pendingModifiers = nil
        
        // Validate permissions
        guard PermissionManager.shared.hasAccessibilityPermission else {
            let error = HotkeyError.permissionDenied
            registrationStatusCallback?(.failure(error))
            print(error.localizedDescription)
            return
        }
        
        // Validate hotkey configuration
        guard modifiers != 0 else {
            let error = HotkeyError.invalidHotkey
            registrationStatusCallback?(.failure(error))
            print(error.localizedDescription)
            return
        }
        
        // Unregister existing hotkey first
        unregisterHotkey()
        
        // Store current configuration
        currentKeyCode = keyCode
        currentModifiers = modifiers
        
        // Create hotkey ID
        let hotkeyID = EventHotKeyID(signature: fourCharCode("AKCY"), id: 1)
        
        // Register the hotkey
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        // Handle registration result
        if status == noErr {
            isHotkeyRegistered = true
            registrationStatusCallback?(.success(()))
            print("Hotkey registered successfully: \(keyCode.displayName) with modifiers \(GlobalHotkeyManager.displayStringFor(modifiers: modifiers))")
        } else {
            isHotkeyRegistered = false
            let error = HotkeyError.registrationFailed(status)
            registrationStatusCallback?(.failure(error))
            print(error.localizedDescription)
        }
    }
    
    /// Setup Carbon event handler for hotkey detection
    private func setupCarbonEventHandler() throws {
        var eventTypes = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleCarbonEvent(theEvent)
            },
            1,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        
        if status != noErr {
            throw HotkeyError.eventHandlerSetupFailed(status)
        }
    }
    
    /// Handle Carbon hotkey events
    private func handleCarbonEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }
        
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            OSType(kEventParamDirectObject),
            OSType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        if status == noErr && hotkeyID.signature == fourCharCode("AKCY") {
            // Execute callback on main thread synchronously to ensure immediate response
            if Thread.isMainThread {
                self.hotkeyPressedCallback?()
            } else {
                DispatchQueue.main.sync {
                    self.hotkeyPressedCallback?()
                }
            }
            return noErr
        }
        
        return OSStatus(eventNotHandledErr)
    }
}

// MARK: - Helper Functions

/// Create a four-character code from string
private func fourCharCode(_ string: String) -> OSType {
    let chars = Array(string.prefix(4).padding(toLength: 4, withPad: " ", startingAt: 0))
    return chars.reduce(0) { result, char in
        (result << 8) + OSType(char.asciiValue ?? 32)
    }
}

// MARK: - Helper Extensions

extension GlobalHotkeyManager {
    
    /// Get display string for modifier combination
    static func displayStringFor(modifiers: UInt32) -> String {
        var description = ""
        
        if modifiers & UInt32(controlKey) != 0 {
            description += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            description += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            description += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            description += "⌘"
        }
        
        return description
    }
}

// No need for this extension as CGKeyCode+Extensions.swift already defines displayName
