import Foundation

private let defaultSymptomLibrary: [String] = [
    "Fever", "Headache", "Sore throat", "Cough", "Congestion",
    "Runny nose", "Chills", "Fatigue", "Muscle aches", "Nausea"
]

enum HealthEventLoggerError: Error, Equatable {
    case missingMemberSelection
    case invalidTemperature
    case memberNotFound
    case eventNotFound
}

@MainActor
final class HealthEventLoggerViewModel: ObservableObject {
    @Published private(set) var members: [FamilyMember] = []
    let symptomLibrary: [String]

    private let store: any HealthLogStoring
    private let calendar: Calendar
    private let contextMemberId: UUID?

    static let validTemperatureRangeCelsius: ClosedRange<Double> = 30.0...43.0

    init(
        store: any HealthLogStoring,
        memberId: UUID? = nil,
        symptomLibrary: [String] = defaultSymptomLibrary,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.symptomLibrary = symptomLibrary
        self.calendar = calendar
        self.contextMemberId = memberId
        refreshMembers()
    }

    func refreshMembers() {
        members = store
            .loadState()
            .members
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func logEvent(using form: HealthEventForm) throws {
        guard let memberId = form.memberId ?? contextMemberId else {
            throw HealthEventLoggerError.missingMemberSelection
        }

        let memberExists = store.loadState().members.contains(where: { $0.id == memberId })
        guard memberExists else {
            throw HealthEventLoggerError.memberNotFound
        }

        if let reading = form.temperature {
            let celsiusValue = reading.celsiusValue
            guard Self.validTemperatureRangeCelsius.contains(celsiusValue) else {
                throw HealthEventLoggerError.invalidTemperature
            }
        }

        let symptoms = normalizeSymptoms(predefined: form.symptomLabels, custom: form.customSymptoms)

        let event = HealthEvent(
            memberId: memberId,
            recordedAt: trimmedToMinute(form.recordedAt),
            temperature: form.temperature,
            symptoms: symptoms,
            medications: form.medications?.nilIfBlank,
            notes: form.notes?.nilIfBlank
        )

        try store.addEvent(event)
    }

    func updateEvent(id: UUID, using form: HealthEventForm) throws {
        guard let existing = store.loadState().events.first(where: { $0.id == id }) else {
            throw HealthEventLoggerError.eventNotFound
        }

        let targetMemberId = form.memberId ?? existing.memberId
        guard store.loadState().members.contains(where: { $0.id == targetMemberId }) else {
            throw HealthEventLoggerError.memberNotFound
        }

        if let reading = form.temperature {
            let celsiusValue = reading.celsiusValue
            guard Self.validTemperatureRangeCelsius.contains(celsiusValue) else {
                throw HealthEventLoggerError.invalidTemperature
            }
        }

        let symptoms = normalizeSymptoms(predefined: form.symptomLabels, custom: form.customSymptoms)

        let updatedEvent = HealthEvent(
            id: id,
            memberId: targetMemberId,
            recordedAt: trimmedToMinute(form.recordedAt),
            temperature: form.temperature,
            symptoms: symptoms,
            medications: form.medications?.nilIfBlank,
            notes: form.notes?.nilIfBlank
        )

        try store.addEvent(updatedEvent)
    }

    static func requiresTemperature(symptomLabels: [String], customSymptoms: [String]) -> Bool {
        let indicators = ["fever", "temperature", "pyrexia", "chills", "febrile"]
        let normalized = symptomLabels + customSymptoms
        return normalized.contains { label in
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return indicators.contains(where: { trimmed.contains($0) })
        }
    }

    private func normalizeSymptoms(predefined: [String], custom: [String]) -> [Symptom] {
        var seen = Set<String>()

        func makeSymptoms(from labels: [String], isCustom: Bool) -> [Symptom] {
            labels.compactMap { label in
                let normalized = label.trimmed
                guard !normalized.isEmpty else { return nil }
                let key = normalized.lowercased()
                guard seen.insert(key).inserted else { return nil }
                return Symptom(label: normalized, isCustom: isCustom)
            }
        }

        let standard = makeSymptoms(from: predefined, isCustom: false)
        let customSymptoms = makeSymptoms(from: custom, isCustom: true)
        return standard + customSymptoms
    }

    private func trimmedToMinute(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
}
