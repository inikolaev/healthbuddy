import Foundation

struct Symptom: Identifiable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case customLabel
        case label
        case isCustom
    }

    var id: UUID
    private(set) var kind: SymptomKind?
    private(set) var customLabel: String?

    var label: String {
        if let kind { return kind.localizedName }
        return customLabel ?? ""
    }

    var isCustom: Bool { kind == nil }

    init(id: UUID = UUID(), kind: SymptomKind) {
        self.id = id
        self.kind = kind
        self.customLabel = nil
    }

    init(id: UUID = UUID(), customLabel: String) {
        self.id = id
        self.kind = nil
        let trimmed = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        self.customLabel = trimmed.isEmpty ? nil : trimmed
    }

    @available(*, deprecated, message: "Use init(kind:) or init(customLabel:)")
    init(id: UUID = UUID(), label: String, isCustom: Bool) {
        if isCustom {
            self.init(id: id, customLabel: label)
        } else if let matched = SymptomKind.matching(label: label) {
            self.init(id: id, kind: matched)
        } else {
            self.init(id: id, customLabel: label)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        if let kind {
            try container.encode(kind.rawValue, forKey: .kind)
        } else if let customLabel {
            try container.encode(customLabel, forKey: .customLabel)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

        if let rawKind = try container.decodeIfPresent(String.self, forKey: .kind),
           let kind = SymptomKind(rawValue: rawKind) {
            self.kind = kind
            self.customLabel = nil
            return
        }

        if let custom = try container.decodeIfPresent(String.self, forKey: .customLabel) {
            self.kind = nil
            let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
            self.customLabel = trimmed.isEmpty ? nil : trimmed
            return
        }

        if let legacyLabel = try container.decodeIfPresent(String.self, forKey: .label) {
            let isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
            if !isCustom, let matched = SymptomKind.matching(label: legacyLabel) {
                self.kind = matched
                self.customLabel = nil
            } else {
                self.kind = nil
                let trimmed = legacyLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                self.customLabel = trimmed.isEmpty ? nil : trimmed
            }
            return
        }

        self.kind = nil
        self.customLabel = nil
    }
}
