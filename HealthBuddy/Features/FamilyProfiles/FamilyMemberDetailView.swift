import SwiftUI

struct FamilyMemberDetailView: View {
    @StateObject private var viewModel: FamilyMemberDetailViewModel
    private let store: any HealthLogStoring
    private let memberId: UUID

    @State private var isEditingProfile = false
    @State private var editName = ""
    @State private var editNotes = ""
    @State private var isPresentingLogEvent = false
    @State private var alertMessage: String?
    @State private var editingEvent: HealthEvent?

    init(store: any HealthLogStoring, memberId: UUID) {
        self.store = store
        self.memberId = memberId
        _viewModel = StateObject(wrappedValue: FamilyMemberDetailViewModel(store: store, memberId: memberId))
    }

    var body: some View {
        List {
            profileSection

            if viewModel.recentEntries.isEmpty {
                Section("Recent Events") {
                    Text("No health events logged yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Recent Events") {
                    ForEach(viewModel.recentEntries) { entry in
                        Button {
                            if let event = viewModel.event(with: entry.id) {
                                editingEvent = event
                            }
                        } label: {
                            MemberEventRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            handleEntryAppear(entry)
                        }
                    }
                }
                Section { Color.clear.frame(height: 72) }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.member.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    editName = viewModel.member.name
                    editNotes = viewModel.member.notes ?? ""
                    isEditingProfile = true
                }
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            editProfileSheet
        }
        .sheet(isPresented: $isPresentingLogEvent) {
            HealthEventLoggerView(store: store, memberId: memberId) {
                viewModel.refresh()
            }
        }
        .sheet(item: $editingEvent) { event in
            HealthEventLoggerView(store: store, editingEvent: event) {
                viewModel.refresh()
            }
        }
        .alert("Update Failed", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .onChange(of: isPresentingLogEvent) { _, newValue in
            if !newValue {
                viewModel.refresh()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                isPresentingLogEvent = true
                editingEvent = nil
            } label: {
                Label("Log Health Event", systemImage: "stethoscope")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12))
                    )
            )
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.member.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                if let notes = viewModel.member.notes, !notes.isEmpty {
                    Text(notes)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No notes yet. Add allergies, chronic conditions, or care preferences.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var editProfileSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $editName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    TextField("Notes", text: $editNotes, axis: .vertical)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        isEditingProfile = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                    }
                    .disabled(editName.trimmed.isEmpty)
                }
            }
        }
    }

    private func saveEdits() {
        do {
            try viewModel.updateMember(name: editName, notes: editNotes)
            isEditingProfile = false
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func handleEntryAppear(_ entry: EventHistoryEntry) {
        viewModel.loadMoreIfNeeded(for: entry)
    }
}

private struct MemberEventRow: View {
    var entry: EventHistoryEntry

    var body: some View {
        let guide = entry.severity.map(TemperatureSeverityGuide.guide) ?? TemperatureSeverityGuide.neutral()

        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(guide.color.gradient)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.summary.isEmpty ? "Symptoms logged" : entry.summary)
                    .font(.headline)
                Text(entry.displayDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notesPrefix(notes))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func notesPrefix(_ notes: String) -> String {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 32 else { return trimmed }
        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: 32, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        return String(trimmed[..<endIndex]) + "…"
    }
}

#if DEBUG
#Preview {
    let store = PreviewHealthLogStore()
    let member = FamilyMember(name: "Jordan", notes: "Peanut allergy")
    _ = try? store.addMember(member)
    _ = try? store.addEvent(
        HealthEvent(
            memberId: member.id,
            recordedAt: Date(),
            temperature: TemperatureReading(value: 38.6, unit: .celsius),
            symptoms: [Symptom(label: "Fever", isCustom: false)],
            notes: "Improved after rest"
        )
    )
    return NavigationStack {
        FamilyMemberDetailView(store: store, memberId: member.id)
    }
}
#endif
