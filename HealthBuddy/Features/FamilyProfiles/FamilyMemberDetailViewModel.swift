import Foundation

@MainActor
final class FamilyMemberDetailViewModel: ObservableObject {
    @Published private(set) var member: FamilyMember
    @Published private(set) var recentEntries: [EventHistoryEntry] = []

    private let store: any HealthLogStoring
    private let memberId: UUID
    private let pageSize: Int
    private var currentLimit: Int
    private let dateFormatter: DateFormatter
    private let calendar: Calendar
    private let locale: Locale

    init(
        store: any HealthLogStoring,
        memberId: UUID,
        historyLimit: Int = 20,
        locale: Locale = .current,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.memberId = memberId
        self.pageSize = historyLimit
        self.currentLimit = historyLimit
        self.calendar = calendar
        self.locale = locale
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.dateFormatter = formatter

        if let existing = store.loadState().members.first(where: { $0.id == memberId }) {
            self.member = existing
        } else {
            self.member = FamilyMember(id: memberId, name: "Unknown")
        }

        refresh()
    }

    func refresh() {
        let state = store.loadState()
        if let updatedMember = state.members.first(where: { $0.id == memberId }) {
            member = updatedMember
        }

        recentEntries = entries(limit: currentLimit, from: state.events)
    }

    func updateMember(name: String, notes: String?) throws {
        let trimmedName = name.trimmed
        guard !trimmedName.isEmpty else {
            throw FamilyProfilesError.emptyName
        }

        var updated = member
        updated.name = trimmedName
        updated.notes = notes?.nilIfBlank
        try store.addMember(updated)
        refresh()
    }

    func loadMoreIfNeeded(for entry: EventHistoryEntry) {
        guard let last = recentEntries.last, last.id == entry.id else { return }
        let allEvents = store.loadState().events.filter { $0.memberId == memberId }
        guard recentEntries.count < allEvents.count else { return }
        currentLimit = min(currentLimit + pageSize, allEvents.count)
        recentEntries = entries(limit: currentLimit, from: allEvents)
    }

    private func entries(limit: Int, from events: [HealthEvent]) -> [EventHistoryEntry] {
        events
            .filter { $0.memberId == memberId }
            .sorted { $0.recordedAt > $1.recordedAt }
            .prefix(limit)
            .map { EventHistoryEntryFactory.makeEntry(event: $0, member: member, dateFormatter: dateFormatter, locale: locale) }
    }
}
