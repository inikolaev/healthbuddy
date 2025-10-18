import Foundation

struct FamilyMember: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var avatarAssetName: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        avatarAssetName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.avatarAssetName = avatarAssetName
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
