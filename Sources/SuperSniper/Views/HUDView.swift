import SwiftUI
import AppKit

// Removed legacy VisualEffectView wrapper
// MARK: - HUD SwiftUI View
struct HUDView: View {
    @State var text: String
    var onClose: () -> Void
    
    @State private var isCopied = false
    @State private var isHovered = false
    @State private var dismissTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Row
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                
                Text(text.isEmpty ? "No Text Recognized" : "Text Copied to Clipboard")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Dismiss HUD")
            }
            
            // Text Area
            if !text.isEmpty {
                ScrollView {
                    Text(text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 75)
                .background(Color.black.opacity(0.15))
                .cornerRadius(6)
            } else {
                VStack {
                    Spacer()
                    Text("Could not find any readable text in selection.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 75)
            }
            
            // Footer Control Row
            HStack {
                Text("\(text.count) characters")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !text.isEmpty {
                    Button(action: copyToClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                            Text(isCopied ? "Copied!" : "Copy")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isCopied ? Color.green.opacity(0.2) : Color.primary.opacity(0.1))
                        .foregroundColor(isCopied ? .green : .primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 420, height: 160)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            copyToClipboard()
            startDismissTimer()
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                stopDismissTimer()
            } else {
                startDismissTimer()
            }
        }
    }
    
    private func copyToClipboard() {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        // Register to history
        HistoryManager.shared.addEntry(text: text)
        
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }
    
    private func startDismissTimer() {
        stopDismissTimer()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                onClose()
            }
        }
    }
    
    private func stopDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}

// MARK: - Toast View
struct ToastView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(in: RoundedRectangle(cornerRadius: 8))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Native NSPanel HUD Overlay
@MainActor
class HUDPanel: NSPanel {
    init(contentView: NSView, width: CGFloat = 420, height: CGFloat = 160) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.contentView = contentView
    }
    
    func positionAtBottomCenter(width: CGFloat = 420, height: CGFloat = 160) {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.origin.x + (screenFrame.width - width) / 2
            let y = screenFrame.origin.y + 60 // Float above Dock
            self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }
    }
    
    func positionAtCursor(width: CGFloat, height: CGFloat) {
        let mouseLoc = NSEvent.mouseLocation
        let x = mouseLoc.x + 10
        let y = mouseLoc.y - height - 10
        self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}

// MARK: - HUD Display Manager
@MainActor
class HUDManager {
    static let shared = HUDManager()
    
    private var hudPanel: HUDPanel?
    
    private init() {}
    
    /// Display the HUD on screen with a fade-in animation.
    func showHUD(with text: String) {
        DispatchQueue.main.async {
            self.hideHUDImmediately()
            
            let hudView = HUDView(text: text, onClose: { [weak self] in
                self?.hideHUD()
            })
            
            let hostingView = NSHostingView(rootView: hudView)
            let panel = HUDPanel(contentView: hostingView)
            self.hudPanel = panel
            
            panel.positionAtBottomCenter()
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                panel.animator().alphaValue = 1.0
            }
        }
    }
    
    /// Display a small toast notification.
    func showToast(with text: String) {
        DispatchQueue.main.async {
            self.hideHUDImmediately()
            
            let toastView = ToastView(text: text)
            let hostingView = NSHostingView(rootView: toastView)
            
            // Use fittingSize to dynamically size the panel for the toast
            let size = hostingView.fittingSize
            let width = size.width
            let height = size.height
            
            let panel = HUDPanel(contentView: hostingView, width: width, height: height)
            self.hudPanel = panel
            
            panel.positionAtBottomCenter(width: width, height: height)
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                panel.animator().alphaValue = 1.0
            }
            
            // Auto-hide toast after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.hideHUD()
            }
        }
    }
    
    /// Display a small toast notification near the mouse cursor.
    func showToastAtCursor(with text: String) {
        DispatchQueue.main.async {
            self.hideHUDImmediately()
            
            let toastView = ToastView(text: text)
            let hostingView = NSHostingView(rootView: toastView)
            
            let size = hostingView.fittingSize
            let width = size.width
            let height = size.height
            
            let panel = HUDPanel(contentView: hostingView, width: width, height: height)
            self.hudPanel = panel
            
            panel.positionAtCursor(width: width, height: height)
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                panel.animator().alphaValue = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.hideHUD()
            }
        }
    }
    
    /// Dismiss the HUD with a fade-out animation.
    func hideHUD() {
        DispatchQueue.main.async {
            guard let panel = self.hudPanel else { return }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                panel.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                Task { @MainActor in
                    panel.orderOut(nil)
                    if self?.hudPanel === panel {
                        self?.hudPanel = nil
                    }
                }
            })
        }
    }
    
    /// Hide the HUD immediately without transition animations.
    private func hideHUDImmediately() {
        hudPanel?.orderOut(nil)
        hudPanel = nil
    }
}

