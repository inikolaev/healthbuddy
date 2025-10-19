//
//  HealthBuddyApp.swift
//  HealthBuddy
//
//  Created by Igor Nikolaev on 19.10.2025.
//

import SwiftUI

@main
struct HealthBuddyApp: App {
    private let store: HealthLogStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTesting") {
            let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("HealthBuddyUITests", isDirectory: true)
            if arguments.contains("-uiTestingResetData") {
                try? FileManager.default.removeItem(at: tempDirectory)
            }
            store = HealthLogStore(directory: tempDirectory)
        } else {
            let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let storageDirectory = baseDirectory.appendingPathComponent("HealthBuddy", isDirectory: true)
            store = HealthLogStore(directory: storageDirectory)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
