import SwiftUI

struct FamilyProfilesView: View {
    @StateObject private var viewModel: FamilyProfilesViewModel
    @State private var isPresentingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberNotes = ""
    @State private var alertMessage: String?
    private let store: any HealthLogStoring

    init(store: any HealthLogStoring) {
        self.store = store
        _viewModel = StateObject(wrappedValue: FamilyProfilesViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Family")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            newMemberName = ""
                            newMemberNotes = ""
                            isPresentingAddMember = true
                        } label: {
                            Label("Add Member", systemImage: "plus")
                        }
                        .accessibilityIdentifier("family_addMemberButton")
                    }
                }
                .sheet(isPresented: $isPresentingAddMember) {
                    addMemberSheet
                }
                .alert("Unable to Save", isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { alertMessage = nil }
                } message: {
                    Text(alertMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.members.isEmpty {
            emptyState
        } else {
            List {
                ForEach(viewModel.members) { member in
                    NavigationLink {
                        FamilyMemberDetailView(store: store, memberId: member.id)
                    } label: {
                        FamilyMemberRow(member: member)
                    }
                }
                .onDelete(perform: delete)
            }
            .listStyle(.insetGrouped)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Start Your Family List",
            systemImage: "person.3",
            description: Text("Add each family member so you can log symptoms and notes when they need care.")
        )
        .symbolEffect(.bounce, value: viewModel.members.isEmpty)
    }

    private var addMemberSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $newMemberName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("family_addMember_nameField")
                    TextField("Allergies or chronic notes", text: $newMemberNotes, axis: .vertical)
                }
            }
            .navigationTitle("New Family Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        isPresentingAddMember = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMember()
                    }
                    .disabled(newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("family_addMember_saveButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveMember() {
        do {
            try viewModel.addMember(name: newMemberName, notes: newMemberNotes.isEmpty ? nil : newMemberNotes)
            isPresentingAddMember = false
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        do {
            try viewModel.deleteMembers(at: offsets)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

private struct FamilyMemberRow: View {
    var member: FamilyMember

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color.accentColor.gradient)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                if let notes = member.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#if DEBUG
final class PreviewHealthLogStore: HealthLogStoring {
    private var state = HealthLogState(
        members: [
            FamilyMember(name: "Nora", notes: "Penicillin allergy"),
            FamilyMember(name: "Milo", notes: "Asthma inhaler"),
            FamilyMember(name: "Ava")
        ],
        events: []
    )

    func loadState() -> HealthLogState { state }
    @discardableResult func addMember(_ member: FamilyMember) throws -> HealthLogState {
        if let index = state.members.firstIndex(where: { $0.id == member.id }) {
            state.members[index] = member
        } else {
            state.members.append(member)
        }
        return state
    }

    @discardableResult func addEvent(_ event: HealthEvent) throws -> HealthLogState {
        if let index = state.events.firstIndex(where: { $0.id == event.id }) {
            state.events[index] = event
        } else {
            state.events.append(event)
        }
        return state
    }

    func removeMember(id: UUID) throws {
        state.members.removeAll { $0.id == id }
    }

    func removeEvent(id: UUID) throws {
        state.events.removeAll { $0.id == id }
    }

    func replaceState(_ newState: HealthLogState) throws {
        state = newState
    }
}
#endif

#Preview {
    FamilyProfilesView(store: PreviewHealthLogStore())
}
