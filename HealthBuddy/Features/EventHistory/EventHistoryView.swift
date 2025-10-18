import SwiftUI

struct EventHistoryView: View {
    @StateObject private var viewModel: EventHistoryViewModel

    init(store: any HealthLogStoring) {
        _viewModel = StateObject(wrappedValue: EventHistoryViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sections.isEmpty {
                    ContentUnavailableView(
                        "No health events yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Log an event to build a compassionate history for each family member.")
                    )
                } else {
                    List {
                        ForEach(viewModel.sections) { section in
                            Section(header: Text(section.member.name)) {
                                ForEach(section.entries) { entry in
                                    NavigationLink {
                                        EventHistoryDetailView(entry: entry, memberName: section.member.name)
                                    } label: {
                                        EventHistoryRow(entry: entry)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

private struct EventHistoryRow: View {
    var entry: EventHistoryEntry

    var body: some View {
        let guide = TemperatureSeverityGuide.guide(for: entry.severity)

        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(guide.color.gradient)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.summary)
                    .font(.headline)
                Text(entry.displayDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

private struct EventHistoryDetailView: View {
    var entry: EventHistoryEntry
    var memberName: String

    var body: some View {
        List {
            Section(header: Text("Temperature")) {
                TemperatureSeverityBadge(severity: entry.severity)
                Text(entry.temperature.formatted())
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            if !entry.symptoms.isEmpty {
                Section(header: Text("Symptoms")) {
                    ForEach(entry.symptoms) { symptom in
                        Label(symptom.label, systemImage: symptom.isCustom ? "pencil" : "star")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }

            if let medications = entry.medications, !medications.isEmpty {
                Section(header: Text("Medication")) {
                    Text(medications)
                }
            }

            if let notes = entry.notes, !notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(notes)
                }
            }

            Section(header: Text("Recorded")) {
                Text(entry.displayDate)
                Text(memberName)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(memberName)
    }
}

#if DEBUG
#Preview {
    let store = PreviewHealthLogStore()
    let member = FamilyMember(name: "Jordan")
    _ = try? store.addMember(member)
    _ = try? store.addEvent(
        HealthEvent(
            memberId: member.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.8, unit: .celsius),
            symptoms: [Symptom(label: "Fever", isCustom: false), Symptom(label: "Chills", isCustom: false)],
            medications: "Paracetamol",
            notes: "Temp lowered after two hours"
        )
    )
    return EventHistoryView(store: store)
}
#endif
