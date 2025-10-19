import Foundation

struct HealthEventForm {
    var memberId: UUID?
    var recordedAt: Date
    var temperature: TemperatureReading?
    var symptomLabels: [String]
    var customSymptoms: [String]
    var notes: String?

    init(
        memberId: UUID? = nil,
        recordedAt: Date = Date(),
        temperature: TemperatureReading? = nil,
        symptomLabels: [String] = [],
        customSymptoms: [String] = [],
        notes: String? = nil
    ) {
        self.memberId = memberId
        self.recordedAt = recordedAt
        self.temperature = temperature
        self.symptomLabels = symptomLabels
        self.customSymptoms = customSymptoms
        self.notes = notes
    }

    init(event: HealthEvent) {
        self.memberId = event.memberId
        self.recordedAt = event.recordedAt
        self.temperature = event.temperature
        self.symptomLabels = event.symptoms.filter { !$0.isCustom }.map { $0.label }
        self.customSymptoms = event.symptoms.filter { $0.isCustom }.map { $0.label }
        self.notes = event.notes
    }
}
