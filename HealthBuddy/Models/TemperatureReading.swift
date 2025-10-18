import Foundation

enum TemperatureUnit: String, Codable, CaseIterable, Equatable {
    case celsius
    case fahrenheit
}

struct TemperatureReading: Codable, Equatable {
    var value: Double
    var unit: TemperatureUnit

    init(value: Double, unit: TemperatureUnit) {
        self.value = value
        self.unit = unit
    }

    func converted(to targetUnit: TemperatureUnit) -> TemperatureReading {
        guard unit != targetUnit else { return self }

        switch (unit, targetUnit) {
        case (.celsius, .fahrenheit):
            return TemperatureReading(value: (value * 9 / 5) + 32, unit: .fahrenheit)
        case (.fahrenheit, .celsius):
            return TemperatureReading(value: (value - 32) * 5 / 9, unit: .celsius)
        default:
            return TemperatureReading(value: value, unit: targetUnit)
        }
    }

    var celsiusValue: Double {
        switch unit {
        case .celsius:
            return value
        case .fahrenheit:
            return (value - 32) * 5 / 9
        }
    }

    var severity: TemperatureSeverity {
        let temperature = celsiusValue
        switch temperature {
        case ..<TemperatureSeverity.hypothermiaThresholdCelsius:
            return .tooLow
        case ..<TemperatureSeverity.elevatedThresholdCelsius:
            return .normal
        case ..<TemperatureSeverity.highThresholdCelsius:
            return .elevated
        case ..<TemperatureSeverity.criticalThresholdCelsius:
            return .high
        default:
            return .critical
        }
    }

    func formatted(decimals: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = decimals
        formatter.locale = Locale.current
        let number = NSNumber(value: value)
        let formattedValue = formatter.string(from: number) ?? String(format: "%0.*f", decimals, value)
        let unitSuffix = unit == .celsius ? "°C" : "°F"
        return "\(formattedValue) \(unitSuffix)"
    }
}

enum TemperatureSeverity: Equatable {
    case tooLow
    case normal
    case elevated
    case high
    case critical

    static let hypothermiaThresholdCelsius: Double = 35.0
    static let elevatedThresholdCelsius: Double = 37.5
    static let highThresholdCelsius: Double = 38.5
    static let criticalThresholdCelsius: Double = 39.5
}
