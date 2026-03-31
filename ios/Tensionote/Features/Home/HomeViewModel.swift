import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var systolicInput = "" {
        didSet {
            validationMessageKey = nil
            recalculateDraftStatus()
        }
    }
    @Published var diastolicInput = "" {
        didSet {
            validationMessageKey = nil
            recalculateDraftStatus()
        }
    }
    @Published var heartRateInput = "" {
        didSet { validationMessageKey = nil }
    }
    @Published private(set) var trendRecords: [BloodPressureRecord] = []
    @Published private(set) var selectedStatus: BloodPressureStatus = .normal
    @Published private(set) var draftStatus: BloodPressureStatus?
    @Published private(set) var validationMessageKey: String?

    let repository: BloodPressureRepository
    private let evaluator: BloodPressureStatusEvaluator
    private let validator = RecordInputValidator()

    init(repository: BloodPressureRepository, evaluator: BloodPressureStatusEvaluator) {
        self.repository = repository
        self.evaluator = evaluator
        reload()
        if let latest = trendRecords.last {
            selectedStatus = latest.status
        }
    }

    func reload() {
        trendRecords = repository.fetchRecentTwoWeeks()
        if let latest = trendRecords.last {
            selectedStatus = latest.status
        } else {
            selectedStatus = .normal
        }
    }

    func saveQuickRecord() {
        guard
            let systolic = Int(systolicInput),
            let diastolic = Int(diastolicInput),
            let heartRate = Int(heartRateInput)
        else {
            validationMessageKey = "validation_enter_valid_numbers"
            return
        }

        guard validator.isValid(systolic: systolic, diastolic: diastolic, heartRate: heartRate) else {
            validationMessageKey = "validation_out_of_range"
            return
        }

        let record = repository.saveQuickRecord(
            systolic: systolic,
            diastolic: diastolic,
            heartRate: heartRate
        )
        clearInputs()
        reload()
        selectedStatus = record.status
        draftStatus = nil
        validationMessageKey = nil
    }

    func selectRecord(_ record: BloodPressureRecord) {
        selectedStatus = record.status
    }

    var displayStatus: BloodPressureStatus {
        draftStatus ?? selectedStatus
    }

    var repositoryPublisher: AnyPublisher<[BloodPressureRecord], Never> {
        if let observableRepository = repository as? InMemoryBloodPressureRepository {
            return observableRepository.$records.eraseToAnyPublisher()
        }
        return Just([]).eraseToAnyPublisher()
    }

    private func clearInputs() {
        systolicInput = ""
        diastolicInput = ""
        heartRateInput = ""
    }

    private func recalculateDraftStatus() {
        guard
            let systolic = Int(systolicInput),
            let diastolic = Int(diastolicInput)
        else {
            draftStatus = nil
            return
        }
        draftStatus = evaluator.evaluate(systolic: systolic, diastolic: diastolic)
    }
}
