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

        XCTAssertTrue(app.navigationBars["Family"].waitForExistence(timeout: 5))

        app.navigationBars["Family"].buttons["Add Member"].tap()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Jordan")

        app.navigationBars["New Family Member"].buttons["Save"].tap()

        let memberCell = app.cells.containing(.staticText, identifier: "Jordan").firstMatch
        XCTAssertTrue(memberCell.waitForExistence(timeout: 2))
        memberCell.tap()

        let logEventButton = app.buttons["Log Health Event"]
        XCTAssertTrue(logEventButton.waitForExistence(timeout: 2))
        logEventButton.tap()

        let addSymptomButton = app.buttons["Add Symptom"]
        XCTAssertTrue(addSymptomButton.waitForExistence(timeout: 2))
        addSymptomButton.tap()

        let coughButton = app.buttons["Cough"]
        XCTAssertTrue(coughButton.waitForExistence(timeout: 2))
        coughButton.tap()

        let saveButton = app.buttons["Save Health Event"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()

        let eventCell = app.cells.containing(.staticText, identifier: "Cough").firstMatch
        XCTAssertTrue(eventCell.waitForExistence(timeout: 2))
        eventCell.tap()

        let deleteButton = app.navigationBars["Edit Health Event"].buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        let confirmDeleteButton = app.buttons["Delete Event"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 2))
        confirmDeleteButton.tap()

        let noEventsLabel = app.staticTexts["No health events logged yet."]
        XCTAssertTrue(noEventsLabel.waitForExistence(timeout: 2))
        XCTAssertFalse(eventCell.exists)
    }
}
