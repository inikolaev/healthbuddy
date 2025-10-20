import XCTest
@testable import HealthBuddy

final class HealthLogStoreTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: HealthLogStore!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        store = HealthLogStore(directory: temporaryDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        store = nil
    }

    func testLoadReturnsEmptyStateWhenBackingFileMissing() throws {
        let state = store.loadState()

        XCTAssertEqual(state.schemaVersion, HealthLogSchemaVersion.current.rawValue)
        XCTAssertTrue(state.members.isEmpty)
        XCTAssertTrue(state.events.isEmpty)
    }

    func testAddMemberPersistsToDisk() throws {
        let member = FamilyMember(id: UUID(), name: "Jordan", notes: "Peanut allergy")
        try store.addMember(member)

        let reloadedStore = HealthLogStore(directory: temporaryDirectory)
        XCTAssertEqual(reloadedStore.loadState().members, [member])
        XCTAssertEqual(reloadedStore.loadState().schemaVersion, HealthLogSchemaVersion.current.rawValue)
    }

    func testAddEventRequiresExistingMember() {
        let event = HealthEvent(
            id: UUID(),
            memberId: UUID(),
            recordedAt: Date(),
            temperature: TemperatureReading(value: 37.1, unit: .celsius),
            symptoms: [Symptom(kind: .cough)],
            notes: "Rested"
        )

        XCTAssertThrowsError(try store.addEvent(event)) { error in
            guard let storeError = error as? HealthLogStoreError else {
                return XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertEqual(storeError, .missingMember(event.memberId))
        }
        XCTAssertEqual(store.loadState().schemaVersion, HealthLogSchemaVersion.current.rawValue)
    }

    func testRemovingMemberAlsoRemovesEvents() throws {
        let member = FamilyMember(id: UUID(), name: "Lena", notes: nil)
        try store.addMember(member)

        let event = HealthEvent(
            id: UUID(),
            memberId: member.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.3, unit: .celsius),
            symptoms: [Symptom(kind: .headache)],
            notes: "Slept early"
        )
        try store.addEvent(event)

        try store.removeMember(id: member.id)

        let state = store.loadState()
        XCTAssertEqual(state.schemaVersion, HealthLogSchemaVersion.current.rawValue)
        XCTAssertTrue(state.members.isEmpty)
        XCTAssertTrue(state.events.isEmpty)
    }

    func testAddEventAllowsMissingTemperature() throws {
        let member = FamilyMember(id: UUID(), name: "Kai", notes: nil)
        try store.addMember(member)

        let event = HealthEvent(
            id: UUID(),
            memberId: member.id,
            recordedAt: Date(),
            temperature: nil,
            symptoms: [],
            notes: nil
        )

        try store.addEvent(event)

        let state = store.loadState()
        XCTAssertEqual(state.schemaVersion, HealthLogSchemaVersion.current.rawValue)
        XCTAssertNil(state.events.first?.temperature)
    }

    func testRemoveEventDeletesEvent() throws {
        let member = FamilyMember(id: UUID(), name: "Kai", notes: nil)
        try store.addMember(member)

        let event = HealthEvent(
            id: UUID(),
            memberId: member.id,
            recordedAt: Date(),
            temperature: nil,
            symptoms: [],
            notes: nil
        )
        try store.addEvent(event)

        try store.removeEvent(id: event.id)

        let state = store.loadState()
        XCTAssertEqual(state.schemaVersion, HealthLogSchemaVersion.current.rawValue)
        XCTAssertTrue(state.events.isEmpty)
    }
}
