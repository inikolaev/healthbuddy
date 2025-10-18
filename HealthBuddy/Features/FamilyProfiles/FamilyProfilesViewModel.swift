import Foundation

enum FamilyProfilesError: Error, Equatable {
    case emptyName
}

@MainActor
final class FamilyProfilesViewModel: ObservableObject {
    @Published private(set) var members: [FamilyMember] = []

    private let store: any HealthLogStoring

    init(store: any HealthLogStoring) {
        self.store = store
        refresh()
    }

    func refresh() {
        members = store
            .loadState()
            .members
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func addMember(name: String, notes: String?, avatarAssetName: String? = nil) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FamilyProfilesError.emptyName
        }

        let member = FamilyMember(name: trimmedName, avatarAssetName: avatarAssetName, notes: notes)
        try store.addMember(member)
        refresh()
    }

    func updateMember(_ member: FamilyMember) throws {
        let trimmedName = member.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FamilyProfilesError.emptyName
        }

        var updated = member
        updated.name = trimmedName
        try store.addMember(updated)
        refresh()
    }

    func deleteMembers(at offsets: IndexSet) throws {
        let idsToDelete = offsets.compactMap { index -> UUID? in
            guard members.indices.contains(index) else { return nil }
            return members[index].id
        }

        for id in idsToDelete {
            try store.removeMember(id: id)
        }

        refresh()
    }
}
