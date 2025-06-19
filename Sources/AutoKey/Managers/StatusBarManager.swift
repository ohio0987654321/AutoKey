//
//  StatusBarManager.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa

/// Manages the status bar menu and icon for the application
class StatusBarManager {
    
    // MARK: - Properties
    
    static let shared = StatusBarManager()
    
    private let settings = AppSettings.shared
    private let keySimulator = KeyPressSimulator.shared
    
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var statusToggleMenuItem: NSMenuItem?
    private var statusKeyMenuItem: NSMenuItem?
    private var statusSpeedMenuItem: NSMenuItem?
    
    // Callback for menu actions
    var toggleSimulationCallback: (() -> Void)?
    var showMainWindowCallback: (() -> Void)?
    var quitApplicationCallback: (() -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Public Methods
    
    /// Set up the status bar menu
    func setupStatusBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set initial icon
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "AutoKey")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true // Support dark mode
        }
        
        // Create status menu
        statusMenu = NSMenu()
        
        // Add app name item (non-interactive)
        let appNameItem = NSMenuItem(title: "AutoKey", action: nil, keyEquivalent: "")
        appNameItem.isEnabled = false
        appNameItem.attributedTitle = NSAttributedString(
            string: "AutoKey",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor
            ]
        )
        statusMenu?.addItem(appNameItem)
        
        // Add separator
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Add status items
        statusToggleMenuItem = NSMenuItem(
            title: "Start Auto-Clicking",
            action: #selector(toggleSimulationFromMenu),
            keyEquivalent: ""
        )
        statusToggleMenuItem?.target = self
        statusMenu?.addItem(statusToggleMenuItem!)
        
        // Add key info
        statusKeyMenuItem = NSMenuItem(title: "Target Key: Space", action: nil, keyEquivalent: "")
        statusKeyMenuItem?.isEnabled = false
        statusMenu?.addItem(statusKeyMenuItem!)
        
        // Add speed info
        statusSpeedMenuItem = NSMenuItem(title: "Speed: 1 clicks/sec", action: nil, keyEquivalent: "")
        statusSpeedMenuItem?.isEnabled = false
        statusMenu?.addItem(statusSpeedMenuItem!)
        
        // Add separator
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Add show main window item
        let showWindowItem = NSMenuItem(
            title: "Open Settings...",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        showWindowItem.target = self
        statusMenu?.addItem(showWindowItem)
        
        // Add quit item
        let quitItem = NSMenuItem(
            title: "Quit AutoKey",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        statusMenu?.addItem(quitItem)
        
        // Assign menu to status item
        statusItem?.menu = statusMenu
        
        // Update initial state
        updateStatusBarState()
        
        // Set up notification observers
        setupNotifications()
    }
    
    /// Update status bar appearance based on current state
    func updateStatusBarState() {
        let isActive = keySimulator.isActive
        
        // Update icon with more subtle native styling
        if let button = statusItem?.button {
            if isActive {
                button.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: "AutoKey Active")
                // Use controlAccentColor with reduced opacity for a more native look
                button.contentTintColor = NSColor.controlAccentColor.withAlphaComponent(0.85)
            } else {
                button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "AutoKey")
                // Use default tint color which adapts to system appearance
                button.contentTintColor = nil
            }
        }
        
        // Update toggle menu item
        statusToggleMenuItem?.title = isActive ? "Stop Auto-Clicking" : "Start Auto-Clicking"
        
        // Update key info
        statusKeyMenuItem?.title = "Target Key: \(settings.targetKeyDescription)"
        
        // Update speed info
        statusSpeedMenuItem?.title = "Speed: \(Int(settings.clicksPerSecond)) clicks/sec"
    }
    
    /// Remove the status item from the status bar
    func removeStatusItem() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        // Listen for simulation state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSimulationStateChanged),
            name: .simulationStateChanged,
            object: nil
        )
        
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )
    }
    
    @objc private func handleSimulationStateChanged() {
        updateStatusBarState()
    }
    
    @objc private func handleSettingsChanged() {
        updateStatusBarState()
    }
    
    @objc private func toggleSimulationFromMenu() {
        toggleSimulationCallback?()
    }
    
    @objc private func showMainWindow() {
        showMainWindowCallback?()
    }
    
    @objc private func quitApplication() {
        quitApplicationCallback?()
    }
}
