import Foundation

struct BloodPressureRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let systolic: Int
    let diastolic: Int
    let heartRate: Int
    let measuredAt: Date
    let tags: [String]
    let note: String?
    let status: BloodPressureStatus

    init(
        id: UUID = UUID(),
        systolic: Int,
        diastolic: Int,
        heartRate: Int,
        measuredAt: Date = .now,
        tags: [String] = [],
        note: String? = nil,
        status: BloodPressureStatus
    ) {
        self.id = id
        self.systolic = systolic
        self.diastolic = diastolic
        self.heartRate = heartRate
        self.measuredAt = measuredAt
        self.tags = tags
        self.note = note
        self.status = status
    }
}

enum BloodPressureStatus: String, Codable {
    case normal
    case systolicHigh
    case diastolicHigh
    case bothHigh
    case variability

    var localizationKey: String {
        switch self {
        case .normal:
            return "blood_pressure_status_normal"
        case .systolicHigh:
            return "blood_pressure_status_systolic_high"
        case .diastolicHigh:
            return "blood_pressure_status_diastolic_high"
        case .bothHigh:
            return "blood_pressure_status_both_high"
        case .variability:
            return "blood_pressure_status_variability"
        }
    }
}
