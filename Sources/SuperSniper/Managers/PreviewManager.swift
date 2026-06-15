import Foundation
import Quartz
import AppKit

@MainActor
class PreviewManager: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = PreviewManager()
    
    private var currentURL: URL?
    
    private override init() {
        super.init()
    }
    
    func togglePreview(for url: URL) {
        self.currentURL = url
        
        guard let panel = QLPreviewPanel.shared() else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.dataSource = self
            panel.delegate = self
            panel.makeKeyAndOrderFront(nil)
            panel.reloadData()
        }
    }
    
    func closePreview() {
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.orderOut(nil)
        }
    }
    
    // MARK: - QLPreviewPanelDataSource
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return currentURL != nil ? 1 : 0
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return currentURL! as QLPreviewItem
    }
    
    // MARK: - QLPreviewPanelDelegate
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        // If the user presses Esc or Space, we can close the panel
        if event.type == .keyDown {
            if event.keyCode == 53 || event.keyCode == 49 { // Esc or Space
                panel.orderOut(nil)
                return true
            }
        }
        return false
    }
}
