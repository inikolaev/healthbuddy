import Foundation

struct HealthEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var memberId: UUID
    var recordedAt: Date
    var temperature: TemperatureReading
    var symptoms: [Symptom]
    var medications: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        memberId: UUID,
        recordedAt: Date,
        temperature: TemperatureReading,
        symptoms: [Symptom],
        medications: String?,
        notes: String?
    ) {
        self.id = id
        self.memberId = memberId
        self.recordedAt = recordedAt
        self.temperature = temperature
        self.symptoms = symptoms
        self.medications = medications?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
