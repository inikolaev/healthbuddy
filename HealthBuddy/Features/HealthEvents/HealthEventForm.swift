import Foundation

struct HealthEventForm {
    var memberId: UUID?
    var recordedAt: Date
    var temperature: TemperatureReading?
    var symptomKinds: [SymptomKind]
    var customSymptoms: [String]
    var notes: String?

    init(
        memberId: UUID? = nil,
        recordedAt: Date = Date(),
        temperature: TemperatureReading? = nil,
        symptomKinds: [SymptomKind] = [],
        customSymptoms: [String] = [],
        notes: String? = nil
    ) {
        self.memberId = memberId
        self.recordedAt = recordedAt
        self.temperature = temperature
        self.symptomKinds = symptomKinds
        self.customSymptoms = customSymptoms
        self.notes = notes
    }

    init(event: HealthEvent) {
        self.memberId = event.memberId
        self.recordedAt = event.recordedAt
        self.temperature = event.temperature
        self.symptomKinds = event.symptoms.compactMap { $0.kind }
        self.customSymptoms = event.symptoms
            .filter { $0.isCustom }
            .compactMap { $0.customLabel }
        self.notes = event.notes
    }
}
