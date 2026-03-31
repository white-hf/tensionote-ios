import Foundation

struct BloodPressureStatusEvaluator {
    func evaluate(systolic: Int, diastolic: Int) -> BloodPressureStatus {
        let systolicHigh = systolic >= 140
        let diastolicHigh = diastolic >= 90

        switch (systolicHigh, diastolicHigh) {
        case (true, true):
            return .bothHigh
        case (true, false):
            return .systolicHigh
        case (false, true):
            return .diastolicHigh
        default:
            return .normal
        }
    }
}
