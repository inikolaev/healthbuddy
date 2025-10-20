import Foundation

struct HealthLogState: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case members
        case events
    }

    var schemaVersion: Int
    var members: [FamilyMember]
    var events: [HealthEvent]

    init(
        schemaVersion: Int = HealthLogSchemaVersion.current.rawValue,
        members: [FamilyMember] = [],
        events: [HealthEvent] = []
    ) {
        self.schemaVersion = schemaVersion
        self.members = members
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
            ?? HealthLogSchemaVersion.legacy.rawValue
        self.members = try container.decodeIfPresent([FamilyMember].self, forKey: .members) ?? []
        self.events = try container.decodeIfPresent([HealthEvent].self, forKey: .events) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(members, forKey: .members)
        try container.encode(events, forKey: .events)
    }
}
