import XCTest
@testable import HealthBuddy

@MainActor
final class FamilyMemberDetailViewModelTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: HealthLogStore!
    private var member: FamilyMember!
    private var otherMember: FamilyMember!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        store = HealthLogStore(directory: temporaryDirectory)
        member = FamilyMember(id: UUID(), name: "Jordan", notes: "Peanut allergy")
        otherMember = FamilyMember(id: UUID(), name: "Lena", notes: nil)
        try store.addMember(member)
        try store.addMember(otherMember)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        store = nil
        member = nil
        otherMember = nil
    }

    func testLoadsMemberAndRecentEvents() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let earlier = now.addingTimeInterval(-3600)

        let memberEvent = HealthEvent(
            memberId: member.id,
            recordedAt: now,
            temperature: TemperatureReading(value: 38.2, unit: .celsius),
            symptoms: [Symptom(label: "Fever", isCustom: false)],
            medications: "Paracetamol",
            notes: nil
        )
        let olderMemberEvent = HealthEvent(
            memberId: member.id,
            recordedAt: earlier,
            temperature: nil,
            symptoms: [Symptom(label: "Fatigue", isCustom: false)],
            medications: nil,
            notes: nil
        )
        let otherEvent = HealthEvent(
            memberId: otherMember.id,
            recordedAt: now,
            temperature: TemperatureReading(value: 37.5, unit: .celsius),
            symptoms: [],
            medications: nil,
            notes: nil
        )

        try store.addEvent(memberEvent)
        try store.addEvent(olderMemberEvent)
        try store.addEvent(otherEvent)

        let sut = FamilyMemberDetailViewModel(store: store, memberId: member.id, historyLimit: 2, locale: Locale(identifier: "en_US_POSIX"), calendar: calendar)

        XCTAssertEqual(sut.member.id, member.id)
        XCTAssertEqual(sut.recentEntries.count, 2)
        XCTAssertEqual(sut.recentEntries.first?.id, memberEvent.id)
        XCTAssertEqual(sut.recentEntries.last?.id, olderMemberEvent.id)
    }

    func testUpdateMemberMetadataPersistsChanges() throws {
        let sut = FamilyMemberDetailViewModel(store: store, memberId: member.id)

        try sut.updateMember(name: "Jordan Smith", notes: "Peanut allergy, seasonal asthma")

        XCTAssertEqual(sut.member.name, "Jordan Smith")
        XCTAssertEqual(store.loadState().members.first(where: { $0.id == member.id })?.notes, "Peanut allergy, seasonal asthma")
    }
}
