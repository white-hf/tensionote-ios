import SwiftUI
import MessageUI

struct ReportView: View {
    @ObservedObject var repository: InMemoryBloodPressureRepository
    @StateObject private var viewModel: ReportViewModel
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
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
                        let category = record.regionalCategory
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
                            Text(L10n.tr(category.localizationKey))
                                .font(.footnote)
                                .foregroundStyle(category.tintColor)
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, 14)
                        .padding(.trailing, 8)
                        .background(category.backgroundColor)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(category.tintColor)
                                .frame(width: 6)
                                .padding(.vertical, 6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            Section {
                Button(L10n.tr("report_export_pdf")) {
                    exportAndPresentShareSheet()
                }
                .disabled(viewModel.records.isEmpty)
                Button(L10n.tr("report_share_email")) {
                    guard let fileURL = prepareExportedPDF() else {
                        return
                    }

                    shareItems = [
                        EmailShareItemSource(
                            subject: viewModel.emailSubject,
                            body: viewModel.emailBody
                        ),
                        fileURL
                    ]
                    showShareSheet = true
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
                        Text(L10n.tr("report_export_saved_hint"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("tab_report"))
        .onAppear {
            viewModel.reload()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .onChange(of: showShareSheet) { isPresented in
            if !isPresented {
                shareItems = []
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

    private func handleExportState() {
        if let key = viewModel.exportStatusMessageKey {
            exportAlert = ExportAlert(
                title: L10n.tr("report_export_error_title"),
                message: L10n.tr(key)
            )
            viewModel.clearExportMessage()
        }
    }

    private func prepareExportedPDF() -> URL? {
        viewModel.exportPDF()
        handleExportState()
        return viewModel.exportedFileURL
    }

    private func exportAndPresentShareSheet() {
        guard let fileURL = prepareExportedPDF() else {
            return
        }
        shareItems = [fileURL]
        showShareSheet = true
    }
}
