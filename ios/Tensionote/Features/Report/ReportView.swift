import SwiftUI
import MessageUI

struct ReportView: View {
    @ObservedObject var repository: InMemoryBloodPressureRepository
    @StateObject private var viewModel: ReportViewModel
    @State private var showShareSheet = false
    @State private var showMailComposer = false
    @State private var exportAlert: ExportAlert?

    struct ExportAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    init(repository: InMemoryBloodPressureRepository) {
        self.repository = repository
        _viewModel = StateObject(wrappedValue: ReportViewModel(repository: repository))
    }

    var body: some View {
        Form {
            Section(L10n.tr("report_range_title")) {
                Picker(L10n.tr("report_range_title"), selection: Binding(
                    get: { viewModel.selectedDays },
                    set: { viewModel.selectPresetDays($0) }
                )) {
                    Text(L10n.tr("report_range_7_days")).tag(7)
                    Text(L10n.tr("report_range_14_days")).tag(14)
                    Text(L10n.tr("report_range_30_days")).tag(30)
                }
                .pickerStyle(.segmented)

                if viewModel.isCustomRange {
                    Text(viewModel.rangeDisplayText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(L10n.tr("report_range_custom")) {
                        viewModel.enableCustomRange()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text(viewModel.rangeDisplayText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(L10n.tr("report_range_custom")) {
                        viewModel.enableCustomRange()
                    }
                }
            }

            if viewModel.isCustomRange {
                Section {
                    DatePicker(
                        L10n.tr("report_custom_from"),
                        selection: $viewModel.startDate,
                        in: ...viewModel.endDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        L10n.tr("report_custom_to"),
                        selection: $viewModel.endDate,
                        in: viewModel.startDate...Date(),
                        displayedComponents: .date
                    )
                }
            }

            Section(L10n.tr("report_summary_title")) {
                if viewModel.records.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.tr("report_empty_title"))
                            .font(.headline)
                        Text(L10n.tr("report_empty_body"))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    reportRow(titleKey: "report_metric_count", value: "\(viewModel.summary.count)")
                    reportRow(titleKey: "report_metric_average_systolic", value: "\(viewModel.summary.averageSystolic)")
                    reportRow(titleKey: "report_metric_average_diastolic", value: "\(viewModel.summary.averageDiastolic)")
                    reportRow(titleKey: "report_metric_average_heart_rate", value: "\(viewModel.summary.averageHeartRate)")
                }
            }

            if !viewModel.records.isEmpty {
                Section(L10n.tr("report_recent_records_title")) {
                    ForEach(viewModel.records.prefix(5)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.measuredAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("\(record.systolic)/\(record.diastolic)")
                            HStack {
                                Text(L10n.tr("metric_heart_rate"))
                                Spacer()
                                Text("\(record.heartRate)")
                            }
                            .font(.footnote)
                            Text(L10n.tr(record.status.localizationKey))
                                .font(.footnote)
                                .foregroundStyle(statusColor(for: record.status))
                        }
                    }
                }
            }

            Section {
                Button(L10n.tr("report_export_pdf")) {
                    viewModel.exportPDF()
                    handleExportState()
                }
                .disabled(viewModel.records.isEmpty)
                Button(L10n.tr("report_share_email")) {
                    if viewModel.exportedFileURL == nil {
                        viewModel.exportPDF()
                        handleExportState()
                    }
                    if MFMailComposeViewController.canSendMail(), viewModel.exportedFileURL != nil {
                        showMailComposer = viewModel.exportedFileURL != nil
                    } else if viewModel.exportedFileURL != nil {
                        showShareSheet = viewModel.exportedFileURL != nil
                    } else {
                        handleExportState()
                    }
                }
                .disabled(viewModel.records.isEmpty)
            }

            if let exportedFileName = viewModel.exportedFileName {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("report_export_result_prefix"))
                            .font(.headline)
                        Text(exportedFileName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("tab_report"))
        .onAppear {
            viewModel.reload()
        }
        .onReceive(repository.$records) { _ in
            viewModel.reload()
        }
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = viewModel.exportedFileURL {
                ShareSheet(items: [fileURL])
            }
        }
        .sheet(isPresented: $showMailComposer) {
            if let fileURL = viewModel.exportedFileURL {
                MailComposer(
                    subject: viewModel.emailSubject,
                    body: viewModel.emailBody,
                    attachmentURL: fileURL
                )
            }
        }
        .alert(item: $exportAlert) { payload in
            Alert(
                title: Text(payload.title),
                message: Text(payload.message),
                dismissButton: .default(Text(L10n.tr("common_back")))
            )
        }
    }

    private func reportRow(titleKey: String, value: String) -> some View {
        HStack {
            Text(L10n.tr(titleKey))
            Spacer()
            Text(value)
        }
    }

    private func statusColor(for status: BloodPressureStatus) -> Color {
        switch status {
        case .normal:
            return .green
        case .systolicHigh:
            return .red
        case .diastolicHigh:
            return .orange
        case .bothHigh:
            return .red.opacity(0.85)
        case .variability:
            return .purple
        }
    }

    private func handleExportState() {
        if let key = viewModel.exportStatusMessageKey {
            exportAlert = ExportAlert(
                title: L10n.tr("report_export_error_title"),
                message: L10n.tr(key)
            )
            viewModel.clearExportMessage()
        }
    }
}
