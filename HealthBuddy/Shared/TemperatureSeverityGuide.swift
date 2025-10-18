import SwiftUI

struct TemperatureSeverityGuide {
    let severity: TemperatureSeverity
    let title: String
    let message: String
    let color: Color

    static func guide(for severity: TemperatureSeverity) -> TemperatureSeverityGuide {
        switch severity {
        case .tooLow:
            TemperatureSeverityGuide(
                severity: severity,
                title: "Low temperature",
                message: "Below the typical range. Warm the person and seek urgent care if symptoms persist.",
                color: .blue
            )
        case .normal:
            TemperatureSeverityGuide(
                severity: severity,
                title: "Within normal range",
                message: "Keep monitoring symptoms and encourage rest and hydration.",
                color: .green
            )
        case .elevated:
            TemperatureSeverityGuide(
                severity: severity,
                title: "Mild fever",
                message: "Monitor closely. Consider contacting a clinician if it lasts more than 24 hours.",
                color: .yellow
            )
        case .high:
            TemperatureSeverityGuide(
                severity: severity,
                title: "High fever",
                message: "Offer fever reducers if advised and reach out to a doctor if the fever persists.",
                color: .orange
            )
        case .critical:
            TemperatureSeverityGuide(
                severity: severity,
                title: "Very high fever",
                message: "Seek medical attention promptly, especially if other concerning symptoms appear.",
                color: .red
            )
        }
    }

    static func neutral() -> TemperatureSeverityGuide {
        TemperatureSeverityGuide(
            severity: .normal,
            title: "No temperature recorded",
            message: "Recordings without a temperature focus on symptoms and notes.",
            color: .gray.opacity(0.4)
        )
    }
}
