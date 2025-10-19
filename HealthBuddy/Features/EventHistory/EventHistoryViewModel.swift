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
    let notes: String?
}

@MainActor
final class EventHistoryViewModel: ObservableObject {
    @Published private(set) var sections: [EventHistorySection] = []

    private let store: any HealthLogStoring
    private let dateFormatter: DateFormatter
    private let locale: Locale

    init(store: any HealthLogStoring, locale: Locale = .current) {
        self.store = store
        self.locale = locale
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.dateFormatter = formatter
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
        EventHistoryEntryFactory.makeEntry(event: event, member: member, dateFormatter: dateFormatter, locale: locale)
    }
}

enum EventHistoryEntryFactory {
    static func makeEntry(event: HealthEvent, member: FamilyMember, dateFormatter: DateFormatter, locale: Locale) -> EventHistoryEntry {
        let date = event.recordedAt
        return EventHistoryEntry(
            id: event.id,
            recordedAt: date,
            displayDate: dateFormatter.string(from: date),
            temperature: event.temperature,
            severity: event.temperature?.severity,
            summary: buildSummary(for: event, locale: locale),
            symptoms: event.symptoms,
            notes: event.notes
        )
    }

    private static func buildSummary(for event: HealthEvent, locale: Locale) -> String {
        var parts: [String] = []

        let symptomText = event.symptoms.map { $0.label }.joined(separator: ", ")
        if !symptomText.isEmpty {
            parts.append(symptomText)
        }

        if shouldIncludeTemperature(for: event), let temperature = event.temperature {
            parts.append(temperature.formatted(locale: locale))
        }

        return parts.joined(separator: " · ")
    }

    private static func shouldIncludeTemperature(for event: HealthEvent) -> Bool {
        guard event.temperature != nil else { return false }
        let keywords = ["fever", "temperature", "pyrexia", "febrile"]
        return event.symptoms.contains { symptom in
            let label = symptom.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return keywords.contains { keyword in label.contains(keyword) }
        }
    }
}
