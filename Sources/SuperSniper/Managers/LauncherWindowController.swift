import AppKit
import SwiftUI

class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    // Intercept Arrow Keys, Return, and Esc so they are globally routed
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            // 125 = Down Arrow, 126 = Up Arrow, 36 = Return, 53 = Esc
            if [125, 126, 36, 53].contains(event.keyCode) {
                NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.launcherKeyPressed"), object: event.keyCode)
                return // Consume the event completely
            }
            
            // Handle standard Edit shortcuts because borderless windows lack a Main Menu
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
                let handled: Bool
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "x": handled = NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
                case "c": handled = NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
                case "v": handled = NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
                case "a": handled = NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
                case "z": handled = NSApp.sendAction(Selector(("undo:")), to: nil, from: self)
                default: handled = false
                }
                if handled { return }
            }
        }
        super.sendEvent(event)
    }
}

@MainActor
class LauncherWindowController: NSWindowController, NSWindowDelegate {
    static let shared = LauncherWindowController()
    
    private init() {
        let panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false // Shadow is now handled by SwiftUI so it matches the dynamic shape
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.center()
        
        // Wrap LauncherView in a clear background and give it rounded corners
        let hostingView = NSHostingView(
            rootView: LauncherView()
                // .background(VisualEffectView(material: .popover, blendingMode: .behindWindow)) -> Added inside LauncherView
        )
        panel.contentView = hostingView
        
        super.init(window: panel)
        panel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toggleWindow() {
        guard let window = self.window else { return }
        if window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        guard let window = self.window else { return }
        
        // Center horizontally, and position ~25% from the top (like Spotlight)
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let yPos = screenRect.maxY - (screenRect.height * 0.25) - 600
            let newOrigin = NSPoint(
                x: screenRect.midX - 350,
                y: yPos
            )
            window.setFrameOrigin(newOrigin)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.launcherWindowDidOpen"), object: nil)
    }
    
    func hideWindow() {
        self.window?.orderOut(nil)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        hideWindow()
    }
}
