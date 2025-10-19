import XCTest
@testable import HealthBuddy

@MainActor
final class HealthEventLoggerViewModelTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: HealthLogStore!
    private var sut: HealthEventLoggerViewModel!
    private var member: FamilyMember!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        store = HealthLogStore(directory: temporaryDirectory)
        member = FamilyMember(id: UUID(), name: "Jordan")
        try store.addMember(member)
        calendar = Calendar(identifier: .gregorian)
        sut = HealthEventLoggerViewModel(store: store, memberId: member.id, calendar: calendar)
    }

    override func tearDownWithError() throws {
        sut = nil
        store = nil
        member = nil
        calendar = nil
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testLogEventPersistsToStoreWithTemperature() throws {
        var form = HealthEventForm()
        form.temperature = TemperatureReading(value: 38.1, unit: .celsius)
        form.symptomLabels = ["Cough"]
        form.customSymptoms = ["Body aches"]
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

    func testLogEventRespectsCustomTimestamp() throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(calendar: calendar, year: 2025, month: 6, day: 1, hour: 14, minute: 27, second: 45)
        let recordedDate = components.date ?? Date()

        var form = HealthEventForm(memberId: member.id, recordedAt: recordedDate)
        form.temperature = TemperatureReading(value: 37.6, unit: .celsius)

        try sut.logEvent(using: form)

        let storedEvent = try XCTUnwrap(store.loadState().events.first)
        components.second = 0
        let expected = components.date ?? recordedDate
        XCTAssertEqual(storedEvent.recordedAt, expected)
    }

    func testUpdateEventReplacesExistingRecord() throws {
        let original = HealthEvent(
            memberId: member.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.0, unit: .celsius),
            symptoms: [Symptom(label: "Cough", isCustom: false)],
            notes: nil
        )
        try store.addEvent(original)

        let newRecordedAt = calendar.date(byAdding: .minute, value: -90, to: Date()) ?? Date()

        var form = HealthEventForm(memberId: member.id, recordedAt: newRecordedAt)
        form.symptomLabels = ["Fever"]
        form.customSymptoms = ["Body aches"]
        form.notes = "Hydrate often"

        try sut.updateEvent(id: original.id, using: form)

        let state = store.loadState()
        XCTAssertEqual(state.events.count, 1)
        let updated = try XCTUnwrap(state.events.first)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertNil(updated.temperature)
        XCTAssertTrue(updated.symptoms.contains(where: { !$0.isCustom && $0.label == "Fever" }))
        XCTAssertTrue(updated.symptoms.contains(where: { $0.isCustom && $0.label == "Body aches" }))
        XCTAssertEqual(updated.notes, "Hydrate often")

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: newRecordedAt)
        let trimmedRecordedAt = calendar.date(from: components) ?? newRecordedAt
        XCTAssertEqual(updated.recordedAt, trimmedRecordedAt)
    }

    func testDeleteEventRemovesItFromStore() throws {
        let original = HealthEvent(
            memberId: member.id,
            recordedAt: Date(),
            temperature: nil,
            symptoms: [Symptom(label: "Cough", isCustom: false)],
            notes: nil
        )
        try store.addEvent(original)

        try sut.deleteEvent(id: original.id)

        XCTAssertTrue(store.loadState().events.isEmpty)
    }

    func testLogEventRejectsTemperatureOutsideSafeRange() {
        var form = HealthEventForm()
        form.temperature = TemperatureReading(value: 28.0, unit: .celsius)

        XCTAssertThrowsError(try sut.logEvent(using: form)) { error in
            XCTAssertEqual(error as? HealthEventLoggerError, .invalidTemperature)
        }
    }

    func testLogEventAllowsMissingTemperature() throws {
        var form = HealthEventForm()
        form.symptomLabels = ["Fever"]

        try sut.logEvent(using: form)

        let event = try XCTUnwrap(store.loadState().events.first)
        XCTAssertNil(event.temperature)
        XCTAssertEqual(event.symptoms.first?.label, "Fever")
    }

    func testRequiresTemperatureWhenFeverSelected() {
        XCTAssertTrue(
            HealthEventLoggerViewModel.requiresTemperature(
                symptomLabels: ["fever"],
                customSymptoms: []
            )
        )
    }

    func testRequiresTemperatureWhenChillsSelected() {
        XCTAssertTrue(
            HealthEventLoggerViewModel.requiresTemperature(
                symptomLabels: ["Cough"],
                customSymptoms: ["chills"]
            )
        )
    }

    func testRequiresTemperatureIsCaseInsensitiveAndTrimmed() {
        XCTAssertTrue(
            HealthEventLoggerViewModel.requiresTemperature(
                symptomLabels: ["  Fever "],
                customSymptoms: []
            )
        )
    }

    func testRequiresTemperatureFalseWhenNoIndicatorsPresent() {
        XCTAssertFalse(
            HealthEventLoggerViewModel.requiresTemperature(
                symptomLabels: ["cough", "sore throat"],
                customSymptoms: ["body aches"]
            )
        )
    }
}
