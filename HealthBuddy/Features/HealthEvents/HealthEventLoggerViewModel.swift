import Foundation

private let defaultSymptomLibrary: [SymptomKind] = SymptomKind.allCases

enum HealthEventLoggerError: Error, Equatable {
    case missingMemberSelection
    case invalidTemperature
    case memberNotFound
    case eventNotFound
}

@MainActor
final class HealthEventLoggerViewModel: ObservableObject {
    @Published private(set) var members: [FamilyMember] = []
    let symptomLibrary: [SymptomKind]

    private let store: any HealthLogStoring
    private let calendar: Calendar
    private let contextMemberId: UUID?

    static let validTemperatureRangeCelsius: ClosedRange<Double> = 30.0...43.0

    init(
        store: any HealthLogStoring,
        memberId: UUID? = nil,
        symptomLibrary: [SymptomKind] = defaultSymptomLibrary,
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

        let symptoms = normalizeSymptoms(predefined: form.symptomKinds, custom: form.customSymptoms)

        let event = HealthEvent(
            memberId: memberId,
            recordedAt: trimmedToMinute(form.recordedAt),
            temperature: form.temperature,
            symptoms: symptoms,
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

        let symptoms = normalizeSymptoms(predefined: form.symptomKinds, custom: form.customSymptoms)

        let updatedEvent = HealthEvent(
            id: id,
            memberId: targetMemberId,
            recordedAt: trimmedToMinute(form.recordedAt),
            temperature: form.temperature,
            symptoms: symptoms,
            notes: form.notes?.nilIfBlank
        )

        try store.addEvent(updatedEvent)
    }

    func deleteEvent(id: UUID) throws {
        guard let event = store.loadState().events.first(where: { $0.id == id }) else {
            throw HealthEventLoggerError.eventNotFound
        }

        if let contextMemberId, event.memberId != contextMemberId {
            throw HealthEventLoggerError.memberNotFound
        }

        do {
            try store.removeEvent(id: id)
        } catch {
            throw HealthEventLoggerError.eventNotFound
        }
    }

    static func requiresTemperature(symptomKinds: [SymptomKind], customSymptoms: [String]) -> Bool {
        if symptomKinds.contains(where: { $0 == .fever || $0 == .chills }) {
            return true
        }

        let indicators = ["fever", "temperature", "pyrexia", "chills", "febrile"]
        return customSymptoms.contains { label in
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return indicators.contains(where: { trimmed.contains($0) })
        }
    }

    private func normalizeSymptoms(predefined kinds: [SymptomKind], custom: [String]) -> [Symptom] {
        var seenKinds = Set<SymptomKind>()
        var symptoms: [Symptom] = []

        for kind in kinds {
            guard seenKinds.insert(kind).inserted else { continue }
            symptoms.append(Symptom(kind: kind))
        }

        var seenCustom = Set<String>()
        for label in custom {
            let normalized = label.trimmed
            guard !normalized.isEmpty else { continue }
            if let match = SymptomKind.matching(label: normalized) {
                if seenKinds.insert(match).inserted {
                    symptoms.append(Symptom(kind: match))
                }
                continue
            }
            let key = normalized.lowercased()
            guard seenCustom.insert(key).inserted else { continue }
            symptoms.append(Symptom(customLabel: normalized))
        }

        return symptoms
    }

    private func trimmedToMinute(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
}
