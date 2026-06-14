import SwiftUI
import Carbon

struct DashboardView: View {
    @ObservedObject var history = HistoryManager.shared
    @ObservedObject private var prefs = Preferences.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Title
                Text("Dashboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                
                // Group 1: Quick Capture Actions
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUICK SCAN ACTIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    VStack(spacing: 0) {
                        PreferenceActionRow(
                            title: "Capture & OCR Area",
                            description: "Select an area of the screen to perform text recognition offline.",
                            icon: "crop.badge.viewfinder",
                            color: .orange
                        ) {
                            triggerAction(#selector(SuperSniperApp.menuCaptureAndOCR))
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        PreferenceActionRow(
                            title: "OCR Clipboard Image",
                            description: "Examine the image currently in your clipboard and extract text.",
                            icon: "doc.on.clipboard",
                            color: .blue
                        ) {
                            triggerAction(#selector(SuperSniperApp.menuOCRClipboard))
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        PreferenceActionRow(
                            title: "Save Screenshot",
                            description: "Grab a region of the screen and save it to your local target folder.",
                            icon: "camera.viewfinder",
                            color: .green
                        ) {
                            triggerAction(#selector(SuperSniperApp.menuCaptureArea))
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        PreferenceActionRow(
                            title: "Capture Full Screen",
                            description: "Immediately save a capture of your entire display layout.",
                            icon: "macwindow",
                            color: .teal
                        ) {
                            triggerAction(#selector(SuperSniperApp.menuCaptureFullScreen))
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                
                // Group 2: System Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("SYSTEM OVERVIEW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    VStack(spacing: 0) {
                        PreferenceStatRow(
                            title: "Total OCR Clips",
                            value: "\(history.items.count) clippings",
                            icon: "doc.text.fill",
                            color: .purple
                        )
                        
                        Divider().padding(.leading, 52)
                        
                        PreferenceStatRow(
                            title: "Last Capture Activity",
                            value: lastScanTimeString(),
                            icon: "clock.fill",
                            color: .indigo
                        )
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                
                // Group 3: Keyboard Shortcuts Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACTIVE KEYBOARD SHORTCUTS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    VStack(spacing: 0) {
                        PreferenceShortcutRow(
                            title: "Capture & OCR Area",
                            keys: shortcutString(modifier: prefs.ocrModifier, keyCode: prefs.ocrKeyCode),
                            color: .orange
                        )
                        
                        Divider().padding(.leading, 12)
                        
                        PreferenceShortcutRow(
                            title: "Save Region Screenshot",
                            keys: shortcutString(modifier: prefs.scModifier, keyCode: prefs.scKeyCode),
                            color: .green
                        )
                        
                        Divider().padding(.leading, 12)
                        
                        PreferenceShortcutRow(
                            title: "Capture Full Screen",
                            keys: shortcutString(modifier: prefs.fsModifier, keyCode: prefs.fsKeyCode),
                            color: .teal
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding(24)
        }
    }
    
    private func triggerAction(_ selector: Selector) {
        if let delegate = NSApp.delegate as? SuperSniperApp {
            delegate.perform(selector)
        }
    }
    
    private func lastScanTimeString() -> String {
        guard let last = history.items.first else { return "No activity recorded" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: last.timestamp, relativeTo: Date())
    }
    
    private func shortcutString(modifier: UInt32, keyCode: UInt32) -> String {
        var modStr = ""
        if (modifier & UInt32(cmdKey)) != 0 { modStr += "⌘ " }
        if (modifier & UInt32(optionKey)) != 0 { modStr += "⌥ " }
        if (modifier & UInt32(controlKey)) != 0 { modStr += "⌃ " }
        if (modifier & UInt32(shiftKey)) != 0 { modStr += "⇧ " }
        
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

// MARK: - Premium Preference Action Row
struct PreferenceActionRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Settings-style Rounded Rect Icon
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hover
            }
        }
    }
}

// MARK: - Premium Preference Stat Row
struct PreferenceStatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Premium Preference Shortcut Row
struct PreferenceShortcutRow: View {
    let title: String
    let keys: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(keys)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 0.5)
                )
        }
        .padding(.vertical, 8)
    }
}
