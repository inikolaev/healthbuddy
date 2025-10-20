import XCTest
@testable import HealthBuddy

final class HealthLogMigrationTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
    }

    func testMigrationFromLegacyFormatUpgradesSchemaAndSymptoms() throws {
        struct LegacySymptom: Codable {
            var id: UUID
            var label: String
            var isCustom: Bool
        }

        struct LegacyEvent: Codable {
            var id: UUID
            var memberId: UUID
            var recordedAt: Date
            var temperature: TemperatureReading?
            var symptoms: [LegacySymptom]
            var notes: String?
        }

        struct LegacyHealthLogState: Codable {
            var members: [FamilyMember]
            var events: [LegacyEvent]
        }

        let member = FamilyMember(id: UUID(), name: "Jordan")
        let legacySymptom = LegacySymptom(id: UUID(), label: "Fever", isCustom: false)
        let legacyEvent = LegacyEvent(
            id: UUID(),
            memberId: member.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.4, unit: .celsius),
            symptoms: [legacySymptom],
            notes: "Encourage rest"
        )
        let legacyState = LegacyHealthLogState(members: [member], events: [legacyEvent])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970

        let data = try encoder.encode(legacyState)
        let storageURL = temporaryDirectory.appendingPathComponent("health-log.json")
        try data.write(to: storageURL)

        let store = HealthLogStore(directory: temporaryDirectory)
        let state = store.loadState()

        XCTAssertEqual(state.schemaVersion, HealthLogSchemaVersion.current.rawValue)
        let symptomKind = state.events.first?.symptoms.first?.kind
        XCTAssertEqual(symptomKind, .fever)
    }
}
