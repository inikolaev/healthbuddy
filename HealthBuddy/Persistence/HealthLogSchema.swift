import Foundation

enum HealthLogSchemaVersion: Int, Comparable {
    case legacy = 1
    case symptomKinds = 2

    static var current: HealthLogSchemaVersion { .symptomKinds }

    static func < (lhs: HealthLogSchemaVersion, rhs: HealthLogSchemaVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

protocol HealthLogMigrating {
    var fromVersion: HealthLogSchemaVersion { get }
    var toVersion: HealthLogSchemaVersion { get }
    func migrate(state: HealthLogState) -> HealthLogState
}

struct HealthLogMigrationPipeline {
    private static let migrations: [HealthLogMigrating] = [
        HealthLogMigrationV1toV2()
    ]

    static func migrate(state: HealthLogState) -> HealthLogState {
        var working = state
        var currentVersion = HealthLogSchemaVersion(rawValue: working.schemaVersion) ?? .legacy

        while currentVersion < HealthLogSchemaVersion.current {
            guard let migration = migrations.first(where: { $0.fromVersion == currentVersion }) else {
                break
            }
            working = migration.migrate(state: working)
            working.schemaVersion = migration.toVersion.rawValue
            currentVersion = migration.toVersion
        }

        if working.schemaVersion != HealthLogSchemaVersion.current.rawValue {
            working.schemaVersion = HealthLogSchemaVersion.current.rawValue
        }

        return working
    }
}

private struct HealthLogMigrationV1toV2: HealthLogMigrating {
    let fromVersion: HealthLogSchemaVersion = .legacy
    let toVersion: HealthLogSchemaVersion = .symptomKinds

    func migrate(state: HealthLogState) -> HealthLogState {
        var updated = state
        updated.events = state.events.map { event in
            var event = event
            event.symptoms = event.symptoms.map { symptom in
                if let kind = symptom.kind {
                    return Symptom(id: symptom.id, kind: kind)
                }
                if let custom = symptom.customLabel, let matched = SymptomKind.matching(label: custom) {
                    return Symptom(id: symptom.id, kind: matched)
                }
                if let matched = SymptomKind.matching(label: symptom.label) {
                    return Symptom(id: symptom.id, kind: matched)
                }
                if let custom = symptom.customLabel ?? (symptom.label.isEmpty ? nil : symptom.label) {
                    return Symptom(id: symptom.id, customLabel: custom)
                }
                return symptom
            }
            return event
        }
        updated.schemaVersion = toVersion.rawValue
        return updated
    }
}
