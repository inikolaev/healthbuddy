import Foundation

@MainActor
final class FamilyMemberDetailViewModel: ObservableObject {
    @Published private(set) var member: FamilyMember
    @Published private(set) var recentEntries: [EventHistoryEntry] = []

    private let store: any HealthLogStoring
    private let memberId: UUID
    private let historyLimit: Int
    private let dateFormatter: DateFormatter
    private let calendar: Calendar

    init(
        store: any HealthLogStoring,
        memberId: UUID,
        historyLimit: Int = 3,
        locale: Locale = .current,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.memberId = memberId
        self.historyLimit = historyLimit
        self.calendar = calendar
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

        let entries = state.events
            .filter { $0.memberId == memberId }
            .sorted { $0.recordedAt > $1.recordedAt }
            .prefix(historyLimit)
            .map { EventHistoryEntryFactory.makeEntry(event: $0, member: member, dateFormatter: dateFormatter) }

        recentEntries = Array(entries)
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
}
