import AppKit
import SwiftUI
import Carbon

@MainActor
class SuperSniperApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?
    
    // Temp capture location
    private var tempCaptureURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("sniper_capture_temp.png")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status item in system menu bar
        setupStatusItem()
        
        // Register global shortcuts
        registerShortcuts()
        
        // Observe shortcut preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutsPreferenceChanged),
            name: .shortcutsDidChange,
            object: nil
        )
        
        // Observe activation policy changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activationPolicyPreferenceChanged),
            name: .activationPolicyDidChange,
            object: nil
        )
        
        // Apply initial activation policy (regular vs. accessory) and open window if regular
        applyActivationPolicy(initialLaunch: true)
        
        print("SuperSniper application launched and background shortcuts registered.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregisterAll()
        cleanupTempFile()
    }
    
    // Reopen main window when clicking the Dock icon (if app is running as regular Dock app)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }
    
    // MARK: - Status Item Setup
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "SuperSniper")
            button.action = nil
        }
        
        let menu = NSMenu()
        menu.delegate = self // Set delegate to build menu dynamically before display
        statusItem?.menu = menu
    }
    
    // MARK: - Dynamic Menu Rebuilding
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        
        let prefs = Preferences.shared
        
        // Window Control
        let showWindowItem = NSMenuItem(title: "Open SuperSniper Dashboard", action: #selector(menuOpenMainWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)
        
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(menuOpenPreferences), keyEquivalent: "")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Primary Actions with current shortcuts displayed
        let ocrStr = shortcutString(modifier: prefs.ocrModifier, keyCode: prefs.ocrKeyCode)
        let ocrItem = NSMenuItem(title: "Capture & OCR Area (\(ocrStr))", action: #selector(menuCaptureAndOCR), keyEquivalent: "")
        ocrItem.target = self
        menu.addItem(ocrItem)
        
        let scStr = shortcutString(modifier: prefs.scModifier, keyCode: prefs.scKeyCode)
        let scItem = NSMenuItem(title: "Capture Screenshot (\(scStr))", action: #selector(menuCaptureArea), keyEquivalent: "")
        scItem.target = self
        menu.addItem(scItem)
        
        let fsStr = shortcutString(modifier: prefs.fsModifier, keyCode: prefs.fsKeyCode)
        let fsItem = NSMenuItem(title: "Capture Full Screen (\(fsStr))", action: #selector(menuCaptureFullScreen), keyEquivalent: "")
        fsItem.target = self
        menu.addItem(fsItem)
        
        let clipboardItem = NSMenuItem(title: "OCR Clipboard Image", action: #selector(menuOCRClipboard), keyEquivalent: "")
        clipboardItem.target = self
        menu.addItem(clipboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // History Submenu
        let historyMenu = NSMenu()
        let historyItem = NSMenuItem(title: "OCR Snippet History", action: nil, keyEquivalent: "")
        
        let historyEntries = HistoryManager.shared.items
        if historyEntries.isEmpty {
            let emptyItem = NSMenuItem(title: "No recent clippings", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            historyMenu.addItem(emptyItem)
        } else {
            for item in historyEntries {
                // Truncate text for menu item preview
                let previewLength = 30
                var truncatedText = item.text.replacingOccurrences(of: "\n", with: " ")
                if truncatedText.count > previewLength {
                    truncatedText = String(truncatedText.prefix(previewLength)) + "..."
                }
                
                let entryItem = NSMenuItem(title: truncatedText, action: #selector(menuCopyHistoryItem(_:)), keyEquivalent: "")
                entryItem.target = self
                entryItem.representedObject = item.text
                historyMenu.addItem(entryItem)
            }
            
            historyMenu.addItem(NSMenuItem.separator())
            
            let clearItem = NSMenuItem(title: "Clear History", action: #selector(menuClearHistory), keyEquivalent: "")
            clearItem.target = self
            historyMenu.addItem(clearItem)
        }
        
        historyItem.submenu = historyMenu
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit SuperSniper", action: #selector(menuQuit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Shortcut Registration Management
    private func registerShortcuts() {
        let prefs = Preferences.shared
        
        // Register OCR (ID: 1)
        HotKeyManager.shared.register(
            id: 1,
            keyCode: prefs.ocrKeyCode,
            modifiers: prefs.ocrModifier,
            action: { [weak self] in
                self?.captureAndOCR()
            }
        )
        
        // Register Screenshot (ID: 2)
        HotKeyManager.shared.register(
            id: 2,
            keyCode: prefs.scKeyCode,
            modifiers: prefs.scModifier,
            action: { [weak self] in
                self?.captureArea()
            }
        )
        
        // Register Fullscreen (ID: 3)
        HotKeyManager.shared.register(
            id: 3,
            keyCode: prefs.fsKeyCode,
            modifiers: prefs.fsModifier,
            action: { [weak self] in
                self?.captureFullScreen()
            }
        )
    }
    
    @objc private func shortcutsPreferenceChanged() {
        print("Re-registering hotkeys after preference update...")
        registerShortcuts()
    }
    
    // MARK: - Activation Policy Shifting
    private func applyActivationPolicy(initialLaunch: Bool = false) {
        let prefs = Preferences.shared
        if prefs.runAsMenuBarOnly {
            // Run in background menu bar only
            NSApp.setActivationPolicy(.accessory)
            if !initialLaunch {
                closeMainWindow()
            }
        } else {
            // Run as a regular application with Dock icon
            NSApp.setActivationPolicy(.regular)
            openMainWindow()
        }
    }
    
    @objc private func activationPolicyPreferenceChanged() {
        print("Shifting activation policy...")
        applyActivationPolicy()
    }
    
    // MARK: - Window Management
    private func openMainWindow() {
        if mainWindow == nil {
            let view = MainView()
            let hostingController = NSHostingController(rootView: view)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "SuperSniper"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.center()
            self.mainWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func closeMainWindow() {
        mainWindow?.close()
    }
    
    // MARK: - Core Operations
    
    /// Interactive selection and OCR
    private func captureAndOCR() {
        cleanupTempFile()
        
        let prefs = Preferences.shared
        let tempURL = self.tempCaptureURL
        
        CaptureManager.shared.captureInteractive(outputURL: tempURL) { [weak self] success in
            guard success else {
                HUDManager.shared.showToast(with: "Canceled")
                self?.cleanupTempFile()
                return
            }
            
            // Perform Sound effects if enabled
            if prefs.playSound {
                NSSound(named: "Hero")?.play()
            }
            
            // Perform OCR on captured temporal image
            OCRManager.shared.recognizeText(from: tempURL) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        HUDManager.shared.showHUD(with: text)
                    case .failure(let error):
                        HUDManager.shared.showHUD(with: "OCR Error: \(error.localizedDescription)")
                    }
                    self?.cleanupTempFile()
                }
            }
        }
    }
    
    /// Interactive region screenshot saving
    private func captureArea() {
        cleanupTempFile()
        
        let prefs = Preferences.shared
        let tempURL = self.tempCaptureURL
        let targetDir = URL(fileURLWithPath: prefs.savePath)
        
        CaptureManager.shared.captureInteractive(outputURL: tempURL) { [weak self] success in
            guard success else {
                HUDManager.shared.showToast(with: "Canceled")
                self?.cleanupTempFile()
                return
            }
            
            if prefs.playSound {
                NSSound(named: "Hero")?.play()
            }
            
            if prefs.autoCopy {
                _ = CaptureManager.shared.copyToClipboard(imageURL: tempURL)
            }
            
            _ = CaptureManager.shared.saveToTargetFolder(tempURL: tempURL, targetDirectory: targetDir)
            self?.cleanupTempFile()
        }
    }
    
    /// Fullscreen screenshot saving
    private func captureFullScreen() {
        cleanupTempFile()
        
        let prefs = Preferences.shared
        let tempURL = self.tempCaptureURL
        let targetDir = URL(fileURLWithPath: prefs.savePath)
        
        CaptureManager.shared.captureFullScreen(outputURL: tempURL) { [weak self] success in
            guard success else {
                HUDManager.shared.showToast(with: "Canceled")
                self?.cleanupTempFile()
                return
            }
            
            if prefs.playSound {
                NSSound(named: "Hero")?.play()
            }
            
            if prefs.autoCopy {
                _ = CaptureManager.shared.copyToClipboard(imageURL: tempURL)
            }
            
            _ = CaptureManager.shared.saveToTargetFolder(tempURL: tempURL, targetDirectory: targetDir)
            self?.cleanupTempFile()
        }
    }
    
    /// Perform OCR on the clipboard image
    private func ocrClipboard() {
        let pasteboard = NSPasteboard.general
        guard let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            HUDManager.shared.showHUD(with: "Clipboard does not contain any image.")
            return
        }
        
        OCRManager.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    HUDManager.shared.showHUD(with: text)
                case .failure(let error):
                    HUDManager.shared.showHUD(with: "OCR Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Menu Actions Callbacks
    @objc func menuCaptureAndOCR() { captureAndOCR() }
    @objc func menuCaptureArea() { captureArea() }
    @objc func menuCaptureFullScreen() { captureFullScreen() }
    @objc func menuOCRClipboard() { ocrClipboard() }
    
    @objc func menuOpenMainWindow() {
        NavigationState.shared.selectedTab = .dashboard
        openMainWindow()
    }
    
    @objc func menuOpenPreferences() {
        NavigationState.shared.selectedTab = .settings
        openMainWindow()
    }
    
    @objc private func menuCopyHistoryItem(_ sender: NSMenuItem) {
        if let text = sender.representedObject as? String {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            HUDManager.shared.showHUD(with: text)
        }
    }
    
    @objc private func menuClearHistory() {
        HistoryManager.shared.clearHistory()
    }
    
    @objc private func menuQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Helpers
    private func cleanupTempFile() {
        let path = tempCaptureURL.path
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
    
    private func shortcutString(modifier: UInt32, keyCode: UInt32) -> String {
        var modStr = ""
        if (modifier & UInt32(cmdKey)) != 0 { modStr += "⌘" }
        if (modifier & UInt32(optionKey)) != 0 { modStr += "⌥" }
        if (modifier & UInt32(controlKey)) != 0 { modStr += "⌃" }
        if (modifier & UInt32(shiftKey)) != 0 { modStr += "⇧" }
        
        let keyStr: String
        switch keyCode {
        case 28: keyStr = "8"
        case 26: keyStr = "7"
        case 19: keyStr = "2"
        case 20: keyStr = "3"
        case 21: keyStr = "4"
        case 23: keyStr = "5"
        case 31: keyStr = "O"
        case 1: keyStr = "S"
        case 3: keyStr = "F"
        case 8: keyStr = "C"
        case 9: keyStr = "V"
        case 12: keyStr = "Q"
        case 14: keyStr = "E"
        case 15: keyStr = "R"
        case 35: keyStr = "P"
        case 49: keyStr = "Space"
        case 0: keyStr = "A"
        case 2: keyStr = "D"
        case 4: keyStr = "H"
        case 5: keyStr = "G"
        case 6: keyStr = "Z"
        case 7: keyStr = "X"
        case 13: keyStr = "W"
        case 16: keyStr = "Y"
        case 17: keyStr = "T"
        case 37: keyStr = "L"
        case 38: keyStr = "J"
        case 40: keyStr = "K"
        default: keyStr = "Key[\(keyCode)]"
        }
        
        return "\(modStr)\(keyStr)"
    }
}
