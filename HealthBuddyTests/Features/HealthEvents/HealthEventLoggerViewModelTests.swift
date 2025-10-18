import XCTest
@testable import HealthBuddy

@MainActor
final class HealthEventLoggerViewModelTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: HealthLogStore!
    private var sut: HealthEventLoggerViewModel!
    private var member: FamilyMember!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        store = HealthLogStore(directory: temporaryDirectory)
        member = FamilyMember(id: UUID(), name: "Jordan")
        try store.addMember(member)
        sut = HealthEventLoggerViewModel(store: store)
    }

    override func tearDownWithError() throws {
        sut = nil
        store = nil
        member = nil
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testMembersMirrorStoreState() {
        XCTAssertEqual(sut.members.map(\.id), [member.id])
    }

    func testLogEventPersistsToStore() throws {
        var form = HealthEventForm(memberId: member.id)
        form.temperature = TemperatureReading(value: 38.1, unit: .celsius)
        form.symptomLabels = ["Cough"]
        form.customSymptoms = ["Body aches"]
        form.medications = "Paracetamol"
        form.notes = "Rest and fluids"

        try sut.logEvent(using: form)

        let events = store.loadState().events
        XCTAssertEqual(events.count, 1)
        guard let event = events.first else {
            return XCTFail("Expected stored event")
        }
        XCTAssertEqual(event.memberId, member.id)
        XCTAssertNotNil(event.temperature)
        if let temperature = event.temperature {
            XCTAssertEqual(temperature.value, 38.1, accuracy: 0.001)
        }
        XCTAssertEqual(event.symptoms.count, 2)
        XCTAssertTrue(event.symptoms.contains(where: { !$0.isCustom && $0.label == "Cough" }))
        XCTAssertTrue(event.symptoms.contains(where: { $0.isCustom && $0.label == "Body aches" }))
    }

    func testLogEventRequiresMemberSelection() {
        sut = HealthEventLoggerViewModel(store: store)

        XCTAssertThrowsError(try sut.logEvent(using: HealthEventForm())) { error in
            XCTAssertEqual(error as? HealthEventLoggerError, .missingMemberSelection)
        }
    }

    func testLogEventRejectsTemperatureOutsideSafeRange() {
        var form = HealthEventForm(memberId: member.id)
        form.temperature = TemperatureReading(value: 28.0, unit: .celsius)

        XCTAssertThrowsError(try sut.logEvent(using: form)) { error in
            XCTAssertEqual(error as? HealthEventLoggerError, .invalidTemperature)
        }
    }
}
