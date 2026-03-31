import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published private(set) var rangeDisplayText: String = L10n.tr("report_range_30_days")
    @Published var selectedDays: Int = 30 {
        didSet {
            guard !isRangeUpdateLocked else { return }
            reload()
        }
    }
    @Published var isCustomRange = false {
        didSet {
            guard !isRangeUpdateLocked else { return }
            reload()
        }
    }
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now {
        didSet {
            guard !isRangeUpdateLocked else { return }
            if endDate < startDate {
                endDate = startDate
            }
            reload()
        }
    }
    @Published var endDate: Date = .now {
        didSet {
            guard !isRangeUpdateLocked else { return }
            if endDate < startDate {
                startDate = endDate
            }
            reload()
        }
    }
    @Published private(set) var records: [BloodPressureRecord] = []
    @Published private(set) var summary = ReportSummary(count: 0, averageSystolic: 0, averageDiastolic: 0, averageHeartRate: 0)
    @Published private(set) var exportedFileName: String?
    @Published private(set) var exportedFileURL: URL?
    @Published private(set) var exportStatusMessageKey: String?

    private let repository: BloodPressureRepository
    private let builder = ReportSummaryBuilder()
    private let exporter = PDFReportExporter()
    private var isRangeUpdateLocked = false

    init(repository: BloodPressureRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        updateRangeDisplayText()
        if isCustomRange {
            records = repository.fetchRecords(from: startDate, to: endDate)
        } else {
            records = repository.fetchRecords(days: selectedDays)
        }
        summary = builder.build(records: records)
        exportedFileName = nil
        exportedFileURL = nil
        exportStatusMessageKey = nil
    }

    func selectPresetDays(_ days: Int) {
        performRangeUpdate {
            selectedDays = days
            isCustomRange = false
            startDate = Calendar.current.date(byAdding: .day, value: -(days - 1), to: .now) ?? .now
            endDate = .now
        }
    }

    func enableCustomRange() {
        performRangeUpdate {
            isCustomRange = true
            updateRangeDisplayText()
        }
    }

    func exportPDF() {
        guard !records.isEmpty else {
            exportStatusMessageKey = "report_export_empty"
            exportedFileName = nil
            exportedFileURL = nil
            return
        }

        let url = exporter.export(summary: summary, records: records, days: rangeDays)
        exportedFileURL = url
        exportedFileName = url?.lastPathComponent
        exportStatusMessageKey = url == nil ? "report_export_failed" : nil
    }

    func clearExportMessage() {
        exportStatusMessageKey = nil
    }

    var emailSubject: String {
        L10n.format("report_email_subject_format", rangeDays)
    }

    var emailBody: String {
        L10n.format(
            "report_email_body_format",
            rangeDays,
            summary.count,
            summary.averageSystolic,
            summary.averageDiastolic,
            summary.averageHeartRate
        )
    }

    var rangeDays: Int {
        if !isCustomRange { return selectedDays }
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        return (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    private func performRangeUpdate(_ updates: () -> Void) {
        isRangeUpdateLocked = true
        updates()
        isRangeUpdateLocked = false
        reload()
    }

    private func updateRangeDisplayText() {
        if isCustomRange {
            rangeDisplayText = "\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            rangeDisplayText = L10n.format("report_range_format_days", rangeDays)
        }
    }
}
