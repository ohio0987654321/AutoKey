//
//  AppDelegate.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private let settings = AppSettings.shared
    private let hotkeyManager = GlobalHotkeyManager.shared
    private let keySimulator = KeyPressSimulator.shared
    private let permissionManager = PermissionManager.shared
    
    // Managers
    private let windowManager = WindowManager.shared
    private let statusBarManager = StatusBarManager.shared
    private let menuManager = MenuManager.shared
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set app activation policy
        NSApp.setActivationPolicy(.regular)
        
        // Load saved settings
        settings.loadSettings()
        
        // Set up main menu first
        setupMainMenu()
        
        // Set up hotkey callback
        setupHotkeyCallback()
        
        // Check permissions and set up hotkeys if available
        setupInitialPermissions()
        
        // Set up status bar menu
        setupStatusBar()
        
        // Create main window programmatically - moved after other setup
        windowManager.createMainWindow()
        
        // Activate the app and bring to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Stop any active simulation
        keySimulator.stopSimulation()
        
        // Unregister hotkeys
        hotkeyManager.unregisterHotkey()
        
        // Save settings
        settings.saveSettings()
        
        // Remove status item
        statusBarManager.removeStatusItem()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Allow app to continue running even when main window is closed
        // This enables background hotkey functionality
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show main window when app icon is clicked in dock
        if !flag {
            windowManager.showMainWindow()
        }
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Setup Methods
    
    /// Set up the main menu bar for the application
    private func setupMainMenu() {
        menuManager.setupMainMenu()
        
        // Set up callbacks
        menuManager.toggleSimulationCallback = { [weak self] in
            self?.toggleSimulation()
        }
        
        menuManager.showMainWindowCallback = { [weak self] in
            self?.windowManager.showMainWindow()
        }
        
        menuManager.showAboutCallback = { [weak self] in
            self?.showAbout()
        }
        
        menuManager.quitApplicationCallback = {
            NSApp.terminate(nil)
        }
    }
    
    /// Set up the status bar menu
    private func setupStatusBar() {
        statusBarManager.setupStatusBar()
        
        // Set up callbacks
        statusBarManager.toggleSimulationCallback = { [weak self] in
            self?.toggleSimulation()
        }
        
        statusBarManager.showMainWindowCallback = { [weak self] in
            self?.windowManager.showMainWindow()
        }
        
        statusBarManager.quitApplicationCallback = {
            NSApp.terminate(nil)
        }
    }
    
    /// Set up the hotkey callback to toggle simulation
    private func setupHotkeyCallback() {
        hotkeyManager.hotkeyPressedCallback = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleSimulation()
            }
        }
    }
    
    /// Set up initial permissions and hotkeys
    private func setupInitialPermissions() {
        // Check if we have permissions
        if permissionManager.hasAllRequiredPermissions {
            // Set up hotkeys with current settings
            hotkeyManager.registerHotkey(
                keyCode: settings.toggleHotkeyKeyCode,
                modifiers: settings.toggleHotkeyModifiers
            )
        } else {
            // Request permissions
            permissionManager.showPermissionAlertIfNeeded { [weak self] granted in
                if granted {
                    self?.hotkeyManager.updateHotkey()
                }
            }
        }
    }
    
    // MARK: - Action Methods
    
    /// Handle hotkey press to toggle simulation
    private func toggleSimulation() {
        // Check permissions before toggling
        guard permissionManager.hasAllRequiredPermissions else {
            showPermissionAlert()
            return
        }
        
        // Toggle the simulation
        keySimulator.toggleSimulation()
        
        // Update UI if main window is visible
        NotificationCenter.default.post(name: .simulationStateChanged, object: nil)
        
        // Update status bar
        statusBarManager.updateStatusBarState()
    }
    
    /// Show permission alert when needed
    private func showPermissionAlert() {
        permissionManager.showPermissionAlertIfNeeded { [weak self] granted in
            if granted {
                self?.hotkeyManager.updateHotkey()
            }
        }
    }
    
    /// Show the about dialog
    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AutoKey"
        alert.informativeText = "A simple auto-clicking application for macOS.\n\nVersion 1.0\n\nThis app simulates keyboard input for automation purposes."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
