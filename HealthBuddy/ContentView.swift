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
        FamilyProfilesView(store: store)
    }
}

#Preview {
    ContentView(store: PreviewHealthLogStore())
}
