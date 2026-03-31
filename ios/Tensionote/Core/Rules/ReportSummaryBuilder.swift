import Foundation

struct ReportSummaryBuilder {
    func build(records: [BloodPressureRecord]) -> ReportSummary {
        guard !records.isEmpty else {
            return ReportSummary(count: 0, averageSystolic: 0, averageDiastolic: 0, averageHeartRate: 0)
        }

        let count = records.count
        let systolic = records.map(\.systolic).reduce(0, +) / count
        let diastolic = records.map(\.diastolic).reduce(0, +) / count
        let heartRate = records.map(\.heartRate).reduce(0, +) / count

        return ReportSummary(
            count: count,
            averageSystolic: systolic,
            averageDiastolic: diastolic,
            averageHeartRate: heartRate
        )
    }
}
