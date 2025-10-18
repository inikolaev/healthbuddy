import Foundation

struct Symptom: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    var isCustom: Bool

    init(id: UUID = UUID(), label: String, isCustom: Bool) {
        self.id = id
        self.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isCustom = isCustom
    }
}
