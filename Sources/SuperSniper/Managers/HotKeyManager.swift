import Carbon
import AppKit

@MainActor
class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeys: [UInt32: (ref: EventHotKeyRef, action: () -> Void)] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var isHandlerInstalled = false
    
    // OSType signature for our app hotkeys: "SNIP" -> 0x534e4950
    private let hotKeySignature: OSType = 0x534e4950
    
    private init() {}
    
    /// Install the global Carbon event handler to process hotkey events.
    private func installEventHandlerIfNeeded() {
        guard !isHandlerInstalled else { return }
        
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                    manager.handleHotKeyTrigger(id: hotKeyID.id)
                }
                
                return noErr
            },
            1,
            &eventSpec,
            selfPointer,
            &eventHandlerRef
        )
        
        if status == noErr {
            isHandlerInstalled = true
            print("Successfully installed Carbon HotKey Event Handler.")
        } else {
            print("Failed to install Carbon HotKey Event Handler: \(status)")
        }
    }
    
    /// Register a new global hotkey.
    func register(id: UInt32, keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        // First make sure event handler is active
        installEventHandlerIfNeeded()
        
        // Unregister existing hotkey for this ID if it exists
        unregister(id: id)
        
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: id)
        var hotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            hotKeys[id] = (ref, action)
            print("Registered hotkey ID: \(id), KeyCode: \(keyCode), Modifiers: \(modifiers)")
        } else {
            print("Failed to register hotkey ID: \(id) (error code: \(status))")
        }
    }
    
    /// Unregister an existing hotkey.
    func unregister(id: UInt32) {
        guard let entry = hotKeys[id] else { return }
        
        let status = UnregisterEventHotKey(entry.ref)
        if status == noErr {
            hotKeys.removeValue(forKey: id)
            print("Unregistered hotkey ID: \(id)")
        } else {
            print("Failed to unregister hotkey ID: \(id) (error code: \(status))")
        }
    }
    
    /// Unregister all hotkeys.
    func unregisterAll() {
        for id in hotKeys.keys {
            unregister(id: id)
        }
    }
    
    /// Internal callback from the Carbon event loop.
    private func handleHotKeyTrigger(id: UInt32) {
        guard let entry = hotKeys[id] else { return }
        // Run on the main queue to perform UI actions safely
        DispatchQueue.main.async {
            entry.action()
        }
    }
}
