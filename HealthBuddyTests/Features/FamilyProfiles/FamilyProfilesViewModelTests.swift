import XCTest
@testable import HealthBuddy

@MainActor
final class FamilyProfilesViewModelTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: HealthLogStore!
    private var sut: FamilyProfilesViewModel!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        store = HealthLogStore(directory: temporaryDirectory)
    }

    override func tearDownWithError() throws {
        sut = nil
        try? FileManager.default.removeItem(at: temporaryDirectory)
        store = nil
    }

    func testMembersLoadSortedByName() throws {
        let jordan = FamilyMember(id: UUID(), name: "Jordan")
        let alex = FamilyMember(id: UUID(), name: "alex")
        try store.replaceState(HealthLogState(members: [jordan, alex]))

        sut = FamilyProfilesViewModel(store: store)

        XCTAssertEqual(sut.members.map(\.name), ["alex", "Jordan"])
    }

    func testAddMemberPersistsAndUpdatesState() throws {
        sut = FamilyProfilesViewModel(store: store)

        try sut.addMember(name: "Lena", notes: "Lactose intolerant")

        XCTAssertEqual(sut.members.count, 1)
        XCTAssertEqual(sut.members.first?.name, "Lena")
        XCTAssertEqual(store.loadState().members.first?.notes, "Lactose intolerant")
    }

    func testAddMemberRejectsEmptyName() throws {
        sut = FamilyProfilesViewModel(store: store)

        XCTAssertThrowsError(try sut.addMember(name: "   ", notes: nil)) { error in
            XCTAssertEqual(error as? FamilyProfilesError, .emptyName)
        }
    }

    func testDeleteMemberRemovesFromStore() throws {
        let member = FamilyMember(id: UUID(), name: "Andi")
        try store.addMember(member)
        sut = FamilyProfilesViewModel(store: store)

        try sut.deleteMembers(at: IndexSet(integer: 0))

        XCTAssertTrue(store.loadState().members.isEmpty)
        XCTAssertTrue(sut.members.isEmpty)
    }
}
