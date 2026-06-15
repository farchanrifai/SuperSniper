import Foundation
import AppKit

enum ClipboardContentType: String, Codable {
    case text
    case image
    case file
}

struct HistoryItem: Codable, Identifiable, Hashable {
    var id: UUID
    var type: ClipboardContentType
    
    var text: String?
    var imageFileName: String?
    var fileURL: URL?
    
    var timestamp: Date
    var sourceApp: String?
    var copyCount: Int
    var charactersCount: Int?
    var wordsCount: Int?
    
    var displayText: String {
        switch type {
        case .text: return text ?? ""
        case .image: return "Image (\(imageFileName ?? "Unknown"))"
        case .file: return fileURL?.lastPathComponent ?? "File"
        }
    }
}

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var items: [HistoryItem] = []
    
    private let maxItems = 100
    private let userDefaultsKey = "com.farchan.sniper.clipboardHistoryV2"
    
    private var imagesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("SuperSniper/ClipboardImages")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {
        loadHistory()
    }
    
    func getImage(for fileName: String) -> NSImage? {
        let url = imagesDirectory.appendingPathComponent(fileName)
        return NSImage(contentsOf: url)
    }
    
    /// Called when OCR successfully adds an entry
    func addEntry(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let charCount = text.count
        let wordCount = text.split { $0.isWhitespace }.count
        
        let item = HistoryItem(id: UUID(), type: .text, text: text, imageFileName: nil, fileURL: nil, timestamp: Date(), sourceApp: "SuperSniper", copyCount: 1, charactersCount: charCount, wordsCount: wordCount)
        
        insertItem(item)
    }
    
    func addEntryFromPasteboard(_ pasteboard: NSPasteboard) {
        let timestamp = Date()
        let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        
        // 1. Check for File
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstURL = urls.first {
            let item = HistoryItem(id: UUID(), type: .file, text: nil, imageFileName: nil, fileURL: firstURL, timestamp: timestamp, sourceApp: activeApp, copyCount: 1, charactersCount: nil, wordsCount: nil)
            insertItem(item)
            return
        }
        
        // 2. Check for Image
        if let image = NSImage(pasteboard: pasteboard),
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            
            let fileName = UUID().uuidString + ".png"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            do {
                try pngData.write(to: fileURL)
                let item = HistoryItem(id: UUID(), type: .image, text: nil, imageFileName: fileName, fileURL: nil, timestamp: timestamp, sourceApp: activeApp, copyCount: 1, charactersCount: nil, wordsCount: nil)
                insertItem(item)
                return
            } catch {
                print("Failed to save clipboard image: \(error)")
            }
        }
        
        // 3. Check for Text
        if let text = pasteboard.string(forType: .string) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            
            let charCount = text.count
            let wordCount = text.split { $0.isWhitespace }.count
            
            let item = HistoryItem(id: UUID(), type: .text, text: text, imageFileName: nil, fileURL: nil, timestamp: timestamp, sourceApp: activeApp, copyCount: 1, charactersCount: charCount, wordsCount: wordCount)
            insertItem(item)
            return
        }
    }
    
    private func insertItem(_ newItem: HistoryItem) {
        // Find duplicate to update timestamp and move to top
        if let existingIndex = items.firstIndex(where: {
            if $0.type == .text && newItem.type == .text { return $0.text == newItem.text }
            if $0.type == .file && newItem.type == .file { return $0.fileURL == newItem.fileURL }
            // Ignore image duplicates for now to save performance, just add new
            return false
        }) {
            var updated = items[existingIndex]
            updated.timestamp = newItem.timestamp
            updated.copyCount += 1
            updated.sourceApp = newItem.sourceApp // update source to latest
            items.remove(at: existingIndex)
            items.insert(updated, at: 0)
        } else {
            items.insert(newItem, at: 0)
        }
        
        if items.count > maxItems {
            let toRemove = items.suffix(from: maxItems)
            for item in toRemove {
                if item.type == .image, let fileName = item.imageFileName {
                    let url = imagesDirectory.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: url)
                }
            }
            items = Array(items.prefix(maxItems))
        }
        saveHistory()
    }
    
    func deleteEntry(id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            let item = items[idx]
            if item.type == .image, let fileName = item.imageFileName {
                let url = imagesDirectory.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: url)
            }
            items.remove(at: idx)
            saveHistory()
        }
    }
    
    func clearHistory() {
        for item in items {
            if item.type == .image, let fileName = item.imageFileName {
                let url = imagesDirectory.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: url)
            }
        }
        items.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.items = decoded
        }
    }
}
