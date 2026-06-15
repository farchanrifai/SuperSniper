import Foundation
import JavaScriptCore

@MainActor
class MathManager: ObservableObject {
    static let shared = MathManager()
    
    private let jsContext = JSContext()
    
    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 4
        return f
    }()
    
    private let spellOutFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .spellOut
        return f
    }()
    
    private init() {}
    
    struct MathResult: Equatable {
        let expression: String
        let result: Double
        let formattedResult: String
        let spelledOut: String
    }
    
    /// Evaluates a math expression or a conversion. Returns nil if invalid.
    func evaluate(query: String) -> MathResult? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // 1. Try Conversion
        if let conversionResult = ConversionManager.shared.evaluate(query: trimmed, mathEvaluator: { self.evaluatePureMath($0) }) {
            return conversionResult
        }
        
        // 2. Try Pure Math
        if let mathVal = evaluatePureMath(trimmed) {
            let formatted = numberFormatter.string(from: NSNumber(value: mathVal)) ?? "\(mathVal)"
            var spelled = spellOutFormatter.string(from: NSNumber(value: mathVal)) ?? ""
            spelled = spelled.capitalized
            
            return MathResult(
                expression: trimmed,
                result: mathVal,
                formattedResult: formatted,
                spelledOut: spelled
            )
        }
        
        return nil
    }
    
    private func evaluatePureMath(_ trimmed: String) -> Double? {
        // Prevent JS Injection: Only allow numbers, basic operators, and parenthesis
        let allowedCharacterSet = CharacterSet(charactersIn: "0123456789.+-*/^() ")
        if trimmed.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
            return nil
        }
        
        // Prevent pure single numbers from being treated as calculations
        let hasOperators = trimmed.contains(where: { "+-*/^()".contains($0) })
        guard hasOperators else { return nil }
        
        let safeScript = trimmed.replacingOccurrences(of: "^", with: "**")
        
        guard let context = jsContext else { return nil }
        context.exceptionHandler = { _, _ in } // Silently suppress JS errors
        
        let jsValue = context.evaluateScript(safeScript)
        
        guard let value = jsValue, value.isNumber else { return nil }
        let resultDouble = value.toDouble()
        guard resultDouble.isFinite, !resultDouble.isNaN else { return nil }
        
        return resultDouble
    }
}
