//
//  ContentView.swift
//  HealthBuddy
//
//  Created by Igor Nikolaev on 19.10.2025.
//

import SwiftUI

struct ContentView: View {
    private let store: any HealthLogStoring

    init(store: any HealthLogStoring) {
        self.store = store
    }

    var body: some View {
        TabView {
            FamilyProfilesView(store: store)
                .tabItem {
                    Label("Family", systemImage: "person.3")
                }

            HealthEventLoggerView(store: store)
                .tabItem {
                    Label("Log Event", systemImage: "stethoscope")
                }

            EventHistoryView(store: store)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}

#Preview {
    ContentView(store: PreviewHealthLogStore())
}
