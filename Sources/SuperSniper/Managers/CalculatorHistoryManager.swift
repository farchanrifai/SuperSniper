import Foundation

struct CalculatorEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let expression: String
    let result: Double
    let formattedResult: String
    let timestamp: Date
}

@MainActor
class CalculatorHistoryManager: ObservableObject {
    static let shared = CalculatorHistoryManager()
    
    @Published var history: [CalculatorEntry] = []
    
    private let storageKey = "com.farchan.sniper.calculatorHistory"
    
    private init() {
        loadHistory()
    }
    
    func addEntry(expression: String, result: Double, formattedResult: String) {
        // Prevent exact duplicates at the top
        if let first = history.first, first.expression == expression {
            return
        }
        
        let entry = CalculatorEntry(
            id: UUID(),
            expression: expression,
            result: result,
            formattedResult: formattedResult,
            timestamp: Date()
        )
        
        history.insert(entry, at: 0)
        
        // Keep last 100 entries
        if history.count > 100 {
            history.removeLast()
        }
        
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([CalculatorEntry].self, from: data) {
            history = saved
        }
    }
}
