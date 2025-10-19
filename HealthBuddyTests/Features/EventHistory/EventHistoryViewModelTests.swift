import XCTest
@testable import HealthBuddy

@MainActor
final class EventHistoryViewModelTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: HealthLogStore!
    private var jordan: FamilyMember!
    private var lena: FamilyMember!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        store = HealthLogStore(directory: temporaryDirectory)
        jordan = FamilyMember(id: UUID(), name: "Jordan")
        lena = FamilyMember(id: UUID(), name: "Lena")
        try store.addMember(jordan)
        try store.addMember(lena)
    }

    override func tearDownWithError() throws {
        store = nil
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testSectionsGroupEventsByMemberWithNewestFirst() throws {
        let older = HealthEvent(
            memberId: jordan.id,
            recordedAt: Date().addingTimeInterval(-3600),
            temperature: TemperatureReading(value: 37.2, unit: .celsius),
            symptoms: [Symptom(label: "Headache", isCustom: false)],
            notes: nil
        )
        let newer = HealthEvent(
            memberId: jordan.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.6, unit: .celsius),
            symptoms: [Symptom(label: "Fever", isCustom: false)],
            notes: nil
        )
        let lenaEvent = HealthEvent(
            memberId: lena.id,
            recordedAt: Date().addingTimeInterval(-1800),
            temperature: TemperatureReading(value: 36.4, unit: .celsius),
            symptoms: [],
            notes: nil
        )

        try store.addEvent(older)
        try store.addEvent(newer)
        try store.addEvent(lenaEvent)

        let sut = EventHistoryViewModel(store: store, locale: Locale(identifier: "en_US_POSIX"))

        XCTAssertEqual(sut.sections.count, 2)

        let jordanSection = sut.sections.first { $0.member.id == jordan.id }
        XCTAssertEqual(jordanSection?.entries.map(\.id), [newer.id, older.id])

        let lenaSection = sut.sections.first { $0.member.id == lena.id }
        XCTAssertEqual(lenaSection?.entries.map(\.id), [lenaEvent.id])
    }

    func testEntryProvidesSeverityAndSummary() throws {
        let event = HealthEvent(
            memberId: jordan.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 39.7, unit: .celsius),
            symptoms: [
                Symptom(label: "Fever", isCustom: false),
                Symptom(label: "Cough", isCustom: false),
                Symptom(label: "Sore throat", isCustom: false)
            ],
            notes: "Encourage fluids"
        )
        try store.addEvent(event)

        let sut = EventHistoryViewModel(store: store, locale: Locale(identifier: "en_US_POSIX"))
        guard let entry = sut.sections.first?.entries.first else {
            return XCTFail("Expected an entry")
        }

        XCTAssertEqual(entry.severity, .critical)
        XCTAssertTrue(entry.summary.contains("Cough"))
        XCTAssertTrue(entry.summary.contains("39.7"))
        XCTAssertEqual(entry.notes, "Encourage fluids")
    }

    func testSummaryOmitsTemperatureWhenNoFeverRelatedSymptoms() throws {
        let event = HealthEvent(
            memberId: jordan.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.4, unit: .celsius),
            symptoms: [
                Symptom(label: "Cough", isCustom: false),
                Symptom(label: "Sore throat", isCustom: false)
            ],
            notes: nil
        )
        try store.addEvent(event)

        let sut = EventHistoryViewModel(store: store, locale: Locale(identifier: "en_US_POSIX"))
        let entry = try XCTUnwrap(sut.sections.first?.entries.first)

        XCTAssertFalse(entry.summary.contains("38.4"))
        XCTAssertTrue(entry.summary.contains("Cough"))
    }

    func testEntryHandlesMissingTemperature() throws {
        let event = HealthEvent(
            memberId: jordan.id,
            recordedAt: Date(),
            temperature: nil,
            symptoms: [Symptom(label: "Fatigue", isCustom: false)],
            notes: nil
        )
        try store.addEvent(event)

        let sut = EventHistoryViewModel(store: store, locale: Locale(identifier: "en_US_POSIX"))
        guard let entry = sut.sections.first?.entries.first else {
            return XCTFail("Expected an entry")
        }

        XCTAssertNil(entry.severity)
        XCTAssertFalse(entry.summary.contains("°"))
    }
}
