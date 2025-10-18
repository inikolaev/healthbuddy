import Foundation

enum HealthEventLoggerError: Error, Equatable {
    case missingMemberSelection
    case invalidTemperature
    case memberNotFound
}

@MainActor
final class HealthEventLoggerViewModel: ObservableObject {
    @Published private(set) var members: [FamilyMember] = []
    let symptomLibrary: [String]

    private let store: any HealthLogStoring
    private let calendar: Calendar
    private let contextMemberId: UUID?

    static let validTemperatureRangeCelsius: ClosedRange<Double> = 30.0...43.0
    private static let defaultSymptomLibrary: [String] = [
        "Fever", "Headache", "Sore throat", "Cough", "Congestion",
        "Runny nose", "Chills", "Fatigue", "Muscle aches", "Nausea"
    ]

    init(
        store: any HealthLogStoring,
        memberId: UUID? = nil,
        symptomLibrary: [String] = HealthEventLoggerViewModel.defaultSymptomLibrary,
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
