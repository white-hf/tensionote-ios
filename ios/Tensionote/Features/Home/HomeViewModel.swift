import Foundation
import Combine
import SwiftUI

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
    @Published private(set) var selectedCategory: BloodPressureCategory = .normal
    @Published private(set) var draftCategory: BloodPressureCategory?
    @Published private(set) var validationMessageKey: String?
    @Published var showSaveSuccess = false
    @Published private(set) var feedbackMessageKey: String?

    let repository: BloodPressureRepository
    private let evaluator: RegionalBloodPressureEvaluator
    private let validator = RecordInputValidator()

    init(repository: BloodPressureRepository, evaluator: RegionalBloodPressureEvaluator) {
        self.repository = repository
        self.evaluator = evaluator
        reload()
        if let latest = trendRecords.last {
            selectedCategory = latest.regionalCategory
        }
    }

    func reload() {
        withAnimation(.spring()) {
            trendRecords = repository.fetchRecentTwoWeeks()
            if let latest = trendRecords.last {
                selectedCategory = latest.regionalCategory
            } else {
                selectedCategory = .normal
            }
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

        let baseline = trendRecords
        let record = repository.saveQuickRecord(
            systolic: systolic,
            diastolic: diastolic,
            heartRate: heartRate
        )
        
        feedbackMessageKey = generateFeedback(for: record, baseline: baseline)

        withAnimation(.spring()) {
            clearInputs()
            reload()
            selectedCategory = record.regionalCategory
            draftCategory = nil
            validationMessageKey = nil
            showSaveSuccess = true
        }

        // Auto-hide success message after 4 seconds to give time to read feedback
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            withAnimation {
                showSaveSuccess = false
                feedbackMessageKey = nil
            }
        }
    }

    private func generateFeedback(for record: BloodPressureRecord, baseline: [BloodPressureRecord]) -> String {
        if baseline.isEmpty {
            return "feedback_first_record"
        }
        
        let avgSystolic = baseline.map { Double($0.systolic) }.reduce(0, +) / Double(baseline.count)
        
        if Double(record.systolic) > avgSystolic + 12 {
            return "feedback_sudden_high"
        }
        
        if Double(record.systolic) < avgSystolic - 8 {
            return "feedback_improving"
        }
        
        if record.regionalCategory == .normal {
            return "feedback_normal"
        }
        
        return "feedback_stable_high"
    }

    func selectRecord(_ record: BloodPressureRecord) {
        selectedCategory = record.regionalCategory
    }

    var displayCategory: BloodPressureCategory {
        draftCategory ?? selectedCategory
    }

    var canSaveQuickRecord: Bool {
        guard
            let systolic = Int(systolicInput),
            let diastolic = Int(diastolicInput),
            let heartRate = Int(heartRateInput)
        else {
            return false
        }
        return validator.isValid(systolic: systolic, diastolic: diastolic, heartRate: heartRate)
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
            draftCategory = nil
            return
        }
        draftCategory = evaluator.evaluate(systolic: systolic, diastolic: diastolic)
    }
}
