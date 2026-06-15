import Foundation
import PDFKit

enum PDFError: Error {
    case invalidDocument
    case unlockFailed
    case saveFailed
}

@MainActor
class PDFManager {
    static let shared = PDFManager()
    
    private init() {}
    
    /// Merges multiple PDFs into a single PDF
    func mergePDFs(urls: [URL], outputName: String? = nil) throws -> URL {
        let mergedDocument = PDFDocument()
        
        for url in urls {
            guard let document = PDFDocument(url: url) else { continue }
            let pageCount = document.pageCount
            for i in 0..<pageCount {
                if let page = document.page(at: i) {
                    mergedDocument.insert(page, at: mergedDocument.pageCount)
                }
            }
        }
        
        let outputURL = createOutputURL(prefix: "Merged", customName: outputName)
        if mergedDocument.write(to: outputURL) {
            return outputURL
        } else {
            throw PDFError.saveFailed
        }
    }
    
    /// Splits a PDF into multiple parts based on page count or MB size
    func splitPDF(url: URL, arg: String) throws -> [URL] {
        guard let document = PDFDocument(url: url) else { throw PDFError.invalidDocument }
        let totalPages = document.pageCount
        guard totalPages > 0 else { return [] }
        
        let cleanArg = arg.trimmingCharacters(in: .whitespaces).lowercased()
        
        if cleanArg.hasSuffix("mb") {
            // Split by rough file size
            let mbString = cleanArg.replacingOccurrences(of: "mb", with: "")
            guard let maxMB = Double(mbString) else { return [] }
            let maxBytes = maxMB * 1024 * 1024
            
            // Heuristic approach: Keep adding pages until the output data exceeds maxBytes
            var outputURLs: [URL] = []
            var currentDoc = PDFDocument()
            var partNum = 1
            
            for i in 0..<totalPages {
                if let page = document.page(at: i) {
                    currentDoc.insert(page, at: currentDoc.pageCount)
                    
                    // Check size
                    if let data = currentDoc.dataRepresentation(), Double(data.count) >= maxBytes {
                        // Save current
                        let outURL = createOutputURL(prefix: "Split_Part\(partNum)", customName: nil)
                        currentDoc.write(to: outURL)
                        outputURLs.append(outURL)
                        
                        // Start new
                        currentDoc = PDFDocument()
                        partNum += 1
                    }
                }
            }
            
            // Save remainder
            if currentDoc.pageCount > 0 {
                let outURL = createOutputURL(prefix: "Split_Part\(partNum)", customName: nil)
                currentDoc.write(to: outURL)
                outputURLs.append(outURL)
            }
            
            return outputURLs
            
        } else {
            // Split by page count
            guard let pageLimit = Int(cleanArg), pageLimit > 0 else { return [] }
            var outputURLs: [URL] = []
            var currentDoc = PDFDocument()
            var partNum = 1
            
            for i in 0..<totalPages {
                if let page = document.page(at: i) {
                    currentDoc.insert(page, at: currentDoc.pageCount)
                    
                    if currentDoc.pageCount == pageLimit {
                        let outURL = createOutputURL(prefix: "Split_Part\(partNum)", customName: nil)
                        currentDoc.write(to: outURL)
                        outputURLs.append(outURL)
                        currentDoc = PDFDocument()
                        partNum += 1
                    }
                }
            }
            
            // Save remainder
            if currentDoc.pageCount > 0 {
                let outURL = createOutputURL(prefix: "Split_Part\(partNum)", customName: nil)
                currentDoc.write(to: outURL)
                outputURLs.append(outURL)
            }
            
            return outputURLs
        }
    }
    
    /// Protects a PDF with a password
    func protectPDF(url: URL, password: String) throws -> URL {
        guard let document = PDFDocument(url: url) else { throw PDFError.invalidDocument }
        
        let outputURL = createOutputURL(prefix: "Protected", customName: nil)
        
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]
        
        if document.write(to: outputURL, withOptions: options) {
            return outputURL
        } else {
            throw PDFError.saveFailed
        }
    }
    
    /// Unlocks a PDF and saves it without a password
    func unlockPDF(url: URL, password: String) throws -> URL {
        guard let document = PDFDocument(url: url) else { throw PDFError.invalidDocument }
        
        if document.isEncrypted {
            if !document.unlock(withPassword: password) {
                throw PDFError.unlockFailed
            }
        }
        
        let outputURL = createOutputURL(prefix: "Unlocked", customName: nil)
        if document.write(to: outputURL) {
            return outputURL
        } else {
            throw PDFError.saveFailed
        }
    }
    
    // MARK: - Helpers
    
    private func createOutputURL(prefix: String, customName: String?) -> URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        
        if let name = customName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            let cleanName = name.hasSuffix(".pdf") ? name : "\(name).pdf"
            return desktop.appendingPathComponent(cleanName)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return desktop.appendingPathComponent("\(prefix)_\(timestamp).pdf")
    }
}
