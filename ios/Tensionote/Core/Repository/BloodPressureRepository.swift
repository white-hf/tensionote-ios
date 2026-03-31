import Foundation

protocol BloodPressureRepository: AnyObject {
    func saveQuickRecord(systolic: Int, diastolic: Int, heartRate: Int) -> BloodPressureRecord
    func saveDetailedRecord(
        systolic: Int,
        diastolic: Int,
        heartRate: Int,
        measuredAt: Date,
        tags: [String],
        note: String?
    ) -> BloodPressureRecord
    func fetchRecentTwoWeeks() -> [BloodPressureRecord]
    func fetchAll() -> [BloodPressureRecord]
    func fetchRecords(days: Int) -> [BloodPressureRecord]
    func fetchRecords(from startDate: Date, to endDate: Date) -> [BloodPressureRecord]
    func fetchRecord(id: UUID) -> BloodPressureRecord?
    func deleteRecord(id: UUID)
    func updateRecord(
        id: UUID,
        systolic: Int,
        diastolic: Int,
        heartRate: Int,
        measuredAt: Date,
        tags: [String],
        note: String?
    )
}

final class InMemoryBloodPressureRepository: ObservableObject, BloodPressureRepository {
    @Published private(set) var records: [BloodPressureRecord] = []
    private let evaluator = BloodPressureStatusEvaluator()
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = documentsDirectory.appendingPathComponent("tensionote_records.json")
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadRecords()
    }

    func saveQuickRecord(systolic: Int, diastolic: Int, heartRate: Int) -> BloodPressureRecord {
        let status = evaluator.evaluate(systolic: systolic, diastolic: diastolic)
        let record = BloodPressureRecord(
            systolic: systolic,
            diastolic: diastolic,
            heartRate: heartRate,
            measuredAt: .now,
            status: status
        )
        records.insert(record, at: 0)
        persist()
        return record
    }

    func saveDetailedRecord(
        systolic: Int,
        diastolic: Int,
        heartRate: Int,
        measuredAt: Date,
        tags: [String],
        note: String?
    ) -> BloodPressureRecord {
        let status = evaluator.evaluate(systolic: systolic, diastolic: diastolic)
        let record = BloodPressureRecord(
            systolic: systolic,
            diastolic: diastolic,
            heartRate: heartRate,
            measuredAt: measuredAt,
            tags: tags,
            note: note,
            status: status
        )
        records.insert(record, at: 0)
        persist()
        return record
    }

    func fetchRecentTwoWeeks() -> [BloodPressureRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .distantPast
        return records
            .filter { $0.measuredAt >= cutoff }
            .sorted { $0.measuredAt < $1.measuredAt }
    }

    func fetchAll() -> [BloodPressureRecord] {
        records.sorted { $0.measuredAt > $1.measuredAt }
    }

    func fetchRecords(days: Int) -> [BloodPressureRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        return records
            .filter { $0.measuredAt >= cutoff }
            .sorted { $0.measuredAt > $1.measuredAt }
    }

    func fetchRecords(from startDate: Date, to endDate: Date) -> [BloodPressureRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        return records
            .filter { $0.measuredAt >= startOfDay && $0.measuredAt < endExclusive }
            .sorted { $0.measuredAt > $1.measuredAt }
    }

    func fetchRecord(id: UUID) -> BloodPressureRecord? {
        records.first(where: { $0.id == id })
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    func updateRecord(
        id: UUID,
        systolic: Int,
        diastolic: Int,
        heartRate: Int,
        measuredAt: Date,
        tags: [String],
        note: String?
    ) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index] = BloodPressureRecord(
            id: id,
            systolic: systolic,
            diastolic: diastolic,
            heartRate: heartRate,
            measuredAt: measuredAt,
            tags: tags,
            note: note,
            status: evaluator.evaluate(systolic: systolic, diastolic: diastolic)
        )
        persist()
    }

    private func loadRecords() {
        guard let data = try? Data(contentsOf: fileURL),
              let decodedRecords = try? decoder.decode([BloodPressureRecord].self, from: data),
              !decodedRecords.isEmpty
        else {
            records = []
            return
        }
        records = decodedRecords.sorted { $0.measuredAt > $1.measuredAt }
    }

    private func persist() {
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
