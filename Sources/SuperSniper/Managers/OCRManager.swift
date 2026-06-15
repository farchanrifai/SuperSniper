@preconcurrency import Vision
import AppKit

final class OCRManager: Sendable {
    static let shared = OCRManager()
    
    private init() {}
    
    /// Recognizes text in an NSImage.
    func recognizeText(from image: NSImage, completion: @escaping @MainActor @Sendable (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            Task { @MainActor in
                completion(.failure(NSError(domain: "OCRManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage from NSImage"])))
            }
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        performOCR(with: handler, completion: completion)
    }
    
    /// Recognizes text in an image file at the specified URL.
    func recognizeText(from url: URL, completion: @escaping @MainActor @Sendable (Result<String, Error>) -> Void) {
        let handler = VNImageRequestHandler(url: url, options: [:])
        performOCR(with: handler, completion: completion)
    }
    
    /// Internal helper to execute VNRecognizeTextRequest.
    private func performOCR(with handler: VNImageRequestHandler, completion: @escaping @MainActor @Sendable (Result<String, Error>) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                Task { @MainActor in
                    completion(.failure(error))
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                Task { @MainActor in
                    completion(.success(""))
                }
                return
            }
            
            // Extract the top candidate string from each observation
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            Task { @MainActor in
                completion(.success(fullText))
            }
        }
        
        // Configure for highest accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Execute request asynchronously on a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                Task { @MainActor in
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Async/Await wrapper for OCR on NSImage
    func recognizeText(from image: NSImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            recognizeText(from: image) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Async/Await wrapper for OCR on URL
    func recognizeText(from url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            recognizeText(from: url) { result in
                continuation.resume(with: result)
            }
        }
    }
}

