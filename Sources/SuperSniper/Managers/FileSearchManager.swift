import Foundation
import AppKit

@MainActor
class FileSearchManager: ObservableObject {
    static let shared = FileSearchManager()
    
    @Published var searchResults: [LauncherItem] = []
    
    private var query: NSMetadataQuery?
    
    private init() {}
    
    func search(for term: String) {
        query?.stop()
        query = nil
        searchResults = []
        
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return }
        
        let newQuery = NSMetadataQuery()
        
        // Search for file name matches. We use CONTAINS[cd] for case-insensitive and diacritic-insensitive search.
        newQuery.predicate = NSPredicate(format: "kMDItemDisplayName CONTAINS[cd] %@", trimmed)
        
        // Scope to user's home directory and local computer
        newQuery.searchScopes = [NSMetadataQueryUserHomeScope, NSMetadataQueryLocalComputerScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(queryDidUpdate), name: .NSMetadataQueryDidUpdate, object: newQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(queryDidFinish), name: .NSMetadataQueryDidFinishGathering, object: newQuery)
        
        self.query = newQuery
        newQuery.start()
    }
    
    @objc private func queryDidUpdate(_ notification: Notification) {
        processResults()
    }
    
    @objc private func queryDidFinish(_ notification: Notification) {
        processResults()
    }
    
    private func processResults() {
        guard let query = query else { return }
        query.disableUpdates()
        
        var results: [LauncherItem] = []
        
        // Limit to top 20 items to keep the UI snappy
        let maxResults = min(query.resultCount, 20)
        
        for i in 0..<maxResults {
            guard let item = query.result(at: i) as? NSMetadataItem else { continue }
            guard let path = item.value(forAttribute: NSMetadataItemPathKey as String) as? String else { continue }
            
            let url = URL(fileURLWithPath: path)
            
            // Skip applications since AppSearchManager already handles them
            if url.pathExtension.lowercased() == "app" { continue }
            
            let name = item.value(forAttribute: NSMetadataItemDisplayNameKey as String) as? String ?? url.lastPathComponent
            
            // Generate icon
            let icon = NSWorkspace.shared.icon(forFile: path)
            icon.size = NSSize(width: 32, height: 32)
            
            results.append(LauncherItem(name: name, subtitle: path, url: url, icon: icon, type: .file))
        }
        
        self.searchResults = results
        
        query.enableUpdates()
    }
}
