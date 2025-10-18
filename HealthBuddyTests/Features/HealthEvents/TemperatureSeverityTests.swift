import XCTest
@testable import HealthBuddy

final class TemperatureSeverityTests: XCTestCase {
    func testClassifiesHypothermiaInCelsius() {
        let reading = TemperatureReading(value: 34.9, unit: .celsius)
        XCTAssertEqual(reading.severity, .tooLow)
    }

    func testClassifiesNormalInCelsius() {
        let reading = TemperatureReading(value: 36.6, unit: .celsius)
        XCTAssertEqual(reading.severity, .normal)
    }

    func testClassifiesElevatedInCelsius() {
        let reading = TemperatureReading(value: 37.7, unit: .celsius)
        XCTAssertEqual(reading.severity, .elevated)
    }

    func testClassifiesHighInCelsius() {
        let reading = TemperatureReading(value: 38.6, unit: .celsius)
        XCTAssertEqual(reading.severity, .high)
    }

    func testClassifiesCriticalInCelsius() {
        let reading = TemperatureReading(value: 40.1, unit: .celsius)
        XCTAssertEqual(reading.severity, .critical)
    }

    func testClassifiesUsingFahrenheit() {
        let reading = TemperatureReading(value: 103.0, unit: .fahrenheit)
        XCTAssertEqual(reading.severity, .high)
    }
}
