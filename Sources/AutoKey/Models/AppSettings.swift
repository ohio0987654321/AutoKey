//
//  AppSettings.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation
import Combine
import Carbon
import AppKit

/// Property wrapper for UserDefaults-backed properties
@propertyWrapper
struct UserDefaultsBacked<T> {
    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults
    private let transformer: ((T) -> T)?
    
    init(key: String, defaultValue: T, userDefaults: UserDefaults = .standard, transformer: ((T) -> T)? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
        self.transformer = transformer
    }
    
    var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            let valueToStore = transformer?(newValue) ?? newValue
            userDefaults.set(valueToStore, forKey: key)
        }
    }
}

/// Property wrapper for optional CGKeyCode stored in UserDefaults
@propertyWrapper
struct OptionalKeyCodeUserDefault {
    private let key: String
    private let userDefaults: UserDefaults
    
    init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    var wrappedValue: CGKeyCode? {
        get {
            let value = userDefaults.integer(forKey: key)
            return value != 0 ? CGKeyCode(value) : nil
        }
        set {
            if let newValue = newValue {
                userDefaults.set(Int(newValue), forKey: key)
            } else {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}

/// Configuration settings for the AutoKey application
class AppSettings: ObservableObject {
    
    // MARK: - Static Properties
    
    static let shared = AppSettings()
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let targetKeyCode = "targetKeyCode"
        static let targetKeyModifiers = "targetKeyModifiers"
        static let clicksPerSecond = "clicksPerSecond"
        static let toggleHotkeyKeyCode = "toggleHotkeyKeyCode"
        static let toggleHotkeyModifiers = "toggleHotkeyModifiers"
    }
    
    // MARK: - Published Properties
    
    /// Target key to simulate
    @Published var targetKeyCode: CGKeyCode? = nil {
        didSet {
            if oldValue != targetKeyCode {
                saveTargetKey()
                notifySettingsChanged()
            }
        }
    }
    
    /// Modifier keys for the target key
    @UserDefaultsBacked(key: Keys.targetKeyModifiers, defaultValue: UInt32(0))
    var targetKeyModifiers: UInt32 {
        didSet {
            if oldValue != targetKeyModifiers {
                objectWillChange.send()
                notifySettingsChanged()
            }
        }
    }
    
    /// Clicks per second (1-99)
    @Published var clicksPerSecond: Double = 1.0 {
        didSet {
            if oldValue != clicksPerSecond {
                saveClicksPerSecond()
                notifySettingsChanged()
            }
        }
    }
    
    /// Hotkey to toggle simulation
    @Published var toggleHotkeyKeyCode: CGKeyCode? = nil {
        didSet {
            if oldValue != toggleHotkeyKeyCode {
                saveToggleHotkey()
                notifySettingsChanged()
            }
        }
    }
    
    /// Modifier keys for the toggle hotkey
    @UserDefaultsBacked(key: Keys.toggleHotkeyModifiers, defaultValue: UInt32(0))
    var toggleHotkeyModifiers: UInt32 {
        didSet {
            if oldValue != toggleHotkeyModifiers {
                objectWillChange.send()
                notifySettingsChanged()
            }
        }
    }
    
    /// Whether auto-clicking is currently active
    @Published var isClickingActive: Bool = false {
        didSet {
            if oldValue != isClickingActive {
                objectWillChange.send()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Load settings from UserDefaults
    func loadSettings() {
        // Load target key
        let targetKeyInt = userDefaults.integer(forKey: Keys.targetKeyCode)
        targetKeyCode = targetKeyInt != 0 ? CGKeyCode(targetKeyInt) : nil
        
        // Load clicks per second with validation
        let savedCPS = userDefaults.double(forKey: Keys.clicksPerSecond)
        clicksPerSecond = validateClicksPerSecond(savedCPS)
        
        // Load toggle hotkey
        let toggleKeyInt = userDefaults.integer(forKey: Keys.toggleHotkeyKeyCode)
        toggleHotkeyKeyCode = toggleKeyInt != 0 ? CGKeyCode(toggleKeyInt) : nil
        
        // Note: targetKeyModifiers and toggleHotkeyModifiers are loaded automatically
        // by the property wrapper
    }
    
    /// Save current settings to UserDefaults
    func saveSettings() {
        saveTargetKey()
        saveClicksPerSecond()
        saveToggleHotkey()
        
        // Notify observers that settings have changed
        notifySettingsChanged()
    }
    
    /// Set clicks per second with validation
    func setClicksPerSecond(_ value: Double) {
        clicksPerSecond = validateClicksPerSecond(value)
    }
    
    // MARK: - Computed Properties
    
    /// Get interval between clicks in seconds
    var clickInterval: TimeInterval {
        return 1.0 / clicksPerSecond
    }
    
    /// Get human-readable description of the toggle hotkey
    var toggleHotkeyDescription: String {
        guard let toggleHotkeyKeyCode = toggleHotkeyKeyCode else {
            return "Not Set"
        }
        
        return formatKeyWithModifiers(key: toggleHotkeyKeyCode, modifiers: toggleHotkeyModifiers)
    }
    
    /// Get human-readable description of the target key
    var targetKeyDescription: String {
        guard let targetKeyCode = targetKeyCode else {
            return "Not Set"
        }
        
        return formatKeyWithModifiers(key: targetKeyCode, modifiers: targetKeyModifiers)
    }
    
    // MARK: - Private Methods
    
    /// Save target key to UserDefaults
    private func saveTargetKey() {
        if let targetKey = targetKeyCode {
            userDefaults.set(Int(targetKey), forKey: Keys.targetKeyCode)
        } else {
            userDefaults.removeObject(forKey: Keys.targetKeyCode)
        }
    }
    
    /// Save clicks per second to UserDefaults
    private func saveClicksPerSecond() {
        userDefaults.set(clicksPerSecond, forKey: Keys.clicksPerSecond)
    }
    
    /// Save toggle hotkey to UserDefaults
    private func saveToggleHotkey() {
        if let toggleKey = toggleHotkeyKeyCode {
            userDefaults.set(Int(toggleKey), forKey: Keys.toggleHotkeyKeyCode)
        } else {
            userDefaults.removeObject(forKey: Keys.toggleHotkeyKeyCode)
        }
    }
    
    /// Validate clicks per second value
    private func validateClicksPerSecond(_ value: Double) -> Double {
        if value <= 0 {
            return 1.0
        } else if value > 99.0 {
            return 99.0
        } else {
            return value
        }
    }
    
    /// Format a key with modifiers as a human-readable string
    private func formatKeyWithModifiers(key: CGKeyCode, modifiers: UInt32) -> String {
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
        
        description += key.displayName
        
        return description
    }
    
    /// Notify observers that settings have changed
    private func notifySettingsChanged() {
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
        NotificationCenter.default.post(name: .simulationSettingsUpdated, object: nil)
    }
}
