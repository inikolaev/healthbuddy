import Foundation

struct HealthEventForm {
    var memberId: UUID?
    var recordedAt: Date
    var temperature: TemperatureReading?
    var symptomLabels: [String]
    var customSymptoms: [String]
    var medications: String?
    var notes: String?

    init(
        memberId: UUID? = nil,
        recordedAt: Date = Date(),
        temperature: TemperatureReading? = nil,
        symptomLabels: [String] = [],
        customSymptoms: [String] = [],
        medications: String? = nil,
        notes: String? = nil
    ) {
        self.memberId = memberId
        self.recordedAt = recordedAt
        self.temperature = temperature
        self.symptomLabels = symptomLabels
        self.customSymptoms = customSymptoms
        self.medications = medications
        self.notes = notes
    }
}
