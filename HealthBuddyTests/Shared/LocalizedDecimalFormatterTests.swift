import XCTest
@testable import HealthBuddy

final class LocalizedDecimalFormatterTests: XCTestCase {
    func testParseHandlesCommaDecimalSeparator() {
        let locale = Locale(identifier: "fr_FR")
        let result = LocalizedDecimalFormatter.parse("37,5", locale: locale)
        XCTAssertEqual(result, 37.5, accuracy: 0.0001)
    }

    func testParseAcceptsPeriodInCommaLocale() {
        let locale = Locale(identifier: "fr_FR")
        let result = LocalizedDecimalFormatter.parse("37.5", locale: locale)
        XCTAssertEqual(result, 37.5, accuracy: 0.0001)
    }

    func testStringUsesLocaleDecimalSeparator() {
        let locale = Locale(identifier: "fr_FR")
        let formatted = LocalizedDecimalFormatter.string(from: 38.4, locale: locale, fractionDigits: 1)
        XCTAssertEqual(formatted, "38,4")
    }
}
