import SwiftUI
import Carbon

// Notification names to broadcast shortcut and policy updates
extension Notification.Name {
    static let shortcutsDidChange = Notification.Name("com.farchan.sniper.shortcutsDidChange")
    static let activationPolicyDidChange = Notification.Name("com.farchan.sniper.activationPolicyDidChange")
}

// MARK: - Preferences Data Storage
@MainActor
class Preferences: ObservableObject {
    static let shared = Preferences()
    
    // Preferences Storage Keys
    private let kSavePath = "com.farchan.sniper.savePath"
    private let kAutoCopy = "com.farchan.sniper.autoCopy"
    private let kPlaySound = "com.farchan.sniper.playSound"
    private let kMenuBarOnly = "com.farchan.sniper.menuBarOnly"
    
    private let kOcrModifier = "com.farchan.sniper.ocrModifier"
    private let kOcrKeyCode = "com.farchan.sniper.ocrKeyCode"
    
    private let kScModifier = "com.farchan.sniper.scModifier"
    private let kScKeyCode = "com.farchan.sniper.scKeyCode"
    
    private let kFsModifier = "com.farchan.sniper.fsModifier"
    private let kFsKeyCode = "com.farchan.sniper.fsKeyCode"
    
    private let kChModifier = "com.farchan.sniper.chModifier"
    private let kChKeyCode = "com.farchan.sniper.chKeyCode"
    
    private let kLauncherModifier = "com.farchan.sniper.launcherModifier"
    private let kLauncherKeyCode = "com.farchan.sniper.launcherKeyCode"
    
    @Published var savePath: String {
        didSet { UserDefaults.standard.set(savePath, forKey: kSavePath) }
    }
    
    @Published var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: kAutoCopy) }
    }
    
    @Published var playSound: Bool {
        didSet { UserDefaults.standard.set(playSound, forKey: kPlaySound) }
    }
    
    @Published var runAsMenuBarOnly: Bool {
        didSet {
            UserDefaults.standard.set(runAsMenuBarOnly, forKey: kMenuBarOnly)
            NotificationCenter.default.post(name: .activationPolicyDidChange, object: nil)
        }
    }
    
    // Shortcuts config
    @Published var ocrModifier: UInt32 {
        didSet {
            UserDefaults.standard.set(ocrModifier, forKey: kOcrModifier)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    @Published var ocrKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(ocrKeyCode, forKey: kOcrKeyCode)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    
    @Published var scModifier: UInt32 {
        didSet {
            UserDefaults.standard.set(scModifier, forKey: kScModifier)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    @Published var scKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(scKeyCode, forKey: kScKeyCode)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    
    @Published var fsModifier: UInt32 {
        didSet {
            UserDefaults.standard.set(fsModifier, forKey: kFsModifier)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    @Published var fsKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(fsKeyCode, forKey: kFsKeyCode)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    
    @Published var chModifier: UInt32 {
        didSet {
            UserDefaults.standard.set(chModifier, forKey: kChModifier)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    @Published var chKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(chKeyCode, forKey: kChKeyCode)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    
    @Published var launcherModifier: UInt32 {
        didSet {
            UserDefaults.standard.set(launcherModifier, forKey: kLauncherModifier)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    @Published var launcherKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(launcherKeyCode, forKey: kLauncherKeyCode)
            NotificationCenter.default.post(name: .shortcutsDidChange, object: nil)
        }
    }
    
    private init() {
        // Defaults
        let defaultPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory()
        
        self.savePath = UserDefaults.standard.string(forKey: kSavePath) ?? defaultPath
        self.autoCopy = UserDefaults.standard.object(forKey: kAutoCopy) as? Bool ?? true
        self.playSound = UserDefaults.standard.object(forKey: kPlaySound) as? Bool ?? true
        self.runAsMenuBarOnly = UserDefaults.standard.object(forKey: kMenuBarOnly) as? Bool ?? false
        
        // OCR shortcut default: Cmd + Shift + 8 (768, 28)
        self.ocrModifier = UserDefaults.standard.object(forKey: kOcrModifier) as? UInt32 ?? UInt32(cmdKey | shiftKey)
        self.ocrKeyCode = UserDefaults.standard.object(forKey: kOcrKeyCode) as? UInt32 ?? 28
        
        // Screenshot shortcut default: Cmd + Shift + 7 (768, 26)
        self.scModifier = UserDefaults.standard.object(forKey: kScModifier) as? UInt32 ?? UInt32(cmdKey | shiftKey)
        self.scKeyCode = UserDefaults.standard.object(forKey: kScKeyCode) as? UInt32 ?? 26
        
        // Fullscreen shortcut default: Cmd + Option + F (2304, 3)
        self.fsModifier = UserDefaults.standard.object(forKey: kFsModifier) as? UInt32 ?? UInt32(cmdKey | optionKey)
        self.fsKeyCode = UserDefaults.standard.object(forKey: kFsKeyCode) as? UInt32 ?? 3
        
        // Clipboard history shortcut default: Option + C (2048, 8)
        self.chModifier = UserDefaults.standard.object(forKey: kChModifier) as? UInt32 ?? UInt32(optionKey)
        self.chKeyCode = UserDefaults.standard.object(forKey: kChKeyCode) as? UInt32 ?? 8
        
        // Launcher shortcut default: Option + Space
        self.launcherModifier = UserDefaults.standard.object(forKey: kLauncherModifier) as? UInt32 ?? UInt32(optionKey)
        self.launcherKeyCode = UserDefaults.standard.object(forKey: kLauncherKeyCode) as? UInt32 ?? 49
    }
}

// MARK: - Class-Based State Manager for Keystroke Recording
@MainActor
class ShortcutRecorderState: ObservableObject {
    @Published var isRecording = false
    private var monitor: Any?
    
    func startRecording(onKeyRecorded: @escaping @MainActor @Sendable (UInt32, UInt32) -> Void) {
        // Stop any active recordings first
        stopRecording()
        isRecording = true
        
        // Monitor key events in this application locally
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            // Escape cancels recording
            if event.keyCode == 53 {
                Task { @MainActor in
                    self?.stopRecording()
                }
                return nil // consume event
            }
            
            let flags = event.modifierFlags
            var carbonFlags: UInt32 = 0
            if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
            if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
            if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
            if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
            
            // Require at least one modifier key
            guard carbonFlags != 0 else {
                return event // pass through
            }
            
            let keyCode = UInt32(event.keyCode)
            let modifier = carbonFlags
            
            // Post update back to the main thread bindings and stop recording
            Task { @MainActor in
                onKeyRecorded(modifier, keyCode)
                self?.stopRecording()
            }
            
            return nil // consume event
        }
    }
    
    func stopRecording() {
        isRecording = false
        if let monitor = self.monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

// MARK: - Interactive Shortcut Recorder View
struct ShortcutRecorderView: View {
    let label: String
    let color: Color
    @Binding var modifier: UInt32
    @Binding var keyCode: UInt32
    
    @StateObject private var state = ShortcutRecorderState()
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {
                if state.isRecording {
                    state.stopRecording()
                } else {
                    state.startRecording { newMod, newKey in
                        self.modifier = newMod
                        self.keyCode = newKey
                    }
                }
            }) {
                Text(state.isRecording ? "Press keys... (Esc to Cancel)" : shortcutString(modifier: modifier, keyCode: keyCode))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(state.isRecording ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
                    .foregroundColor(state.isRecording ? .accentColor : .primary)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(state.isRecording ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hover in
                isHovered = hover
            }
            .help("Click to customize keyboard shortcut")
        }
        .padding(.vertical, 6)
        .onDisappear {
            state.stopRecording()
        }
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

// MARK: - Preferences UI View
struct PreferencesView: View {
    @ObservedObject private var prefs = Preferences.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Preferences")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                
                // Group 1: General Settings Block
                VStack(alignment: .leading, spacing: 8) {
                    Text("GENERAL SETTINGS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    VStack(spacing: 0) {
                        // Toggle 1
                        HStack {
                            Text("Run as Menu Bar App Only")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Toggle("", isOn: $prefs.runAsMenuBarOnly)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        
                        Divider().padding(.leading, 16)
                        
                        // Toggle 2
                        HStack {
                            Text("Auto-copy to Clipboard")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Toggle("", isOn: $prefs.autoCopy)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        
                        Divider().padding(.leading, 16)
                        
                        // Toggle 3
                        HStack {
                            Text("Play Camera Sound Effects")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Toggle("", isOn: $prefs.playSound)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        
                        Divider().padding(.leading, 16)
                        
                        // Path selector row
                        HStack(spacing: 12) {
                            Text("Save screenshots to:")
                                .font(.system(size: 13, weight: .medium))
                            
                            Spacer()
                            
                            Text(folderDisplayName(prefs.savePath))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(5)
                                .lineLimit(1)
                            
                            Button("Choose...") {
                                selectFolder()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                
                // Group 2: Shortcuts
                VStack(alignment: .leading, spacing: 8) {
                    Text("GLOBAL KEYBOARD SHORTCUTS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    VStack(spacing: 0) {
                        ShortcutRecorderView(
                            label: "Capture & OCR Area",
                            color: .orange,
                            modifier: $prefs.ocrModifier,
                            keyCode: $prefs.ocrKeyCode
                        )
                        
                        Divider()
                        
                        ShortcutRecorderView(
                            label: "Save Region Screenshot",
                            color: .green,
                            modifier: $prefs.scModifier,
                            keyCode: $prefs.scKeyCode
                        )
                        
                        Divider()
                        
                        ShortcutRecorderView(
                            label: "Capture Full Screen",
                            color: .teal,
                            modifier: $prefs.fsModifier,
                            keyCode: $prefs.fsKeyCode
                        )
                        
                        Divider()
                        
                        ShortcutRecorderView(
                            label: "Clipboard History",
                            color: .purple,
                            modifier: $prefs.chModifier,
                            keyCode: $prefs.chKeyCode
                        )
                        
                        Divider()
                        
                        ShortcutRecorderView(
                            label: "App & Tools Launcher",
                            color: .blue,
                            modifier: $prefs.launcherModifier,
                            keyCode: $prefs.launcherKeyCode
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
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
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: prefs.savePath)
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            prefs.savePath = selectedURL.path
        }
    }
    
    private func folderDisplayName(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }
}
