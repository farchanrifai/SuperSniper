import AppKit
import SwiftUI

class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    // Intercept Arrow Keys, Return, and Esc so they are globally routed
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            // 125 = Down Arrow, 126 = Up Arrow, 36 = Return, 53 = Esc
            if [125, 126, 36, 53].contains(event.keyCode) {
                NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.rawKeyPressed"), object: event.keyCode)
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
class ClipboardWindowController: NSWindowController, NSWindowDelegate {
    static let shared = ClipboardWindowController()
    
    private init() {
        let panel = ClipboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 450),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.center()
        
        // Wrap HistoryListView in a clear background and give it rounded corners
        let hostingView = NSHostingView(
            rootView: HistoryListView()
                .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
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
        
        // Center on the active screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newOrigin = NSPoint(
                x: screenRect.midX - window.frame.width / 2,
                y: screenRect.midY - window.frame.height / 2
            )
            window.setFrameOrigin(newOrigin)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.clipboardWindowDidOpen"), object: nil)
    }
    
    func hideWindow() {
        self.window?.orderOut(nil)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        hideWindow()
    }
}
