import Foundation

struct HistoryItem: Codable, Identifiable, Hashable {
    var id = UUID()
    let text: String
    let timestamp: Date
}

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var items: [HistoryItem] = []
    
    private let maxItems = 20
    private let userDefaultsKey = "com.farchan.sniper.ocrHistory"
    
    private init() {
        loadHistory()
    }
    
    /// Add a new text snippet to the history list.
    func addEntry(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Remove duplicate entry if it exists to bubble it up to the top
        items.removeAll(where: { $0.text == trimmed })
        
        let newItem = HistoryItem(text: trimmed, timestamp: Date())
        items.insert(newItem, at: 0)
        
        // Enforce maximum history capacity
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        saveHistory()
    }
    
    /// Delete a single entry from history.
    func deleteEntry(id: UUID) {
        items.removeAll(where: { $0.id == id })
        saveHistory()
    }
    
    /// Clear all entries from history.
    func clearHistory() {
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
