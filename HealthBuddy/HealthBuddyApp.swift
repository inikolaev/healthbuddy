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
        let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let storageDirectory = baseDirectory.appendingPathComponent("HealthBuddy", isDirectory: true)
        store = HealthLogStore(directory: storageDirectory)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
