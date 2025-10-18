import XCTest
@testable import HealthBuddy

@MainActor
final class AppIntegrationTests: XCTestCase {
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

    func testMemberCreationLoggingAndHistoryFlow() throws {
        // Add a family member through the profiles view model.
        let profilesVM = FamilyProfilesViewModel(store: store)
        try profilesVM.addMember(name: "Jordan", notes: "Peanut allergy")
        XCTAssertEqual(store.loadState().members.count, 1)

        // Log an event through the logging view model.
        let memberId = try XCTUnwrap(store.loadState().members.first?.id)
        let loggerVM = HealthEventLoggerViewModel(store: store, memberId: memberId)

        var form = HealthEventForm()
        form.temperature = TemperatureReading(value: 38.6, unit: .celsius)
        form.symptomLabels = ["Fever", "Cough"]
        form.medications = "Paracetamol"
        form.notes = "Kept hydrated"

        try loggerVM.logEvent(using: form)
        XCTAssertEqual(store.loadState().events.count, 1)

        // View the recorded event through the history view model.
        let historyVM = EventHistoryViewModel(store: store, locale: Locale(identifier: "en_US_POSIX"))
        XCTAssertEqual(historyVM.sections.count, 1)
        XCTAssertEqual(historyVM.sections.first?.entries.count, 1)
        XCTAssertEqual(historyVM.sections.first?.entries.first?.severity, .high)

        // Ensure the member detail surface reflects the new event.
        let detailVM = FamilyMemberDetailViewModel(store: store, memberId: memberId, historyLimit: 5, locale: Locale(identifier: "en_US_POSIX"))
        XCTAssertEqual(detailVM.recentEntries.count, 1)
        XCTAssertEqual(detailVM.recentEntries.first?.severity, .high)
    }
}
