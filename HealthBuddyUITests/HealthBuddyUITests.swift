//
//  HealthBuddyUITests.swift
//  HealthBuddyUITests
//
//  Created by Igor Nikolaev on 19.10.2025.
//

import XCTest

final class HealthBuddyUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-uiTestingResetData"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLogAndDeleteHealthEventFlow() throws {
        app.launch()

        XCTAssertTrue(app.buttons["family_addMemberButton"].waitForExistence(timeout: 5))

        app.buttons["family_addMemberButton"].tap()

        let nameField = app.textFields["family_addMember_nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Jordan")

        app.buttons["family_addMember_saveButton"].tap()

        let memberCell = app.cells.containing(.staticText, identifier: "Jordan").firstMatch
        XCTAssertTrue(memberCell.waitForExistence(timeout: 2))
        memberCell.tap()

        let logEventButton = app.buttons["memberDetail_logEventButton"]
        XCTAssertTrue(logEventButton.waitForExistence(timeout: 2))
        logEventButton.tap()

        let addSymptomButton = app.buttons["event_addSymptomButton"]
        XCTAssertTrue(addSymptomButton.waitForExistence(timeout: 2))
        addSymptomButton.tap()

        let customSymptomField = app.textFields["symptomPicker_customField"]
        XCTAssertTrue(customSymptomField.waitForExistence(timeout: 2))
        customSymptomField.tap()
        customSymptomField.typeText("Cough")

        let addCustomButton = app.buttons["symptomPicker_addCustomButton"]
        XCTAssertTrue(addCustomButton.waitForExistence(timeout: 2))
        addCustomButton.tap()

        let saveButton = app.buttons["event_primaryActionButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()

        let eventCell = app.cells.containing(.staticText, identifier: "Cough").firstMatch
        XCTAssertTrue(eventCell.waitForExistence(timeout: 2))
        eventCell.tap()

        let deleteButton = app.buttons["event_deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        let confirmDeleteButton = app.buttons["event_confirmDeleteButton"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 2))
        confirmDeleteButton.tap()

        let noEventsLabel = app.staticTexts["memberDetail_noEventsLabel"]
        XCTAssertTrue(noEventsLabel.waitForExistence(timeout: 2))
        XCTAssertFalse(eventCell.exists)
    }
}
