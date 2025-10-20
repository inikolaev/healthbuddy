import SwiftUI

struct HealthEventLoggerView: View {
    @StateObject private var viewModel: HealthEventLoggerViewModel
    @State private var form: HealthEventForm
    @State private var temperatureValue: String
    @State private var temperatureUnit: TemperatureUnit
    @State private var isPresentingSymptomPicker = false
    @State private var customSymptomDraft = ""
    @State private var alertMessage: String?
    @State private var isPresentingDeleteConfirmation = false

    private let store: any HealthLogStoring
    private let contextMemberId: UUID?
    private let editingEvent: HealthEvent?
    private let onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    init(store: any HealthLogStoring, memberId: UUID? = nil, editingEvent: HealthEvent? = nil, onSave: (() -> Void)? = nil) {
        self.store = store
        self.editingEvent = editingEvent
        let initialMemberId = memberId ?? editingEvent?.memberId
        self.contextMemberId = initialMemberId
        self.onSave = onSave
        let viewModel = HealthEventLoggerViewModel(store: store, memberId: initialMemberId)
        _viewModel = StateObject(wrappedValue: viewModel)

        if let event = editingEvent {
            _form = State(initialValue: HealthEventForm(event: event))
            let showTemperature = HealthEventLoggerViewModel.requiresTemperature(
                symptomLabels: _form.wrappedValue.symptomLabels,
                customSymptoms: _form.wrappedValue.customSymptoms
            )
            if showTemperature, let temperature = event.temperature {
                let formatted = LocalizedDecimalFormatter.string(from: temperature.value, locale: Locale.current, fractionDigits: 1)
                _temperatureValue = State(initialValue: formatted)
                _temperatureUnit = State(initialValue: temperature.unit)
            } else {
                _temperatureValue = State(initialValue: "")
                _temperatureUnit = State(initialValue: .celsius)
            }
        } else {
            _form = State(initialValue: HealthEventForm(memberId: initialMemberId))
            _temperatureValue = State(initialValue: "")
            _temperatureUnit = State(initialValue: .celsius)
        }
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
                        dateSection
                        symptomsSection
                        if shouldShowTemperatureSection {
                            temperatureSection
                        }
                        notesSection
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Health Event" : "New Health Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            isPresentingDeleteConfirmation = true
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("Delete Health Event?", isPresented: $isPresentingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Event", role: .destructive) {
                    performDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Deleting removes this entry from the log and cannot be undone.")
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
            .onChange(of: form.symptomLabels) { _, _ in
                clearTemperatureIfNeeded()
            }
            .onChange(of: form.customSymptoms) { _, _ in
                clearTemperatureIfNeeded()
            }
            .safeAreaInset(edge: .bottom) {
                if displayPrimaryButton {
                    Button(action: logEvent) {
                        Text(primaryButtonTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .disabled(!canSave)
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
        }
    }

    private var availableSymptoms: [String] {
        viewModel.symptomLibrary.filter { symptom in
            !form.symptomLabels.contains(where: { $0.caseInsensitiveCompare(symptom) == .orderedSame }) &&
            !form.customSymptoms.contains(where: { $0.caseInsensitiveCompare(symptom) == .orderedSame })
        }
    }

    private var isEditing: Bool { editingEvent != nil }

    private var primaryButtonTitle: String { isEditing ? "Update Health Event" : "Save Health Event" }

    private func performDelete() {
        guard let editingEvent else { return }
        isPresentingDeleteConfirmation = false
        do {
            try viewModel.deleteEvent(id: editingEvent.id)
            onSave?()
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
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

    private var dateSection: some View {
        Section("Date & Time") {
            DatePicker(
                "Logged at",
                selection: Binding(
                    get: { form.recordedAt },
                    set: { form.recordedAt = $0 }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
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
        guard shouldShowTemperatureSection,
              let value = LocalizedDecimalFormatter.parse(temperatureValue, locale: locale) else { return nil }
        return TemperatureReading(value: value, unit: temperatureUnit)
    }

    private var canSave: Bool {
        let hasContext = (form.memberId ?? contextMemberId) != nil
        let hasTemperature = temperatureReading != nil
        let hasSymptoms = !form.symptomLabels.isEmpty || !form.customSymptoms.isEmpty
        let hasNotes = !(form.notes?.trimmed.isEmpty ?? true)
        return hasContext && (hasTemperature || hasSymptoms || hasNotes)
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
            if let editingEvent = editingEvent {
                try viewModel.updateEvent(id: editingEvent.id, using: workingForm)
            } else {
                try viewModel.logEvent(using: workingForm)
            }
            onSave?()
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private var shouldShowTemperatureSection: Bool {
        HealthEventLoggerViewModel.requiresTemperature(
            symptomLabels: form.symptomLabels,
            customSymptoms: form.customSymptoms
        )
    }

    private func clearTemperatureIfNeeded() {
        if !shouldShowTemperatureSection {
            temperatureValue = ""
            temperatureUnit = .celsius
            form.temperature = nil
        }
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

#Preview("Editing") {
    let store = PreviewHealthLogStore()
    let member = FamilyMember(name: "Jordan", notes: "Peanut allergy")
    _ = try? store.addMember(member)
    let event = HealthEvent(
        memberId: member.id,
        recordedAt: Date(),
        temperature: TemperatureReading(value: 38.4, unit: .celsius),
        symptoms: [Symptom(label: "Fever", isCustom: false), Symptom(label: "Body aches", isCustom: true)],
        notes: "Encourage rest"
    )
    _ = try? store.addEvent(event)
    return NavigationStack {
        HealthEventLoggerView(store: store, editingEvent: event)
    }
}
#endif
