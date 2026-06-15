import Foundation
import AppKit

@MainActor
class ClipboardObserver: ObservableObject {
    static let shared = ClipboardObserver()
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isInternalCopy: Bool = false
    
    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    /// Starts polling the NSPasteboard in the background.
    func startObserving() {
        guard timer == nil else { return }
        
        // Run a lightweight timer every 0.75 seconds to detect clipboard changes
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForChanges()
            }
        }
        
        // Ensure timer runs even during UI scrolling
        if let t = timer {
            RunLoop.current.add(t, forMode: .common)
        }
    }
    
    /// Stops the clipboard polling.
    func stopObserving() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Notifies the observer that the upcoming clipboard change was triggered internally by the user pasting/copying from the app itself.
    func ignoreNextChange() {
        isInternalCopy = true
    }
    
    private func checkForChanges() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        // Ignore changes triggered by SuperSniper itself (e.g. copying OCR text)
        if isInternalCopy {
            isInternalCopy = false
            return
        }
        
        // Defer to HistoryManager to parse and save the new clipboard content
        HistoryManager.shared.addEntryFromPasteboard(NSPasteboard.general)
    }
}
