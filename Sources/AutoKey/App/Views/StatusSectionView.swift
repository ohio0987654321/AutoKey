//
//  StatusSectionView.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa

/// Protocol for StatusSectionView delegate
protocol StatusSectionViewDelegate: AnyObject {
    func toggleButtonClicked(_ sender: NSButton)
}

/// A view that encapsulates the status section of the main UI
class StatusSectionView: NSView {
    
    // MARK: - Properties
    
    weak var delegate: StatusSectionViewDelegate?
    
    // MARK: - UI Elements
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Status")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var statusIndicator: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.layer?.backgroundColor = NSColor.systemGray.cgColor
        return view
    }()
    
    private lazy var statusLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Stopped")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        return label
    }()
    
    private lazy var statusDetailsLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Press the button or use the hotkey to start")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byWordWrapping
        label.usesSingleLineMode = false
        label.preferredMaxLayoutWidth = 280
        return label
    }()
    
    // Toggle button
    private lazy var toggleButton: NSButton = {
        let button = NSButton(title: "Start", target: self, action: #selector(toggleButtonClicked(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        button.keyEquivalent = "\r" // Return key
        button.wantsLayer = true
        return button
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
        addSubview(statusIndicator)
        addSubview(statusLabel)
        addSubview(statusDetailsLabel)
        addSubview(toggleButton)
    }
    
    private func setupConstraints() {
        let standardSpacing: CGFloat = 16
        let tightSpacing: CGFloat = 8
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Status indicator
            statusIndicator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: standardSpacing),
            statusIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            // Status label
            statusLabel.centerYAnchor.constraint(equalTo: statusIndicator.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: tightSpacing),
            
            // Toggle button
            toggleButton.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            toggleButton.leadingAnchor.constraint(equalTo: centerXAnchor, constant: -10),
            toggleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            toggleButton.heightAnchor.constraint(equalToConstant: 22),
            
            // Status details
            statusDetailsLabel.topAnchor.constraint(equalTo: statusIndicator.bottomAnchor, constant: tightSpacing),
            statusDetailsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusDetailsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statusDetailsLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Public Methods
    
    /// Update the status display
    func updateStatus(isActive: Bool, targetKeyDescription: String, clicksPerSecond: Double) {
        // Update status indicator color with more subtle native colors
        let color: NSColor = isActive ? 
            NSColor.controlAccentColor.withAlphaComponent(0.7) : 
            NSColor.tertiaryLabelColor.withAlphaComponent(0.5)
        statusIndicator.layer?.backgroundColor = color.cgColor
        
        // Update status text
        statusLabel.stringValue = isActive ? "Active" : "Stopped"
        
        // Update details text
        if isActive {
            // Ensure we're using the correct clicks per second value
            let cps = Int(clicksPerSecond)
            statusDetailsLabel.stringValue = "Pressing '\(targetKeyDescription)' at \(cps) clicks per second"
        } else {
            statusDetailsLabel.stringValue = "Press the button or use the hotkey to start"
        }
        
        // Update button appearance
        toggleButton.title = isActive ? "Stop" : "Start"
        toggleButton.bezelColor = NSColor.controlColor
    }
    
    // MARK: - Actions
    
    @objc private func toggleButtonClicked(_ sender: NSButton) {
        delegate?.toggleButtonClicked(sender)
    }
}
