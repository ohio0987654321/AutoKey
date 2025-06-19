//
//  MainViewController.swift
//  AutoKey
//
//  Created by AutoKey on 6/18/25.
//

import Cocoa
import Combine
import Carbon
import Foundation

class MainViewController: NSViewController {
    
    // MARK: - UI Elements
    
    // Background blur view
    private lazy var backgroundView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.material = .underPageBackground
        view.state = .active
        view.blendingMode = .withinWindow 
        return view
    }()

    // Separator view between configuration and status sections
    private lazy var separatorView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.borderWidth = 0.5
        view.layer?.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    // Configuration section
    private lazy var configurationSectionView: ConfigurationSectionView = {
        let view = ConfigurationSectionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.wantsLayer = false
        return view
    }()
    
    // Status section
    private lazy var statusSectionView: StatusSectionView = {
        let view = StatusSectionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = false
        return view
    }()
    
    
    // MARK: - Properties
    
    private let viewModel = MainViewControllerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        // Create view with fixed frame optimized for our UI
        let initialFrame = NSRect(x: 0, y: 0, width: 330, height: 300)
        self.view = NSView(frame: initialFrame)
        
        // Configure view properties
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.clear.cgColor // Make the view transparent
        
        setupUI()
        setupConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        updateUIFromViewModel()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        // Save settings when view disappears
        AppSettings.shared.saveSettings()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // Configure main view to respect system appearance
        view.appearance = nil
        
        // Add background blur view first (so it's behind everything else)
        view.addSubview(backgroundView)
        
        // Add section views
        view.addSubview(configurationSectionView)
        view.addSubview(separatorView)
        view.addSubview(statusSectionView)
        
        // Set up delegates
        statusSectionView.delegate = self
        
        // Update UI with current state
        updateStatusDisplay(isActive: viewModel.isClickingActive)
    }
    
    private func setupConstraints() {
        let edgeInset: CGFloat = 20
        let sectionSpacing: CGFloat = 20
        
        NSLayoutConstraint.activate([
            // Background view fills the entire window
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Configuration section
            configurationSectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: edgeInset),
            configurationSectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeInset),
            configurationSectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -edgeInset),
            
            // Separator view
            separatorView.topAnchor.constraint(equalTo: configurationSectionView.bottomAnchor, constant: sectionSpacing / 2),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Status section
            statusSectionView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: sectionSpacing / 2),
            statusSectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeInset),
            statusSectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -edgeInset),
            statusSectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -edgeInset)
        ])
    }
    
    private func setupCallbacks() {
        // Set up callback for simulation state changes
        viewModel.onSimulationStateChanged = { [weak self] isActive in
            guard let self = self else { return }
            self.updateStatusDisplay(isActive: isActive)
        }
        
        // Set up callback for settings updates
        viewModel.onSettingsUpdated = { [weak self] in
            guard let self = self else { return }
            self.updateUIFromViewModel()
        }
    }
    
    private func updateUIFromViewModel() {
        // Update configuration section
        let settings = AppSettings.shared
        configurationSectionView.updateWithSettings(
            targetKeyCode: settings.targetKeyCode,
            targetKeyModifiers: settings.targetKeyModifiers,
            clicksPerSecond: settings.clicksPerSecond,
            toggleHotkeyKeyCode: settings.toggleHotkeyKeyCode,
            toggleHotkeyModifiers: settings.toggleHotkeyModifiers
        )
        
        // Update status section
        updateStatusDisplay(isActive: viewModel.isClickingActive)
    }
    
    // MARK: - UI Update Methods
    
    private func updateStatusDisplay(isActive: Bool) {
        // Update status section
        statusSectionView.updateStatus(
            isActive: isActive,
            targetKeyDescription: viewModel.targetKeyDescription,
            clicksPerSecond: viewModel.clicksPerSecond
        )
        
        // Disable configuration controls when auto key is active
        configurationSectionView.setControlsEnabled(!isActive)
    }
    
    // MARK: - Actions
    
    @objc private func toggleClicking(_ sender: NSButton) {
        // CRITICAL: Remove focus from any text field to prevent key inputs going there
        view.window?.makeFirstResponder(nil)
        
        // Force a small delay to ensure focus is completely cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            // Toggle clicking via view model
            self.viewModel.toggleClicking()
        }
    }
}

// MARK: - ConfigurationSectionViewDelegate

extension MainViewController: ConfigurationSectionViewDelegate {
    
    func targetKeyChanged(_ keyCode: CGKeyCode?, modifiers: UInt32) {
        viewModel.updateTargetKey(keyCode: keyCode, modifiers: modifiers)
        updateStatusDisplay(isActive: viewModel.isClickingActive)
    }
    
    func clicksPerSecondChanged(_ value: Double) {
        viewModel.updateClicksPerSecond(value)
        updateStatusDisplay(isActive: viewModel.isClickingActive)
    }
    
    func toggleHotkeyChanged(_ keyCode: CGKeyCode?, modifiers: UInt32) {
        viewModel.updateToggleHotkey(keyCode: keyCode, modifiers: modifiers)
    }
    
    func textFieldDidEndEditing(_ textField: NSTextField) {
        // Remove focus from the text field to prevent auto key inputs targeting it
        view.window?.makeFirstResponder(nil)
    }
}

// MARK: - StatusSectionViewDelegate

extension MainViewController: StatusSectionViewDelegate {
    
    func toggleButtonClicked(_ sender: NSButton) {
        // CRITICAL: Remove focus from any text field to prevent key inputs going there
        view.window?.makeFirstResponder(nil)
        
        // Force a small delay to ensure focus is completely cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            // Toggle clicking via view model
            self.viewModel.toggleClicking()
        }
    }
}
