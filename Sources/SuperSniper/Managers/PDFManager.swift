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
    func mergePDFs(urls: [URL]) throws -> URL {
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
        
        let outputURL = createOutputURL(prefix: "Merged")
        if mergedDocument.write(to: outputURL) {
            return outputURL
        } else {
            throw PDFError.saveFailed
        }
    }
    
    /// Splits a PDF into two documents after the specified page index (0-indexed)
    func splitPDF(url: URL, afterPage index: Int) throws -> (URL, URL) {
        guard let document = PDFDocument(url: url) else { throw PDFError.invalidDocument }
        
        let doc1 = PDFDocument()
        let doc2 = PDFDocument()
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                if i <= index {
                    doc1.insert(page, at: doc1.pageCount)
                } else {
                    doc2.insert(page, at: doc2.pageCount)
                }
            }
        }
        
        let out1 = createOutputURL(prefix: "Split_Part1")
        let out2 = createOutputURL(prefix: "Split_Part2")
        
        if doc1.write(to: out1) && doc2.write(to: out2) {
            return (out1, out2)
        } else {
            throw PDFError.saveFailed
        }
    }
    
    /// Protects a PDF with a password
    func protectPDF(url: URL, password: String) throws -> URL {
        guard let document = PDFDocument(url: url) else { throw PDFError.invalidDocument }
        
        let outputURL = createOutputURL(prefix: "Protected")
        
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
        
        let outputURL = createOutputURL(prefix: "Unlocked")
        if document.write(to: outputURL) {
            return outputURL
        } else {
            throw PDFError.saveFailed
        }
    }
    
    // MARK: - Helpers
    
    private func createOutputURL(prefix: String) -> URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return desktop.appendingPathComponent("\(prefix)_\(timestamp).pdf")
    }
}
