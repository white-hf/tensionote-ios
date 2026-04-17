import UIKit

struct PDFReportExporter {
    func export(summary: ReportSummary, records: [BloodPressureRecord], days: Int) -> URL? {
        guard !records.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let timestamp = formatter.string(from: .now)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Tensionote-Report-\(days)-days-\(timestamp).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))

        do {
            try renderer.writePDF(to: outputURL) { context in
                context.beginPage()
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 22)
                ]
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14)
                ]

                NSString(string: L10n.tr("pdf_report_title")).draw(at: CGPoint(x: 32, y: 32), withAttributes: titleAttributes)
                NSString(string: "\(L10n.tr("pdf_report_range_label")): \(L10n.format("report_range_format_days", days))").draw(at: CGPoint(x: 32, y: 70), withAttributes: bodyAttributes)
                NSString(string: "\(L10n.tr("report_metric_count")): \(summary.count)").draw(at: CGPoint(x: 32, y: 95), withAttributes: bodyAttributes)
                NSString(string: "\(L10n.tr("pdf_report_average_label")): \(summary.averageSystolic) / \(summary.averageDiastolic)").draw(at: CGPoint(x: 32, y: 120), withAttributes: bodyAttributes)
                NSString(string: "\(L10n.tr("report_metric_average_heart_rate")): \(summary.averageHeartRate)").draw(at: CGPoint(x: 32, y: 145), withAttributes: bodyAttributes)

                var currentY: CGFloat = 190
                for record in records.prefix(12) {
                    let status = L10n.tr(record.regionalCategory.localizationKey)
                    let line = "\(record.measuredAt.formatted(date: .abbreviated, time: .shortened))  \(record.systolic)/\(record.diastolic)  \(record.heartRate)  \(status)"
                    NSString(string: line).draw(at: CGPoint(x: 32, y: currentY), withAttributes: bodyAttributes)
                    currentY += 22
                }
            }
            return outputURL
        } catch {
            return nil
        }
    }
}
