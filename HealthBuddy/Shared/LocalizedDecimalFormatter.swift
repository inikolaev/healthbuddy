import Foundation

enum LocalizedDecimalFormatter {
    static func parse(_ text: String, locale: Locale = .current) -> Double? {
        let sanitized = sanitize(text)
        guard !sanitized.isEmpty else { return nil }

        let formatter = makeFormatter(locale: locale)
        if let number = formatter.number(from: sanitized) {
            return number.doubleValue
        }

        let alternateSeparator = locale.decimalSeparator == "," ? "." : ","
        if sanitized.contains(alternateSeparator) {
            let decimalSeparator = formatter.decimalSeparator ?? locale.decimalSeparator ?? "."
            let replaced = sanitized.replacingOccurrences(of: alternateSeparator, with: decimalSeparator)
            if let number = formatter.number(from: replaced) {
                return number.doubleValue
            }
        }

        let fallback = sanitized.replacingOccurrences(of: ",", with: ".")
        return Double(fallback)
    }

    static func string(from value: Double, locale: Locale = .current, fractionDigits: Int = 1) -> String {
        let formatter = makeFormatter(locale: locale)
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
    }

    private static func makeFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }

    private static func sanitize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
