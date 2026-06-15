import Foundation
import AppKit

@MainActor
class FinderManager {
    static let shared = FinderManager()
    
    private init() {}
    
    /// Fetches the selected files in Finder. If extensions is provided, filters the selection.
    func getSelectedFiles(allowedExtensions: [String]? = nil) -> [URL] {
        let scriptSource = """
        tell application "Finder"
            set theSelection to selection
            set fileList to ""
            repeat with theItem in theSelection
                set fileList to fileList & POSIX path of (theItem as alias) & linefeed
            end repeat
            return fileList
        end tell
        """
        
        guard let script = NSAppleScript(source: scriptSource) else {
            print("Failed to compile AppleScript")
            return []
        }
        
        var errorDict: NSDictionary?
        let result = script.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            print("AppleScript Error: \(error)")
            return []
        }
        
        guard let output = result.stringValue else {
            return []
        }
        
        let paths = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var urls = paths.map { URL(fileURLWithPath: $0) }
        
        if let extensions = allowedExtensions {
            let lowercasedExts = extensions.map { $0.lowercased() }
            urls = urls.filter { lowercasedExts.contains($0.pathExtension.lowercased()) }
        }
        
        return urls
    }
}
