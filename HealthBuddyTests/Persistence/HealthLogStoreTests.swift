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

        XCTAssertTrue(state.members.isEmpty)
        XCTAssertTrue(state.events.isEmpty)
    }

    func testAddMemberPersistsToDisk() throws {
        let member = FamilyMember(id: UUID(), name: "Jordan", notes: "Peanut allergy")
        try store.addMember(member)

        let reloadedStore = HealthLogStore(directory: temporaryDirectory)
        XCTAssertEqual(reloadedStore.loadState().members, [member])
    }

    func testAddEventRequiresExistingMember() {
        let event = HealthEvent(
            id: UUID(),
            memberId: UUID(),
            recordedAt: Date(),
            temperature: TemperatureReading(value: 37.1, unit: .celsius),
            symptoms: [Symptom(label: "Cough", isCustom: false)],
            medications: "Paracetamol",
            notes: "Rested"
        )

        XCTAssertThrowsError(try store.addEvent(event)) { error in
            guard let storeError = error as? HealthLogStoreError else {
                return XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertEqual(storeError, .missingMember(event.memberId))
        }
    }

    func testRemovingMemberAlsoRemovesEvents() throws {
        let member = FamilyMember(id: UUID(), name: "Lena", notes: nil)
        try store.addMember(member)

        let event = HealthEvent(
            id: UUID(),
            memberId: member.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.3, unit: .celsius),
            symptoms: [Symptom(label: "Headache", isCustom: false)],
            medications: nil,
            notes: "Slept early"
        )
        try store.addEvent(event)

        try store.removeMember(id: member.id)

        XCTAssertTrue(store.loadState().members.isEmpty)
        XCTAssertTrue(store.loadState().events.isEmpty)
    }
}
