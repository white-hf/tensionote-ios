import Charts
import OSLog
import SwiftUI

struct HomeView: View {
    private enum Field: Hashable {
        case systolic
        case diastolic
        case heartRate
    }

    @StateObject private var viewModel: HomeViewModel
    @State private var showDetailedEntry = false
    @FocusState private var focusedField: Field?
    private let logger = Logger(subsystem: "com.tensionote.app", category: "home")

    init(repository: InMemoryBloodPressureRepository) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                repository: repository,
                evaluator: RegionalBloodPressureEvaluator()
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                quickEntryCard
                trendCard
            }
            .padding(20)
        }
        .navigationTitle(L10n.tr("app_name"))
        .background(Color(.systemGroupedBackground))
        .onAppear {
            logger.log("HomeView appeared")
            viewModel.reload()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.tr("common_done")) {
                    focusedField = nil
                }
            }
        }
        .navigationDestination(isPresented: $showDetailedEntry) {
            DetailedRecordView(
                repository: viewModel.repository,
                initialSystolic: viewModel.systolicInput,
                initialDiastolic: viewModel.diastolicInput,
                initialHeartRate: viewModel.heartRateInput,
                onSaved: {
                    viewModel.reload()
                }
            )
        }
    }

    private var quickEntryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.tr("home_quick_entry_title"))
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(L10n.tr("home_detailed_entry_button")) {
                    showDetailedEntry = true
                }
            }

            HStack(spacing: 12) {
                metricField(titleKey: "metric_systolic", text: $viewModel.systolicInput)
                metricField(titleKey: "metric_diastolic", text: $viewModel.diastolicInput)
            }

            metricField(titleKey: "metric_heart_rate", text: $viewModel.heartRateInput)

            Button(action: viewModel.saveQuickRecord) {
                Text(L10n.tr("common_save_now"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSaveQuickRecord)
            .simultaneousGesture(TapGesture().onEnded {
                focusedField = nil
            })

            if let validationMessageKey = viewModel.validationMessageKey {
                Text(L10n.tr(validationMessageKey))
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.tr("home_recent_two_weeks_trend"))
                    .font(.title2.weight(.semibold))
                Spacer()
                NavigationLink(L10n.tr("home_view_all_trend")) {
                    TrendView(records: viewModel.trendRecords)
                }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            if viewModel.trendRecords.isEmpty {
                Text(L10n.tr("trend_empty_title"))
                    .font(.headline)
                Text(L10n.tr("trend_empty_body"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let evaluator = RegionalBloodPressureEvaluator()
                Chart(viewModel.trendRecords) { record in
                    RuleMark(y: .value(L10n.tr("chart_axis_systolic"), evaluator.standard.hypertensionSystolicThreshold))
                        .foregroundStyle(.red.opacity(0.25))
                    RuleMark(y: .value(L10n.tr("chart_axis_diastolic"), evaluator.standard.hypertensionDiastolicThreshold))
                        .foregroundStyle(.orange.opacity(0.25))

                    LineMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_systolic"), record.systolic),
                        series: .value("Series", "systolic")
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_diastolic"), record.diastolic),
                        series: .value("Series", "diastolic")
                    )
                    .foregroundStyle(.teal)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_systolic"), record.systolic)
                    )
                    .foregroundStyle(record.regionalCategory.tintColor)

                    PointMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_diastolic"), record.diastolic)
                    )
                    .foregroundStyle(record.regionalCategory.tintColor)
                }
                .frame(height: 220)

                Text(L10n.tr(viewModel.displayCategory.localizationKey))
                    .font(.headline)
                    .foregroundStyle(viewModel.displayCategory.tintColor)

                Text(
                    L10n.format(
                        "trend_chart_legend_compact_rule",
                        evaluator.standard.hypertensionDiastolicThreshold
                    )
                )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(trendSummaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func metricField(titleKey: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr(titleKey))
                .font(.subheadline)
            TextField(L10n.tr("common_number_placeholder"), text: text)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: field(for: titleKey))
        }
    }

    private var trendSummaryText: String {
        let evaluator = RegionalBloodPressureEvaluator()
        let systolicHighCount = viewModel.trendRecords.filter {
            evaluator.standard.isSystolicAboveHypertensionThreshold($0.systolic)
        }.count
        let diastolicHighCount = viewModel.trendRecords.filter {
            evaluator.standard.isDiastolicAboveHypertensionThreshold($0.diastolic)
        }.count

        if systolicHighCount == 0 && diastolicHighCount == 0 {
            return L10n.tr("trend_summary_normal")
        }

        return L10n.format("trend_summary_counts", systolicHighCount, diastolicHighCount)
    }

    private func field(for titleKey: String) -> Field {
        switch titleKey {
        case "metric_systolic":
            return .systolic
        case "metric_diastolic":
            return .diastolic
        default:
            return .heartRate
        }
    }
}
