//
//  ShortcutRecorder.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa
import Carbon

/// A custom control that mimics macOS system preferences shortcut recorder
class ShortcutRecorder: NSControl {
    
    // MARK: - Properties
    
    private var isUpdatingProgrammatically = false
    
    /// Whether the control is enabled for user interaction
    override var isEnabled: Bool {
        didSet {
            // If disabled while recording, stop recording
            if !isEnabled && isRecording {
                stopRecording()
            }
            updateDisplay()
        }
    }
    
    var keyCode: CGKeyCode? = nil {
        didSet {
            updateDisplay()
            // Only send action if this is a user interaction, not programmatic update
            if !isUpdatingProgrammatically {
                sendAction(action, to: target)
            }
        }
    }
    
    var modifierFlags: UInt32 = 0 {
        didSet {
            updateDisplay()
            // Only send action if this is a user interaction, not programmatic update
            if !isUpdatingProgrammatically {
                sendAction(action, to: target)
            }
        }
    }
    
    private var isRecording = false {
        didSet {
            updateDisplay()
        }
    }
    
    private var eventMonitor: Any?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 4 // More native macOS corner radius
        layer?.borderWidth = 0.5 // Thinner border for a more native look
        layer?.borderColor = NSColor.separatorColor.cgColor
        updateDisplay()
    }
    
    // MARK: - Display
    
    private func updateDisplay() {
        needsDisplay = true
        
        if !isEnabled {
            // Disabled appearance
            layer?.backgroundColor = NSColor.disabledControlTextColor.withAlphaComponent(0.05).cgColor
        } else if isRecording {
            // More subtle highlight when recording
            layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        } else {
            // More native appearance when not recording
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.clear.cgColor // Clear background for better blending
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw a subtle background that matches native macOS controls
        if !isRecording {
            NSColor.controlBackgroundColor.withAlphaComponent(0.5).setFill()
            let backgroundPath = NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4)
            backgroundPath.fill()
        }
        
        let text: String
        let textColor: NSColor
        
        if !isEnabled {
            // Use the current text but with disabled color
            text = shortcutDisplayString
            textColor = .disabledControlTextColor
        } else if isRecording {
            text = "Press shortcut"
            textColor = .secondaryLabelColor
        } else {
            text = shortcutDisplayString
            textColor = .labelColor
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    private var shortcutDisplayString: String {
        guard let keyCode = keyCode else {
            return "Click to set"
        }
        
        var result = ""
        
        if modifierFlags & UInt32(controlKey) != 0 {
            result += "⌃"
        }
        if modifierFlags & UInt32(optionKey) != 0 {
            result += "⌥"
        }
        if modifierFlags & UInt32(shiftKey) != 0 {
            result += "⇧"
        }
        if modifierFlags & UInt32(cmdKey) != 0 {
            result += "⌘"
        }
        
        result += keyCode.displayName
        
        return result
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        // Ignore mouse events when disabled
        guard isEnabled else { return }
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Recording
    
    private func startRecording() {
        isRecording = true
        
        // Capture key events globally
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }
        
        // Also add global monitor for when window loses focus during recording
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }
    
    private func stopRecording() {
        isRecording = false
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        if event.type == .keyDown {
            // Don't allow certain keys
            let keyCode = CGKeyCode(event.keyCode)
            let modifiers = carbonModifiersFrom(event.modifierFlags)
            
            // Require at least one modifier key
            if isValidShortcutKey(keyCode) && hasAtLeastOneModifier(modifiers) {
                self.keyCode = keyCode
                self.modifierFlags = modifiers
                stopRecording()
            } else if isValidShortcutKey(keyCode) && !hasAtLeastOneModifier(modifiers) {
                // Flash the control to indicate invalid combination (no modifiers)
                flashInvalidCombination()
            }
        }
    }
    
    /// Flash the control to indicate an invalid key combination
    private func flashInvalidCombination() {
        let originalBorderColor = layer?.borderColor
        let originalBackgroundColor = layer?.backgroundColor
        
        // Flash red to indicate error
        layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.8).cgColor
        layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.1).cgColor
        
        // Restore original colors after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.layer?.borderColor = originalBorderColor
            self?.layer?.backgroundColor = originalBackgroundColor
        }
    }
    
    /// Check if at least one modifier key is pressed
    private func hasAtLeastOneModifier(_ modifiers: UInt32) -> Bool {
        let requiredModifiers: [UInt32] = [
            UInt32(cmdKey),
            UInt32(optionKey),
            UInt32(controlKey),
            UInt32(shiftKey)
        ]
        
        return requiredModifiers.contains { modifiers & $0 != 0 }
    }
    
    private func isValidShortcutKey(_ keyCode: CGKeyCode) -> Bool {
        // Don't allow modifier keys alone
        let modifierKeyCodes: [CGKeyCode] = [
            CGKeyCode(kVK_Shift), CGKeyCode(kVK_RightShift),
            CGKeyCode(kVK_Control), CGKeyCode(kVK_RightControl),
            CGKeyCode(kVK_Option), CGKeyCode(kVK_RightOption),
            CGKeyCode(kVK_Command), CGKeyCode(kVK_RightCommand),
            CGKeyCode(kVK_CapsLock), CGKeyCode(kVK_Function)
        ]
        
        return !modifierKeyCodes.contains(keyCode)
    }
    
    private func carbonModifiersFrom(_ modifierFlags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        
        if modifierFlags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifierFlags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifierFlags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifierFlags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        
        return carbonModifiers
    }
    
    // MARK: - Programmatic Updates
    
    /// Set keyCode programmatically without triggering action
    func setKeyCode(_ keyCode: CGKeyCode?) {
        isUpdatingProgrammatically = true
        self.keyCode = keyCode
        isUpdatingProgrammatically = false
    }
    
    /// Set modifierFlags programmatically without triggering action
    func setModifierFlags(_ modifierFlags: UInt32) {
        isUpdatingProgrammatically = true
        self.modifierFlags = modifierFlags
        isUpdatingProgrammatically = false
    }
    
    /// Set both keyCode and modifierFlags programmatically without triggering action
    func setShortcut(keyCode: CGKeyCode?, modifierFlags: UInt32) {
        isUpdatingProgrammatically = true
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        isUpdatingProgrammatically = false
    }
    
    // MARK: - Control Protocol
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: -1, height: 23)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}
