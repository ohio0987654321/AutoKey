//
//  ConfigurationSectionView.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa
import Carbon

/// Protocol for ConfigurationSectionView delegate
protocol ConfigurationSectionViewDelegate: AnyObject {
    func targetKeyChanged(_ keyCode: CGKeyCode?, modifiers: UInt32)
    func clicksPerSecondChanged(_ value: Double)
    func toggleHotkeyChanged(_ keyCode: CGKeyCode?, modifiers: UInt32)
    func textFieldDidEndEditing(_ textField: NSTextField)
}

/// A view that encapsulates the configuration section of the main UI
class ConfigurationSectionView: NSView, NSTextFieldDelegate {
    
    // MARK: - Properties
    
    weak var delegate: ConfigurationSectionViewDelegate?
    
    /// Whether the controls are enabled for user interaction
    private var controlsEnabled: Bool = true
    
    // MARK: - UI Elements
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Configuration")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    // Target key controls
    private lazy var targetKeyLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Target Key:")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }()
    
    private lazy var targetKeyIcon: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Target Key")
        imageView.contentTintColor = .secondaryLabelColor
        imageView.symbolConfiguration = .init(pointSize: 14, weight: .regular)
        return imageView
    }()
    
    private lazy var targetKeyRecorder: KeyRecorder = {
        let recorder = KeyRecorder()
        recorder.translatesAutoresizingMaskIntoConstraints = false
        recorder.target = self
        recorder.action = #selector(targetKeyChanged(_:))
        return recorder
    }()
    
    // Clicks per second controls
    private lazy var clicksPerSecondLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Clicks/Sec:")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }()
    
    private lazy var clicksPerSecondIcon: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(systemSymbolName: "speedometer", accessibilityDescription: "Speed")
        imageView.contentTintColor = .secondaryLabelColor
        imageView.symbolConfiguration = .init(pointSize: 14, weight: .regular)
        return imageView
    }()
    
    private lazy var clicksPerSecondTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.formatter = createNumberFormatter()
        textField.delegate = self
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.alignment = .right // Right-align numeric input
        textField.target = self
        textField.action = #selector(textFieldValueChanged(_:))
        return textField
    }()

    // Hotkey controls
    private lazy var toggleHotkeyLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Toggle Hotkey:")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }()
    
    private lazy var toggleHotkeyIcon: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Hotkey")
        imageView.contentTintColor = .secondaryLabelColor
        imageView.symbolConfiguration = .init(pointSize: 14, weight: .regular)
        return imageView
    }()
    
    private lazy var shortcutRecorder: ShortcutRecorder = {
        let recorder = ShortcutRecorder()
        recorder.translatesAutoresizingMaskIntoConstraints = false
        recorder.target = self
        recorder.action = #selector(shortcutRecorderChanged(_:))
        return recorder
    }()
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 8
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(targetKeyIcon)
        addSubview(targetKeyLabel)
        addSubview(targetKeyRecorder)
        addSubview(clicksPerSecondIcon)
        addSubview(clicksPerSecondLabel)
        addSubview(clicksPerSecondTextField)
        addSubview(toggleHotkeyIcon)
        addSubview(toggleHotkeyLabel)
        addSubview(shortcutRecorder)
    }
    
    private func setupConstraints() {
        let standardSpacing: CGFloat = 16
        let tightSpacing: CGFloat = 8
        let iconSize: CGFloat = 16
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Target Key row
            targetKeyIcon.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: standardSpacing),
            targetKeyIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            targetKeyIcon.widthAnchor.constraint(equalToConstant: iconSize),
            targetKeyIcon.heightAnchor.constraint(equalToConstant: iconSize),
            
            targetKeyLabel.centerYAnchor.constraint(equalTo: targetKeyIcon.centerYAnchor),
            targetKeyLabel.leadingAnchor.constraint(equalTo: targetKeyIcon.trailingAnchor, constant: tightSpacing),
            
            targetKeyRecorder.centerYAnchor.constraint(equalTo: targetKeyLabel.centerYAnchor),
            targetKeyRecorder.leadingAnchor.constraint(equalTo: centerXAnchor, constant: -10),
            targetKeyRecorder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            targetKeyRecorder.heightAnchor.constraint(equalToConstant: 23),
            
            // Clicks Per Second row
            clicksPerSecondIcon.topAnchor.constraint(equalTo: targetKeyIcon.bottomAnchor, constant: standardSpacing),
            clicksPerSecondIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            clicksPerSecondIcon.widthAnchor.constraint(equalToConstant: iconSize),
            clicksPerSecondIcon.heightAnchor.constraint(equalToConstant: iconSize),
            
            clicksPerSecondLabel.centerYAnchor.constraint(equalTo: clicksPerSecondIcon.centerYAnchor),
            clicksPerSecondLabel.leadingAnchor.constraint(equalTo: clicksPerSecondIcon.trailingAnchor, constant: tightSpacing),
            
            clicksPerSecondTextField.centerYAnchor.constraint(equalTo: clicksPerSecondLabel.centerYAnchor),
            clicksPerSecondTextField.leadingAnchor.constraint(equalTo: centerXAnchor, constant: -10),
            clicksPerSecondTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            clicksPerSecondTextField.heightAnchor.constraint(equalToConstant: 24),
            
            // Toggle Hotkey row
            toggleHotkeyIcon.topAnchor.constraint(equalTo: clicksPerSecondIcon.bottomAnchor, constant: standardSpacing),
            toggleHotkeyIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            toggleHotkeyIcon.widthAnchor.constraint(equalToConstant: iconSize),
            toggleHotkeyIcon.heightAnchor.constraint(equalToConstant: iconSize),
            
            toggleHotkeyLabel.centerYAnchor.constraint(equalTo: toggleHotkeyIcon.centerYAnchor),
            toggleHotkeyLabel.leadingAnchor.constraint(equalTo: toggleHotkeyIcon.trailingAnchor, constant: tightSpacing),
            
            shortcutRecorder.centerYAnchor.constraint(equalTo: toggleHotkeyLabel.centerYAnchor),
            shortcutRecorder.leadingAnchor.constraint(equalTo: centerXAnchor, constant: -10),
            shortcutRecorder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            shortcutRecorder.heightAnchor.constraint(equalToConstant: 23),
            
            // Bottom constraint
            shortcutRecorder.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    private func createNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 1.0
        formatter.maximum = 99.0 // Reduced from 999 to 99 to prevent performance issues
        formatter.maximumFractionDigits = 0
        formatter.allowsFloats = false
        return formatter
    }
    
    // MARK: - Public Methods
    
    /// Update the view with the current settings
    func updateWithSettings(targetKeyCode: CGKeyCode?, targetKeyModifiers: UInt32, clicksPerSecond: Double, toggleHotkeyKeyCode: CGKeyCode?, toggleHotkeyModifiers: UInt32) {
        // Update target key recorder
        targetKeyRecorder.setShortcut(keyCode: targetKeyCode, modifierFlags: targetKeyModifiers)
        
        // Update clicks per second controls
        clicksPerSecondTextField.stringValue = String(Int(clicksPerSecond))
        
        // Update shortcut recorder
        shortcutRecorder.setShortcut(keyCode: toggleHotkeyKeyCode, modifierFlags: toggleHotkeyModifiers)
    }
    
    /// Enable or disable all configuration controls
    /// - Parameter enabled: Whether the controls should be enabled
    func setControlsEnabled(_ enabled: Bool) {
        // Store the enabled state
        controlsEnabled = enabled
        
        // Update visual appearance and interaction state for all controls
        targetKeyRecorder.isEnabled = enabled
        clicksPerSecondTextField.isEnabled = enabled
        shortcutRecorder.isEnabled = enabled
        
        // Update alpha to provide visual feedback of disabled state
        let alpha: CGFloat = enabled ? 1.0 : 0.6
        
        targetKeyRecorder.alphaValue = alpha
        clicksPerSecondTextField.alphaValue = alpha
        shortcutRecorder.alphaValue = alpha
        
        // If disabled, remove focus from any text field
        if !enabled && window?.firstResponder == clicksPerSecondTextField {
            window?.makeFirstResponder(nil)
        }
    }
    
    // MARK: - Actions
    
    @objc private func targetKeyChanged(_ sender: KeyRecorder) {
        delegate?.targetKeyChanged(sender.keyCode, modifiers: sender.modifierFlags)
    }
    
    
    @objc private func textFieldValueChanged(_ sender: NSTextField) {
        commitTextFieldValue(sender)
    }
    
    @objc private func shortcutRecorderChanged(_ sender: ShortcutRecorder) {
        delegate?.toggleHotkeyChanged(sender.keyCode, modifiers: sender.modifierFlags)
    }
    
    // MARK: - NSTextFieldDelegate
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              textField == clicksPerSecondTextField else { return }
        
        // Remove focus from the text field to prevent auto key inputs targeting it
        window?.makeFirstResponder(nil)
        
        // Only process if controls are enabled
        if controlsEnabled {
            // Process the text field value
            commitTextFieldValue(textField)
            
            // Notify delegate
            delegate?.textFieldDidEndEditing(textField)
        }
    }
    
    /// Helper method to commit text field value changes
    private func commitTextFieldValue(_ textField: NSTextField) {
        guard textField == clicksPerSecondTextField else { return }
        
        guard let value = Double(textField.stringValue) else {
            // Reset to current value if invalid input
            textField.stringValue = "1"
            return
        }
        
        // Notify delegate
        delegate?.clicksPerSecondChanged(value)
    }
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        // Prevent editing if controls are disabled
        if control == clicksPerSecondTextField {
            return controlsEnabled
        }
        return true
    }
    
    func control(_ control: NSControl, isValidObject obj: Any?) -> Bool {
        guard control == clicksPerSecondTextField else { return true }
        
        if let string = obj as? String {
            // Allow empty string while typing
            if string.isEmpty { return true }
            
            // Only allow numeric characters
            let allowedCharacters = CharacterSet(charactersIn: "0123456789")
            if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                return false
            }
            
            // Check length and range
            if string.count > 2 { // Changed from 3 to 2 since max is now 99
                return false
            }
            
            // Validate the numeric range if we have a valid number
            if let value = Int(string), (value < 1 || value > 99) { // Changed from 999 to 99
                return false
            }
            
            return true
        }
        
        return false
    }
    
    func controlTextDidChange(_ obj: Notification) {
        // Skip processing if controls are disabled
        guard controlsEnabled,
              let textField = obj.object as? NSTextField,
              textField == clicksPerSecondTextField else { return }
        
        // Get the current string
        let string = textField.stringValue
        
        // Only allow numeric characters
        let filtered = string.filter { "0123456789".contains($0) }
        
        // If the string was changed, update the text field
        if string != filtered {
            textField.stringValue = filtered
        }
        
        // Immediately update the CPS value as the user types
        if !filtered.isEmpty, let value = Double(filtered) {
            // Only update if the value is valid
            if value >= 1 && value <= 99 {
                // Notify delegate
                delegate?.clicksPerSecondChanged(value)
            }
        }
    }
}
