import SwiftUI

struct HealthEventLoggerView: View {
    @StateObject private var viewModel: HealthEventLoggerViewModel
    @State private var form: HealthEventForm
    @State private var temperatureValue = ""
    @State private var temperatureUnit: TemperatureUnit = .celsius
    @State private var isPresentingSymptomPicker = false
    @State private var customSymptomDraft = ""
    @State private var alertMessage: String?

    private let store: any HealthLogStoring
    private let contextMemberId: UUID?
    private let onSave: (() -> Void)?

    init(store: any HealthLogStoring, memberId: UUID? = nil, onSave: (() -> Void)? = nil) {
        self.store = store
        self.contextMemberId = memberId
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: HealthEventLoggerViewModel(store: store, memberId: memberId))
        _form = State(initialValue: HealthEventForm(memberId: memberId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.members.isEmpty && contextMemberId == nil {
                    ContentUnavailableView(
                        "Add a Family Member",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Create a profile before logging symptoms or medication.")
                    )
                } else {
                    Form {
                        if contextMemberId == nil {
                            memberSection
                        }
                        temperatureSection
                        symptomsSection
                        medicationsSection
                        notesSection
                    }
                }
            }
            .navigationTitle("New Health Event")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Unable to Save", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .sheet(isPresented: $isPresentingSymptomPicker) {
                SymptomPickerView(
                    availableSymptoms: availableSymptoms,
                    customDraft: $customSymptomDraft,
                    onSelect: addSymptom,
                    onAddCustom: addCustomSymptom
                )
            }
            .onAppear(perform: refreshMembersIfNeeded)
            .safeAreaInset(edge: .bottom) {
                if displayPrimaryButton {
                    Button(action: logEvent) {
                        Text("Save Health Event")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .disabled(!canSave)
                    .background(Color(.systemBackground))
                }
            }
        }
    }

    private var availableSymptoms: [String] {
        viewModel.symptomLibrary.filter { symptom in
            !form.symptomLabels.contains(where: { $0.caseInsensitiveCompare(symptom) == .orderedSame }) &&
            !form.customSymptoms.contains(where: { $0.caseInsensitiveCompare(symptom) == .orderedSame })
        }
    }

    private var memberSection: some View {
        Section("Family Member") {
            Picker("Member", selection: Binding(
                get: { form.memberId ?? viewModel.members.first?.id },
                set: { form.memberId = $0 }
            )) {
                ForEach(viewModel.members) { member in
                    Text(member.name).tag(Optional(member.id))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var temperatureSection: some View {
        Section("Temperature") {
            HStack {
                TextField("Optional", text: $temperatureValue)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $temperatureUnit) {
                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                        Text(unit == .celsius ? "°C" : "°F").tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 140)
            }
            if let severity = currentSeverity {
                TemperatureSeverityBadge(severity: severity)
            } else {
                Text("Leave blank if temperature wasn't measured.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var symptomsSection: some View {
        Section("Symptoms") {
            if form.symptomLabels.isEmpty && form.customSymptoms.isEmpty {
                Text("No symptoms selected yet.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(form.symptomLabels, id: \.self) { symptom in
                        SymptomChip(label: symptom, removable: true) {
                            form.symptomLabels.removeAll { $0 == symptom }
                        }
                    }
                    ForEach(form.customSymptoms, id: \.self) { symptom in
                        SymptomChip(label: symptom, removable: true) {
                            form.customSymptoms.removeAll { $0 == symptom }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                customSymptomDraft = ""
                isPresentingSymptomPicker = true
            } label: {
                Label("Add Symptom", systemImage: "plus.circle")
            }
        }
    }

    private var medicationsSection: some View {
        Section("Medication") {
            TextField("Optional", text: Binding(
                get: { form.medications ?? "" },
                set: { form.medications = $0 }
            ))
            .autocorrectionDisabled()
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Care instructions, behaviours, fluids, etc.", text: Binding(
                get: { form.notes ?? "" },
                set: { form.notes = $0 }
            ), axis: .vertical)
        }
    }

    private var displayPrimaryButton: Bool {
        contextMemberId != nil || !viewModel.members.isEmpty
    }

    private var currentSeverity: TemperatureSeverity? {
        guard let reading = temperatureReading else { return nil }
        return reading.severity
    }

    private var temperatureReading: TemperatureReading? {
        guard let value = Double(temperatureValue) else { return nil }
        return TemperatureReading(value: value, unit: temperatureUnit)
    }

    private var canSave: Bool {
        let hasContext = (form.memberId ?? contextMemberId) != nil
        let hasTemperature = temperatureReading != nil
        let hasSymptoms = !form.symptomLabels.isEmpty || !form.customSymptoms.isEmpty
        let hasNotes = !(form.notes?.trimmed.isEmpty ?? true)
        let hasMedication = !(form.medications?.trimmed.isEmpty ?? true)
        return hasContext && (hasTemperature || hasSymptoms || hasNotes || hasMedication)
    }

    private func refreshMembersIfNeeded() {
        viewModel.refreshMembers()
        assignDefaultMemberIfNeeded()
    }

    private func assignDefaultMemberIfNeeded() {
        guard contextMemberId == nil else { return }
        if let currentId = form.memberId,
           viewModel.members.contains(where: { $0.id == currentId }) {
            return
        }
        form.memberId = viewModel.members.first?.id
    }

    private func addSymptom(_ symptom: String) {
        let normalized = symptom.trimmed
        guard !normalized.isEmpty else { return }
        if !form.symptomLabels.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            form.symptomLabels.append(normalized)
        }
        isPresentingSymptomPicker = false
    }

    private func addCustomSymptom(_ symptom: String) {
        let normalized = symptom.trimmed
        guard !normalized.isEmpty else { return }
        if !form.customSymptoms.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) &&
            !form.symptomLabels.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            form.customSymptoms.append(normalized)
        }
        customSymptomDraft = ""
        isPresentingSymptomPicker = false
    }

    private func logEvent() {
        var workingForm = form
        workingForm.memberId = form.memberId ?? contextMemberId
        workingForm.temperature = temperatureReading

        do {
            try viewModel.logEvent(using: workingForm)
            resetForm()
            onSave?()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func resetForm() {
        form = HealthEventForm(memberId: contextMemberId)
        temperatureValue = ""
        temperatureUnit = .celsius
        customSymptomDraft = ""
    }
}

private struct SymptomPickerView: View {
    var availableSymptoms: [String]
    @Binding var customDraft: String
    var onSelect: (String) -> Void
    var onAddCustom: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if !availableSymptoms.isEmpty {
                    Section("Common symptoms") {
                        ForEach(availableSymptoms, id: \.self) { symptom in
                            Button(symptom) {
                                onSelect(symptom)
                                dismiss()
                            }
                        }
                    }
                }

                Section("Custom") {
                    TextField("Describe symptom", text: $customDraft)
                    Button("Add custom") {
                        onAddCustom(customDraft)
                        dismiss()
                    }
                    .disabled(customDraft.trimmed.isEmpty)
                }
            }
            .navigationTitle("Add Symptom")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) { dismiss() }
                }
            }
        }
    }
}

private struct SymptomChip: View {
    var label: String
    var removable: Bool
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.footnote)
            if removable {
                Image(systemName: "xmark.circle.fill")
                    .onTapGesture(perform: onRemove)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.gray.opacity(0.2)))
    }
}

#if DEBUG
#Preview {
    let store = PreviewHealthLogStore()
    let member = FamilyMember(name: "Jordan", notes: "Peanut allergy")
    _ = try? store.addMember(member)
    return NavigationStack {
        HealthEventLoggerView(store: store, memberId: member.id)
    }
}
#endif
