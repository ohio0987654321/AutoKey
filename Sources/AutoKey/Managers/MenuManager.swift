//
//  MenuManager.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa

/// Manages the application's main menu bar
class MenuManager {
    
    // MARK: - Properties
    
    static let shared = MenuManager()
    
    // Callback for menu actions
    var toggleSimulationCallback: (() -> Void)?
    var showMainWindowCallback: (() -> Void)?
    var showAboutCallback: (() -> Void)?
    var quitApplicationCallback: (() -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Public Methods
    
    /// Set up the main menu bar for the application
    func setupMainMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Add About menu item
        let aboutMenuItem = NSMenuItem(title: "About AutoKey", action: #selector(showAbout), keyEquivalent: "")
        aboutMenuItem.target = self
        appMenu.addItem(aboutMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Add Hide menu item
        let hideMenuItem = NSMenuItem(title: "Hide AutoKey", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hideMenuItem)
        
        // Add Hide Others menu item
        let hideOthersMenuItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersMenuItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersMenuItem)
        
        // Add Show All menu item
        let showAllMenuItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Add Quit menu item
        let quitMenuItem = NSMenuItem(title: "Quit AutoKey", action: #selector(quitApplication), keyEquivalent: "q")
        quitMenuItem.target = self
        appMenu.addItem(quitMenuItem)
        
        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        // Add Show Main Window menu item
        let showWindowMenuItem = NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: "1")
        showWindowMenuItem.target = self
        windowMenu.addItem(showWindowMenuItem)
        
        windowMenu.addItem(NSMenuItem.separator())
        
        // Add standard window menu items
        let minimizeMenuItem = NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(minimizeMenuItem)
        
        let zoomMenuItem = NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(zoomMenuItem)
        
        // Set the window menu for the application
        NSApp.windowsMenu = windowMenu
        
        // Control Menu
        let controlMenuItem = NSMenuItem()
        let controlMenu = NSMenu(title: "Control")
        controlMenuItem.submenu = controlMenu
        mainMenu.addItem(controlMenuItem)
        
        // Add Toggle Simulation menu item
        let toggleMenuItem = NSMenuItem(title: "Toggle Auto-Clicking", action: #selector(toggleSimulation), keyEquivalent: "t")
        toggleMenuItem.target = self
        controlMenu.addItem(toggleMenuItem)
    }
    
    // MARK: - Menu Actions
    
    @objc private func showAbout() {
        showAboutCallback?()
    }
    
    @objc private func showMainWindow() {
        showMainWindowCallback?()
    }
    
    @objc private func toggleSimulation() {
        toggleSimulationCallback?()
    }
    
    @objc private func quitApplication() {
        quitApplicationCallback?()
    }
}
