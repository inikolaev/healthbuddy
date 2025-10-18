import Foundation

struct EventHistorySection: Identifiable, Equatable {
    let member: FamilyMember
    var entries: [EventHistoryEntry]

    var id: UUID { member.id }
}

struct EventHistoryEntry: Identifiable, Equatable {
    let id: UUID
    let recordedAt: Date
    let displayDate: String
    let temperature: TemperatureReading?
    let severity: TemperatureSeverity?
    let summary: String
    let symptoms: [Symptom]
    let medications: String?
    let notes: String?

    var memberSummary: String {
        summary
    }
}

@MainActor
final class EventHistoryViewModel: ObservableObject {
    @Published private(set) var sections: [EventHistorySection] = []

    private let store: any HealthLogStoring
    private let dateFormatter: DateFormatter

    init(store: any HealthLogStoring, locale: Locale = .current) {
        self.store = store
        self.dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        refresh()
    }

    func refresh() {
        let state = store.loadState()
        let membersById = Dictionary(uniqueKeysWithValues: state.members.map { ($0.id, $0) })

        var grouped: [UUID: [EventHistoryEntry]] = [:]

        for event in state.events {
            guard let member = membersById[event.memberId] else { continue }
            let entry = makeEntry(for: event, member: member)
            grouped[member.id, default: []].append(entry)
        }

        sections = state.members.map { member in
            let entries = (grouped[member.id] ?? [])
                .sorted(by: { $0.recordedAt > $1.recordedAt })
            return EventHistorySection(member: member, entries: entries)
        }
        .filter { !$0.entries.isEmpty }
        .sorted { $0.member.name.localizedCaseInsensitiveCompare($1.member.name) == .orderedAscending }
    }

    private func makeEntry(for event: HealthEvent, member: FamilyMember) -> EventHistoryEntry {
        EventHistoryEntryFactory.makeEntry(event: event, member: member, dateFormatter: dateFormatter)
    }
}

enum EventHistoryEntryFactory {
    static func makeEntry(event: HealthEvent, member: FamilyMember, dateFormatter: DateFormatter) -> EventHistoryEntry {
        let date = event.recordedAt
        return EventHistoryEntry(
            id: event.id,
            recordedAt: date,
            displayDate: dateFormatter.string(from: date),
            temperature: event.temperature,
            severity: event.temperature?.severity,
            summary: buildSummary(for: event),
            symptoms: event.symptoms,
            medications: event.medications,
            notes: event.notes
        )
    }

    private static func buildSummary(for event: HealthEvent) -> String {
        var parts: [String] = []

        let symptomText = event.symptoms.map { $0.label }.joined(separator: ", ")
        if !symptomText.isEmpty {
            parts.append(symptomText)
        }

        if let temperature = event.temperature {
            parts.append(temperature.formatted())
        }

        if let medications = event.medications?.nilIfBlank {
            parts.append(medications)
        }

        return parts.joined(separator: " · ")
    }
}
