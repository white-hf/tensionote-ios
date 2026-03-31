import Foundation

struct RecordInputValidator {
    func isValid(systolic: Int, diastolic: Int, heartRate: Int) -> Bool {
        (70...260).contains(systolic)
            && (40...180).contains(diastolic)
            && (30...220).contains(heartRate)
    }
}
