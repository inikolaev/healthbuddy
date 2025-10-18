import SwiftUI

struct HealthEventLoggerView: View {
    @StateObject private var viewModel: HealthEventLoggerViewModel
    @State private var form = HealthEventForm()
    @State private var temperatureValue = ""
    @State private var temperatureUnit: TemperatureUnit = .celsius
    @State private var customSymptomInput = ""
    @State private var alertMessage: String?

    init(store: any HealthLogStoring) {
        _viewModel = StateObject(wrappedValue: HealthEventLoggerViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.members.isEmpty {
                    ContentUnavailableView(
                        "Add a Family Member",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Create at least one profile before logging temperature, symptoms, or medication.")
                    )
                } else {
                    Form {
                        memberSection
                        temperatureSection
                        symptomsSection
                        medicationsSection
                        notesSection
                        logButtonSection
                    }
                }
            }
            .navigationTitle("New Health Event")
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

    private var memberSection: some View {
        Section(header: Text("Family Member")) {
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
        Section(
            header: Text("Temperature"),
            footer: Text("Normal range is 35–37.4 °C (95.0–99.3 °F). Values outside 30–43 °C will be rejected.")
        ) {
            HStack {
                TextField("Value", text: $temperatureValue)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                Picker("Unit", selection: $temperatureUnit) {
                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                        Text(unit == .celsius ? "°C" : "°F").tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 120)
            }
            if let severity = currentSeverity {
                TemperatureSeverityBadge(severity: severity)
            }
        }
    }

    private var symptomsSection: some View {
        Section(
            header: Text("Symptoms"),
            footer: Text("Tap a custom symptom to remove it. We'll avoid duplicates automatically.")
        ) {
            ForEach(viewModel.symptomLibrary, id: \.self) { symptom in
                Toggle(symptom, isOn: Binding(
                    get: { form.symptomLabels.contains(symptom) },
                    set: { isOn in
                        if isOn {
                            if !form.symptomLabels.contains(symptom) {
                                form.symptomLabels.append(symptom)
                            }
                        } else {
                            form.symptomLabels.removeAll { $0 == symptom }
                        }
                    }
                ))
            }

            if !form.customSymptoms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(form.customSymptoms.enumerated()), id: \.element) { index, label in
                            Label(label, systemImage: "xmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.footnote)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.gray.opacity(0.2)))
                                .onTapGesture {
                                    form.customSymptoms.remove(at: index)
                                }
                        }
                    }
                }
            }

            HStack {
                TextField("Add custom symptom", text: $customSymptomInput)
                Button("Add") {
                    addCustomSymptom()
                }
                .disabled(customSymptomInput.trimmed.isEmpty)
            }
        }
    }

    private var medicationsSection: some View {
        Section(header: Text("Medication")) {
            TextField("Medication given", text: Binding(
                get: { form.medications ?? "" },
                set: { form.medications = $0 }
            ))
            .autocorrectionDisabled()
        }
    }

    private var notesSection: some View {
        Section(header: Text("Notes")) {
            TextField("Additional context (diet, rest, etc.)", text: Binding(
                get: { form.notes ?? "" },
                set: { form.notes = $0 }
            ), axis: .vertical)
        }
    }

    private var logButtonSection: some View {
        Section {
            Button {
                logEvent()
            } label: {
                Text("Save Health Event")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
        }
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
        form.memberId != nil && temperatureReading != nil
    }

    private func addCustomSymptom() {
        let trimmed = customSymptomInput.trimmed
        guard !trimmed.isEmpty else { return }
        if !form.customSymptoms.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            form.customSymptoms.append(trimmed)
        }
        customSymptomInput = ""
    }

    private func logEvent() {
        guard let reading = temperatureReading else {
            alertMessage = "Please enter a valid temperature."
            return
        }

        var workingForm = form
        workingForm.temperature = reading

        do {
            try viewModel.logEvent(using: workingForm)
            resetForm()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func resetForm() {
        form = HealthEventForm(memberId: form.memberId)
        temperatureValue = ""
        temperatureUnit = .celsius
        customSymptomInput = ""
    }
}

#if DEBUG
#Preview {
    let store = PreviewHealthLogStore()
    _ = try? store.addMember(FamilyMember(name: "Jordan", notes: "Peanut allergy"))
    _ = try? store.addMember(FamilyMember(name: "Lena"))
    return HealthEventLoggerView(store: store)
}
#endif
