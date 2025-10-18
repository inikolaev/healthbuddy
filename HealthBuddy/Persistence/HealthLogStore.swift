import Foundation

protocol HealthLogStoring: AnyObject {
    func loadState() -> HealthLogState
    @discardableResult func addMember(_ member: FamilyMember) throws -> HealthLogState
    @discardableResult func addEvent(_ event: HealthEvent) throws -> HealthLogState
    func removeMember(id: UUID) throws
    func removeEvent(id: UUID) throws
    func replaceState(_ newState: HealthLogState) throws
}

enum HealthLogStoreError: Error, Equatable {
    case missingMember(UUID)
    case missingEvent(UUID)
}

final class HealthLogStore: HealthLogStoring {
    private let fileURL: URL
    private var state: HealthLogState
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "io.healthbuddy.healthlogstore", qos: .userInitiated)

    init(directory: URL, fileName: String = "health-log.json") {
        self.fileURL = directory.appendingPathComponent(fileName)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        self.decoder = decoder

        if let persisted = try? Self.readState(from: fileURL, decoder: decoder) {
            self.state = persisted
        } else {
            self.state = HealthLogState()
        }
    }

    func loadState() -> HealthLogState {
        queue.sync {
            state
        }
    }

    @discardableResult
    func addMember(_ member: FamilyMember) throws -> HealthLogState {
        try queue.sync {
            if let index = state.members.firstIndex(where: { $0.id == member.id }) {
                state.members[index] = member
            } else {
                state.members.append(member)
            }
            try persist()
            return state
        }
    }

    @discardableResult
    func addEvent(_ event: HealthEvent) throws -> HealthLogState {
        try queue.sync {
            guard state.members.contains(where: { $0.id == event.memberId }) else {
                throw HealthLogStoreError.missingMember(event.memberId)
            }

            if let index = state.events.firstIndex(where: { $0.id == event.id }) {
                state.events[index] = event
            } else {
                state.events.append(event)
            }
            try persist()
            return state
        }
    }

    func removeMember(id: UUID) throws {
        try queue.sync {
            state.members.removeAll { $0.id == id }
            state.events.removeAll { $0.memberId == id }
            try persist()
        }
    }

    func removeEvent(id: UUID) throws {
        try queue.sync {
            guard let index = state.events.firstIndex(where: { $0.id == id }) else {
                throw HealthLogStoreError.missingEvent(id)
            }
            state.events.remove(at: index)
            try persist()
        }
    }

    func replaceState(_ newState: HealthLogState) throws {
        try queue.sync {
            state = newState
            try persist()
        }
    }

    private func persist() throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func readState(from url: URL, decoder: JSONDecoder) throws -> HealthLogState? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(HealthLogState.self, from: data)
    }
}
