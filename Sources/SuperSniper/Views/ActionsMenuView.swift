import SwiftUI
import AppKit

struct ActionsMenuView: View {
    let item: LauncherItem
    let onClose: () -> Void
    
    @State private var openWithApps: [URL] = []
    @State private var showingOpenWith = false
    
    @State private var selectedIndex = 0
    
    let baseActions = [
        ("Open File Directory", "folder"),
        ("Copy File", "doc.on.doc"),
        ("Open With...", "arrow.up.right.square"),
        ("AirDrop", "airplayaudio"),
        ("Delete", "trash")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(showingOpenWith ? "Open With..." : "Actions for \(item.name)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 4) {
                    if showingOpenWith {
                        ForEach(Array(openWithApps.enumerated()), id: \.offset) { index, appURL in
                            HStack {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Text(appURL.deletingPathExtension().lastPathComponent)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedIndex == index ? Color.accentColor : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(selectedIndex == index ? .white : .primary)
                        }
                    } else {
                        ForEach(Array(baseActions.enumerated()), id: \.offset) { index, action in
                            HStack {
                                Image(systemName: action.1)
                                    .frame(width: 24)
                                Text(action.0)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedIndex == index ? Color.accentColor : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(selectedIndex == index ? .white : .primary)
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 350, height: 350)
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onAppear {
            if let url = item.url {
                openWithApps = NSWorkspace.shared.urlsForApplications(toOpen: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.launcherKeyPressed"))) { notification in
            if let keyCode = notification.object as? UInt16 {
                handleRawKey(keyCode)
            }
        }
    }
    
    private func handleRawKey(_ keyCode: UInt16) {
        let maxIndex = showingOpenWith ? openWithApps.count - 1 : baseActions.count - 1
        
        if keyCode == 53 { // Esc
            if showingOpenWith {
                showingOpenWith = false
                selectedIndex = 2 // "Open With..." index
            } else {
                onClose()
            }
            return
        }
        
        if keyCode == 125 { // Down
            if selectedIndex < maxIndex { selectedIndex += 1 }
        } else if keyCode == 126 { // Up
            if selectedIndex > 0 { selectedIndex -= 1 }
        } else if keyCode == 36 || keyCode == 124 { // Return or Right
            executeSelected()
        } else if keyCode == 123 { // Left
            if showingOpenWith {
                showingOpenWith = false
                selectedIndex = 2
            }
        }
    }
    
    private func executeSelected() {
        if showingOpenWith {
            if selectedIndex < openWithApps.count {
                openWithApp(openWithApps[selectedIndex])
            }
            return
        }
        
        switch selectedIndex {
        case 0: revealInFinder()
        case 1: copyFile()
        case 2: 
            showingOpenWith = true
            selectedIndex = 0
        case 3: airDrop()
        case 4: deleteFile()
        default: break
        }
    }
    
    func copyFile() {
        guard let url = item.url else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([url as NSURL])
        HUDManager.shared.showHUD(with: "Copied File")
        LauncherWindowController.shared.hideWindow()
        onClose()
    }
    
    func revealInFinder() {
        guard let url = item.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        LauncherWindowController.shared.hideWindow()
        onClose()
    }
    
    func openWithApp(_ appURL: URL) {
        guard let url = item.url else { return }
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: config, completionHandler: nil)
        LauncherWindowController.shared.hideWindow()
        onClose()
    }
    
    func airDrop() {
        guard let url = item.url else { return }
        let service = NSSharingService(named: .sendViaAirDrop)
        service?.perform(withItems: [url])
        LauncherWindowController.shared.hideWindow()
        onClose()
    }
    
    func deleteFile() {
        guard let url = item.url else { return }
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            HUDManager.shared.showHUD(with: "Moved to Trash")
        } catch {
            print("Failed to trash file")
        }
        LauncherWindowController.shared.hideWindow()
        onClose()
    }
}
