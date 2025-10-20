import Foundation

enum SymptomKind: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case fever
    case headache
    case soreThroat
    case cough
    case congestion
    case runnyNose
    case chills
    case fatigue
    case muscleAches
    case nausea

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .fever: return "symptom.fever"
        case .headache: return "symptom.headache"
        case .soreThroat: return "symptom.soreThroat"
        case .cough: return "symptom.cough"
        case .congestion: return "symptom.congestion"
        case .runnyNose: return "symptom.runnyNose"
        case .chills: return "symptom.chills"
        case .fatigue: return "symptom.fatigue"
        case .muscleAches: return "symptom.muscleAches"
        case .nausea: return "symptom.nausea"
        }
    }

    var defaultName: String {
        switch self {
        case .fever: return "Fever"
        case .headache: return "Headache"
        case .soreThroat: return "Sore throat"
        case .cough: return "Cough"
        case .congestion: return "Congestion"
        case .runnyNose: return "Runny nose"
        case .chills: return "Chills"
        case .fatigue: return "Fatigue"
        case .muscleAches: return "Muscle aches"
        case .nausea: return "Nausea"
        }
    }

    var localizedName: String {
        NSLocalizedString(localizationKey, tableName: nil, bundle: .main, value: defaultName, comment: "Localized symptom name")
    }

    static func matching(label: String) -> SymptomKind? {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return Self.allCases.first { kind in
            let localized = kind.localizedName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if localized == normalized { return true }
            return kind.defaultName.lowercased() == normalized
        }
    }
}
