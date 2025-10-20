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
                title: NSLocalizedString("Low temperature", comment: "Temperature severity title for low temperature"),
                message: NSLocalizedString("Below the typical range. Warm the person and seek urgent care if symptoms persist.", comment: "Guidance for low temperature"),
                color: .blue
            )
        case .normal:
            TemperatureSeverityGuide(
                severity: severity,
                title: NSLocalizedString("Within normal range", comment: "Temperature severity title for normal temperature"),
                message: NSLocalizedString("Keep monitoring symptoms and encourage rest and hydration.", comment: "Guidance for normal temperature"),
                color: .green
            )
        case .elevated:
            TemperatureSeverityGuide(
                severity: severity,
                title: NSLocalizedString("Mild fever", comment: "Temperature severity title for mild fever"),
                message: NSLocalizedString("Monitor closely. Consider contacting a clinician if it lasts more than 24 hours.", comment: "Guidance for mild fever"),
                color: .yellow
            )
        case .high:
            TemperatureSeverityGuide(
                severity: severity,
                title: NSLocalizedString("High fever", comment: "Temperature severity title for high fever"),
                message: NSLocalizedString("Offer fever reducers if advised and reach out to a doctor if the fever persists.", comment: "Guidance for high fever"),
                color: .orange
            )
        case .critical:
            TemperatureSeverityGuide(
                severity: severity,
                title: NSLocalizedString("Very high fever", comment: "Temperature severity title for very high fever"),
                message: NSLocalizedString("Seek medical attention promptly, especially if other concerning symptoms appear.", comment: "Guidance for very high fever"),
                color: .red
            )
        }
    }

    static func neutral() -> TemperatureSeverityGuide {
        TemperatureSeverityGuide(
            severity: .normal,
            title: NSLocalizedString("No temperature recorded", comment: "Temperature severity title when no temperature recorded"),
            message: NSLocalizedString("Recordings without a temperature focus on symptoms and notes.", comment: "Guidance when no temperature recorded"),
            color: .gray.opacity(0.4)
        )
    }
}
