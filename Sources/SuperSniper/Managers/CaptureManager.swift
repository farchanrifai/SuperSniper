import AppKit
import Foundation

final class CaptureManager: Sendable {
    static let shared = CaptureManager()
    
    private init() {}
    
    /// Capture a selected area/window interactively.
    func captureInteractive(outputURL: URL, completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        runCaptureProcess(arguments: ["-i", outputURL.path], completion: completion)
    }
    
    /// Capture the entire screen immediately.
    func captureFullScreen(outputURL: URL, completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        runCaptureProcess(arguments: [outputURL.path], completion: completion)
    }
    
    /// Internal process runner for /usr/sbin/screencapture.
    private func runCaptureProcess(arguments: [String], completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = arguments
        
        process.terminationHandler = { proc in
            Task { @MainActor in
                let success = (proc.terminationStatus == 0)
                completion(success)
            }
        }
        
        do {
            try process.run()
        } catch {
            print("Error: Failed to execute screencapture: \(error)")
            Task { @MainActor in
                completion(false)
            }
        }
    }
    
    /// Copy the image at the given URL to the system clipboard.
    func copyToClipboard(imageURL: URL) -> Bool {
        guard let image = NSImage(contentsOf: imageURL) else {
            print("Error: Could not load image from \(imageURL.path) to copy to clipboard.")
            return false
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }
    
    /// Save the captured file to the user's target folder with a clean timestamped name.
    func saveToTargetFolder(tempURL: URL, targetDirectory: URL, prefix: String = "Screenshot") -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let dateString = formatter.string(from: Date())
        let fileName = "\(prefix) \(dateString).png"
        let destinationURL = targetDirectory.appendingPathComponent(fileName)
        
        do {
            // Ensure target directory exists
            try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
            
            // If file exists at destination, delete it first
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: tempURL, to: destinationURL)
            print("Successfully saved capture to: \(destinationURL.path)")
            return destinationURL
        } catch {
            print("Error: Failed to save screenshot to target folder: \(error)")
            return nil
        }
    }
}
