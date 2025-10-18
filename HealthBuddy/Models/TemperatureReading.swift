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
}
