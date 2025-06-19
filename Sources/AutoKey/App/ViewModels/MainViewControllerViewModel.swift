//
//  MainViewControllerViewModel.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Foundation
import Combine
import Carbon
import AppKit

/// ViewModel for the MainViewController, handling business logic and state management
class MainViewControllerViewModel {
    
    // MARK: - Properties
    
    private let settings = AppSettings.shared
    private let hotkeyManager = GlobalHotkeyManager.shared
    private let keySimulator = KeyPressSimulator.shared
    private let permissionManager = PermissionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    /// Current state of the auto-clicking functionality
    var isClickingActive: Bool {
        return keySimulator.isActive
    }
    
    /// Current target key description
    var targetKeyDescription: String {
        return settings.targetKeyDescription
    }
    
    /// Current clicks per second value
    var clicksPerSecond: Double {
        return settings.clicksPerSecond
    }
    
    /// Current toggle hotkey description
    var toggleHotkeyDescription: String {
        return settings.toggleHotkeyDescription
    }
    
    // MARK: - Callbacks
    
    /// Callback for when the simulation state changes
    var onSimulationStateChanged: ((Bool) -> Void)?
    
    /// Callback for when settings are updated
    var onSettingsUpdated: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        setupNotifications()
        setupHotkeyCallback()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Observe settings changes
        settings.$targetKeyCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onSettingsUpdated?()
            }
            .store(in: &cancellables)
        
        settings.$clicksPerSecond
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onSettingsUpdated?()
                // Update simulation timing when CPS changes
                self?.keySimulator.updateSimulationSettings()
            }
            .store(in: &cancellables)
        
        settings.$toggleHotkeyKeyCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onSettingsUpdated?()
            }
            .store(in: &cancellables)
        
        // Use NotificationCenter to observe changes to properties with property wrappers
        NotificationCenter.default.publisher(for: .settingsChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onSettingsUpdated?()
            }
            .store(in: &cancellables)
        
        settings.$isClickingActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.onSimulationStateChanged?(isActive)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSimulationStateChanged),
            name: .simulationStateChanged,
            object: nil
        )
    }
    
    private func setupHotkeyCallback() {
        // Setup hotkey callback
        hotkeyManager.hotkeyPressedCallback = { [weak self] in
            guard let self = self else { return }
            
            // Ensure we're on the main thread
            if Thread.isMainThread {
                self.toggleClickingViaHotkey()
            } else {
                DispatchQueue.main.sync {
                    self.toggleClickingViaHotkey()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Update the target key
    func updateTargetKey(keyCode: CGKeyCode?, modifiers: UInt32) {
        settings.targetKeyCode = keyCode
        settings.targetKeyModifiers = modifiers
        settings.saveSettings()
    }
    
    /// Update the clicks per second value
    func updateClicksPerSecond(_ value: Double) {
        settings.setClicksPerSecond(value)
        settings.saveSettings()
    }
    
    /// Update the toggle hotkey
    func updateToggleHotkey(keyCode: CGKeyCode?, modifiers: UInt32) {
        settings.toggleHotkeyKeyCode = keyCode
        settings.toggleHotkeyModifiers = modifiers
        settings.saveSettings()
        updateHotkey()
    }
    
    /// Toggle the auto-clicking functionality
    func toggleClicking() {
        // Check permissions before starting
        guard permissionManager.hasAllRequiredPermissions else {
            showPermissionAlert()
            return
        }
        
        // Check if we have a target key set
        if settings.targetKeyCode == nil {
            showAlert(title: "No Target Key Set", message: "Please set a target key before starting.")
            return
        }
        
        // Toggle simulation
        keySimulator.toggleSimulation()
    }
    
    /// Check if the app has all required permissions
    var hasAllRequiredPermissions: Bool {
        return permissionManager.hasAllRequiredPermissions
    }
    
    /// Request all required permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        permissionManager.showPermissionAlertIfNeeded { [weak self] granted in
            if granted {
                self?.hotkeyManager.updateHotkey()
            }
            completion(granted)
        }
    }
    
    // MARK: - Private Methods
    
    /// Toggle clicking via hotkey
    private func toggleClickingViaHotkey() {
        // Check permissions
        guard permissionManager.hasAllRequiredPermissions else {
            return
        }
        
        // Check if we have a target key set
        guard settings.targetKeyCode != nil else {
            return
        }
        
        // Toggle simulation
        keySimulator.toggleSimulation()
    }
    
    /// Update the registered hotkey
    private func updateHotkey() {
        hotkeyManager.registerHotkey(
            keyCode: settings.toggleHotkeyKeyCode,
            modifiers: settings.toggleHotkeyModifiers
        )
    }
    
    /// Show permission alert
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Autokey needs accessibility permissions to simulate keyboard input. Please grant permission in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open accessibility settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// Show a generic alert
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    /// Handle simulation state changed notification
    @objc private func handleSimulationStateChanged() {
        DispatchQueue.main.async {
            self.onSimulationStateChanged?(self.isClickingActive)
        }
    }
}
