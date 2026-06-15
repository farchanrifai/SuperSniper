import Foundation
import AppKit

struct LauncherItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String?
    let url: URL?
    let icon: NSImage?
    let type: ItemType
    
    enum ItemType {
        case application
        case tool
        case calculatorHistory
        case file
    }
}

@MainActor
class AppSearchManager: ObservableObject {
    static let shared = AppSearchManager()
    
    @Published var installedApps: [LauncherItem] = []
    
    private init() {
        Task {
            await refreshApps()
        }
    }
    
    func refreshApps() async {
        let directoriesToScan = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first
        ].compactMap { $0 }
        
        // Background scan
        let items = await Task.detached(priority: .userInitiated) { () -> [LauncherItem] in
            var foundApps: [LauncherItem] = []
            let fileManager = FileManager.default
            
            for directory in directoriesToScan {
                guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isApplicationKey], options: [.skipsPackageDescendants, .skipsHiddenFiles]) else {
                    continue
                }
                
                while let url = enumerator.nextObject() as? URL {
                    if url.pathExtension == "app" {
                        let name = url.deletingPathExtension().lastPathComponent
                        
                        let icon = NSWorkspace.shared.icon(forFile: url.path)
                        icon.size = NSSize(width: 32, height: 32)
                        
                        let item = LauncherItem(
                            name: name,
                            subtitle: "Application",
                            url: url,
                            icon: icon,
                            type: .application
                        )
                        foundApps.append(item)
                    }
                }
            }
            
            // Deduplicate by name and sort alphabetically
            var uniqueApps = [String: LauncherItem]()
            for app in foundApps {
                if uniqueApps[app.name] == nil {
                    uniqueApps[app.name] = app
                }
            }
            return uniqueApps.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }.value
        
        self.installedApps = items
    }
    
    func search(query: String) -> [LauncherItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return installedApps
        }
        
        // Simple fuzzy search (case insensitive)
        return installedApps.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}
