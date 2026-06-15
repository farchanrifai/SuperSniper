import AppKit
import SwiftUI

@MainActor
class ClipboardWindowController: NSWindowController, NSWindowDelegate {
    static let shared = ClipboardWindowController()
    
    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 450),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
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
    }
    
    func hideWindow() {
        self.window?.orderOut(nil)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        hideWindow()
    }
}
