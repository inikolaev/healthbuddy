import Foundation

struct HealthLogState: Codable, Equatable {
    var members: [FamilyMember]
    var events: [HealthEvent]

    init(members: [FamilyMember] = [], events: [HealthEvent] = []) {
        self.members = members
        self.events = events
    }
}
