import Foundation

@MainActor
class ConversionManager: ObservableObject {
    static let shared = ConversionManager()
    
    @Published var currencyRates: [String: Double] = [:]
    private var lastUpdate: Date?
    
    private let ratesKey = "com.farchan.sniper.currencyRates"
    private let dateKey = "com.farchan.sniper.currencyUpdateDate"
    
    private init() {
        loadRates()
        refreshRatesIfNeeded()
    }
    
    private func loadRates() {
        if let dict = UserDefaults.standard.dictionary(forKey: ratesKey) as? [String: Double] {
            self.currencyRates = dict
        }
        if let date = UserDefaults.standard.object(forKey: dateKey) as? Date {
            self.lastUpdate = date
        }
    }
    
    private func refreshRatesIfNeeded() {
        // Refresh if older than 24h or empty
        if currencyRates.isEmpty || lastUpdate == nil || Date().timeIntervalSince(lastUpdate!) > 86400 {
            Task.detached {
                await self.fetchLiveRates()
            }
        }
    }
    
    private func fetchLiveRates() async {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Double] {
                await MainActor.run {
                    var lowercasedRates: [String: Double] = [:]
                    for (k, v) in rates { lowercasedRates[k.lowercased()] = v }
                    self.currencyRates = lowercasedRates
                    self.lastUpdate = Date()
                    UserDefaults.standard.set(lowercasedRates, forKey: self.ratesKey)
                    UserDefaults.standard.set(self.lastUpdate, forKey: self.dateKey)
                    print("Currency rates updated.")
                }
            }
        } catch {
            print("Failed to fetch currency rates: \(error)")
        }
    }
    
    // Parses and evaluates "expr unit1 to unit2"
    func evaluate(query: String, mathEvaluator: (String) -> Double?) -> MathManager.MathResult? {
        let pattern = "^(.*?[0-9\\)\\s])([a-zA-Z]+)\\s*(?:to|in)\\s*([a-zA-Z]+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let nsString = query as NSString
        let results = regex.matches(in: query, range: NSRange(location: 0, length: nsString.length))
        guard let match = results.first, match.numberOfRanges == 4 else { return nil }
        
        let exprStr = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
        let fromUnit = nsString.substring(with: match.range(at: 2)).lowercased()
        let toUnit = nsString.substring(with: match.range(at: 3)).lowercased()
        
        // Evaluate math
        let exprVal = exprStr.isEmpty ? 1.0 : (mathEvaluator(exprStr) ?? 1.0)
        
        // 1. Try Currency
        if let fromRate = currencyRates[fromUnit], let toRate = currencyRates[toUnit] {
            let usdValue = exprVal / fromRate
            let finalValue = usdValue * toRate
            return buildResult(value: finalValue, from: "\(exprStr)\(fromUnit)".uppercased(), toSymbol: toUnit.uppercased())
        }
        
        // 2. Try Units
        if let uFrom = mapUnit(fromUnit), let uTo = mapUnit(toUnit) {
            // Must be same dimension
            if type(of: uFrom) == type(of: uTo) {
                let measurement = Measurement(value: exprVal, unit: uFrom)
                let converted = measurement.converted(to: uTo)
                return buildResult(value: converted.value, from: "\(exprStr)\(fromUnit)", toSymbol: toUnit)
            }
        }
        
        return nil
    }
    
    private func buildResult(value: Double, from: String, toSymbol: String) -> MathManager.MathResult {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        let fullFormatted = "\(formatted) \(toSymbol)"
        
        let spellOutFormatter = NumberFormatter()
        spellOutFormatter.numberStyle = .spellOut
        let spelled = (spellOutFormatter.string(from: NSNumber(value: value)) ?? "").capitalized
        
        return MathManager.MathResult(
            expression: "\(from) to \(toSymbol)",
            result: value,
            formattedResult: fullFormatted,
            spelledOut: "\(spelled) \(toSymbol)"
        )
    }
    
    private func mapUnit(_ str: String) -> Dimension? {
        switch str {
        // Length
        case "m", "meter", "meters": return UnitLength.meters
        case "km", "kilometer", "kilometers": return UnitLength.kilometers
        case "cm", "centimeter", "centimeters": return UnitLength.centimeters
        case "mm", "millimeter", "millimeters": return UnitLength.millimeters
        case "mi", "mile", "miles": return UnitLength.miles
        case "yd", "yard", "yards": return UnitLength.yards
        case "ft", "foot", "feet": return UnitLength.feet
        case "in", "inch", "inches": return UnitLength.inches
        
        // Mass
        case "kg", "kilo", "kilogram", "kilograms": return UnitMass.kilograms
        case "g", "gram", "grams": return UnitMass.grams
        case "mg", "milligram", "milligrams": return UnitMass.milligrams
        case "oz", "ounce", "ounces": return UnitMass.ounces
        case "lb", "lbs", "pound", "pounds": return UnitMass.pounds
        
        // Temperature
        case "c", "celsius": return UnitTemperature.celsius
        case "f", "fahrenheit": return UnitTemperature.fahrenheit
        case "k", "kelvin": return UnitTemperature.kelvin
            
        // Volume
        case "l", "liter", "liters": return UnitVolume.liters
        case "ml", "milliliter", "milliliters": return UnitVolume.milliliters
        case "gal", "gallon", "gallons": return UnitVolume.gallons
        case "qt", "quart", "quarts": return UnitVolume.quarts
        case "pt", "pint", "pints": return UnitVolume.pints
        case "cup", "cups": return UnitVolume.cups
        case "floz", "ozfl": return UnitVolume.fluidOunces
            
        // Speed
        case "kmh": return UnitSpeed.kilometersPerHour
        case "mph": return UnitSpeed.milesPerHour
        case "ms": return UnitSpeed.metersPerSecond
        case "kn", "knot", "knots": return UnitSpeed.knots
            
        default: return nil
        }
    }
}
