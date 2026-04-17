import SwiftUI

enum BloodPressureRegionalStandard {
    case unitedStates
    case europe
    case unitedKingdom
    case japan
    case whoDefault

    static var current: BloodPressureRegionalStandard {
        let regionCode = Locale.autoupdatingCurrent.region?.identifier.uppercased() ?? ""
        switch regionCode {
        case "US":
            return .unitedStates
        case "GB":
            return .unitedKingdom
        case "JP":
            return .japan
        case "CN":
            return .whoDefault
        case "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE",
             "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT",
             "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "CH":
            return .europe
        default:
            return .whoDefault
        }
    }

    var hypertensionSystolicThreshold: Int {
        switch self {
        case .unitedStates:
            return 130
        case .europe, .unitedKingdom, .japan, .whoDefault:
            return 140
        }
    }

    var hypertensionDiastolicThreshold: Int {
        switch self {
        case .unitedStates:
            return 80
        case .europe, .unitedKingdom, .japan, .whoDefault:
            return 90
        }
    }

    func isSystolicAboveHypertensionThreshold(_ systolic: Int) -> Bool {
        systolic >= hypertensionSystolicThreshold
    }

    func isDiastolicAboveHypertensionThreshold(_ diastolic: Int) -> Bool {
        diastolic >= hypertensionDiastolicThreshold
    }
}

enum BloodPressureCategory {
    case normal
    case highNormal
    case elevated
    case stage1Hypertension
    case stage2Hypertension
    case hypertension
    case grade1Hypertension
    case grade2Hypertension
    case grade3Hypertension
    case severeHypertension
    case hypertensiveCrisis

    var localizationKey: String {
        switch self {
        case .normal:
            return "blood_pressure_category_normal"
        case .highNormal:
            return "blood_pressure_category_high_normal"
        case .elevated:
            return "blood_pressure_category_elevated"
        case .stage1Hypertension:
            return "blood_pressure_category_stage_1_hypertension"
        case .stage2Hypertension:
            return "blood_pressure_category_stage_2_hypertension"
        case .hypertension:
            return "blood_pressure_category_hypertension"
        case .grade1Hypertension:
            return "blood_pressure_category_grade_1_hypertension"
        case .grade2Hypertension:
            return "blood_pressure_category_grade_2_hypertension"
        case .grade3Hypertension:
            return "blood_pressure_category_grade_3_hypertension"
        case .severeHypertension:
            return "blood_pressure_category_severe_hypertension"
        case .hypertensiveCrisis:
            return "blood_pressure_category_hypertensive_crisis"
        }
    }

    var tintColor: Color {
        switch self {
        case .normal:
            return Color(red: 0.18, green: 0.49, blue: 0.20)
        case .highNormal, .elevated:
            return Color(red: 0.76, green: 0.54, blue: 0.00)
        case .stage1Hypertension, .grade1Hypertension:
            return Color(red: 0.94, green: 0.42, blue: 0.00)
        case .stage2Hypertension, .hypertension, .grade2Hypertension, .severeHypertension:
            return Color(red: 0.78, green: 0.16, blue: 0.16)
        case .grade3Hypertension, .hypertensiveCrisis:
            return Color(red: 0.56, green: 0.10, blue: 0.10)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .normal:
            return Color(red: 0.92, green: 0.96, blue: 0.93)
        case .highNormal, .elevated:
            return Color(red: 1.00, green: 0.96, blue: 0.84)
        case .stage1Hypertension, .grade1Hypertension:
            return Color(red: 1.00, green: 0.90, blue: 0.82)
        case .stage2Hypertension, .hypertension, .grade2Hypertension, .severeHypertension:
            return Color(red: 0.97, green: 0.84, blue: 0.85)
        case .grade3Hypertension, .hypertensiveCrisis:
            return Color(red: 0.95, green: 0.77, blue: 0.79)
        }
    }
}

struct BloodPressureAssessment {
    let standard: BloodPressureRegionalStandard
    let category: BloodPressureCategory
}

struct RegionalBloodPressureEvaluator {
    let standard: BloodPressureRegionalStandard

    init(standard: BloodPressureRegionalStandard = .current) {
        self.standard = standard
    }

    func evaluate(systolic: Int, diastolic: Int) -> BloodPressureCategory {
        switch standard {
        case .unitedStates:
            if systolic >= 180 || diastolic >= 120 {
                return .hypertensiveCrisis
            }
            if systolic >= 140 || diastolic >= 90 {
                return .stage2Hypertension
            }
            if systolic >= 130 || diastolic >= 80 {
                return .stage1Hypertension
            }
            if (120...129).contains(systolic) && diastolic < 80 {
                return .elevated
            }
            return .normal

        case .europe:
            if systolic >= 180 || diastolic >= 120 {
                return .hypertensiveCrisis
            }
            if systolic >= 140 || diastolic >= 90 {
                return .hypertension
            }
            if systolic < 120 && diastolic < 70 {
                return .normal
            }
            return .elevated

        case .unitedKingdom:
            if systolic >= 180 || diastolic >= 120 {
                return .severeHypertension
            }
            if systolic >= 160 || diastolic >= 100 {
                return .stage2Hypertension
            }
            if systolic >= 140 || diastolic >= 90 {
                return .stage1Hypertension
            }
            return .normal

        case .japan:
            if systolic >= 180 || diastolic >= 110 {
                return .grade3Hypertension
            }
            if systolic >= 160 || diastolic >= 100 {
                return .grade2Hypertension
            }
            if systolic >= 140 || diastolic >= 90 {
                return .grade1Hypertension
            }
            if systolic >= 130 || diastolic >= 80 {
                return .elevated
            }
            if (120...129).contains(systolic) && diastolic < 80 {
                return .highNormal
            }
            return .normal

        case .whoDefault:
            if systolic >= 180 || diastolic >= 110 {
                return .grade3Hypertension
            }
            if systolic >= 160 || diastolic >= 100 {
                return .grade2Hypertension
            }
            if systolic >= 140 || diastolic >= 90 {
                return .grade1Hypertension
            }
            return .normal
        }
    }

    func assess(systolic: Int, diastolic: Int) -> BloodPressureAssessment {
        BloodPressureAssessment(
            standard: standard,
            category: evaluate(systolic: systolic, diastolic: diastolic)
        )
    }
}

extension BloodPressureRecord {
    var regionalAssessment: BloodPressureAssessment {
        RegionalBloodPressureEvaluator().assess(systolic: systolic, diastolic: diastolic)
    }

    var regionalCategory: BloodPressureCategory {
        regionalAssessment.category
    }
}
