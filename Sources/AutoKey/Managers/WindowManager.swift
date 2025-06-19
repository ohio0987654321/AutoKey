//
//  WindowManager.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa

/// Manages the application's main window
class WindowManager: NSObject, NSWindowDelegate {
    
    // MARK: - Properties
    
    static let shared = WindowManager()
    
    private var mainWindow: NSWindow?
    private var mainViewController: MainViewController?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        // Private initializer for singleton
    }
    
    // MARK: - Public Methods
    
    /// Create and show the main window
    func createMainWindow() {
        // Create the main view controller
        mainViewController = MainViewController()
        
        // Create the main window with optimal fixed size for the UI
        let windowRect = NSRect(x: 0, y: 0, width: 330, height: 300)
        mainWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        guard let window = mainWindow else {
            showCriticalError("Failed to create main window")
            return
        }
        
        // Configure window properties
        window.title = "AutoKey"
        window.isReleasedWhenClosed = false // Important: Keep window in memory
        window.delegate = self
        window.level = .normal
        window.hasShadow = true
        window.isOpaque = true

        // Set content view controller - this must happen before showing
        window.contentViewController = mainViewController
        
        // Center window on screen
        window.center()
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        
        // Ensure app is active and window is visible
        NSApp.activate(ignoringOtherApps: true)
        
        print("Main window created and should be visible: \(window.isVisible)")
    }
    
    /// Show the main window, creating it if necessary
    func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Recreate the main window if it doesn't exist
            createMainWindow()
        }
    }
    
    /// Check if the main window exists
    var hasMainWindow: Bool {
        return mainWindow != nil
    }
    
    // MARK: - Private Methods
    
    /// Attempt to recover window visibility if it fails to show
    private func recoverWindowVisibility() {
        guard let window = mainWindow else { return }
        
        // Try different approaches to make the window visible
        window.orderOut(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            if !window.isVisible {
                self.showCriticalError("Unable to display the main window. Please try restarting the application.")
            }
        }
    }
    
    /// Show a critical error alert
    private func showCriticalError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "AutoKey Error"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Save settings when window closes
        AppSettings.shared.saveSettings()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Not needed for now
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Not needed for now
    }
}
