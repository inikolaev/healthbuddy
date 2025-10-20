import Foundation

extension FamilyProfilesError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return NSLocalizedString("Please enter a name before saving.", comment: "Validation error when member name is missing")
        }
    }
}

extension HealthEventLoggerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingMemberSelection:
            return NSLocalizedString("Select a family member before logging an event.", comment: "Error when member is not selected for health event")
        case .invalidTemperature:
            return NSLocalizedString("Temperature must be between 30 °C and 43 °C.", comment: "Error when temperature is outside supported range")
        case .memberNotFound:
            return NSLocalizedString("The selected family member could not be found.", comment: "Error when related member is missing")
        case .eventNotFound:
            return NSLocalizedString("We couldn't find that health event.", comment: "Error when health event is missing")
        }
    }
}

extension HealthLogStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingMember:
            return NSLocalizedString("The selected family member could not be found.", comment: "Store error when member id is missing")
        case .missingEvent:
            return NSLocalizedString("The health event no longer exists.", comment: "Store error when event id is missing")
        }
    }
}
