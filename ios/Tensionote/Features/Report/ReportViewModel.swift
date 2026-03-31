import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published var selectedDays: Int = 30 {
        didSet { reload() }
    }
    @Published var isCustomRange = false {
        didSet { reload() }
    }
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now {
        didSet {
            if endDate < startDate {
                endDate = startDate
            }
            reload()
        }
    }
    @Published var endDate: Date = .now {
        didSet {
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

    private let repository: BloodPressureRepository
    private let builder = ReportSummaryBuilder()
    private let exporter = PDFReportExporter()

    init(repository: BloodPressureRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        if isCustomRange {
            records = repository.fetchRecords(from: startDate, to: endDate)
        } else {
            records = repository.fetchRecords(days: selectedDays)
        }
        summary = builder.build(records: records)
        exportedFileName = nil
        exportedFileURL = nil
    }

    func selectPresetDays(_ days: Int) {
        selectedDays = days
        isCustomRange = false
        startDate = Calendar.current.date(byAdding: .day, value: -(days - 1), to: .now) ?? .now
        endDate = .now
    }

    func enableCustomRange() {
        isCustomRange = true
    }

    func exportPDF() {
        let url = exporter.export(summary: summary, records: records, days: rangeDays)
        exportedFileURL = url
        exportedFileName = url?.lastPathComponent
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
}
