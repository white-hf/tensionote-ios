import Charts
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showDetailedEntry = false

    init(repository: InMemoryBloodPressureRepository) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                repository: repository,
                evaluator: BloodPressureStatusEvaluator()
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
            viewModel.reload()
        }
        .onReceive(viewModel.repositoryPublisher) { _ in
            viewModel.reload()
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
                Chart(viewModel.trendRecords) { record in
                    RuleMark(y: .value(L10n.tr("chart_axis_systolic"), 140))
                        .foregroundStyle(.red.opacity(0.25))
                    RuleMark(y: .value(L10n.tr("chart_axis_diastolic"), 90))
                        .foregroundStyle(.orange.opacity(0.25))

                    LineMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_systolic"), record.systolic)
                    )
                    .foregroundStyle(.blue)

                    LineMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_diastolic"), record.diastolic)
                    )
                    .foregroundStyle(.teal)

                    PointMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_systolic"), record.systolic)
                    )
                    .foregroundStyle(pointColor(for: record.status))

                    PointMark(
                        x: .value(L10n.tr("chart_axis_date"), record.measuredAt),
                        y: .value(L10n.tr("chart_axis_diastolic"), record.diastolic)
                    )
                    .foregroundStyle(pointColor(for: record.status))
                }
                .frame(height: 220)

                Text(L10n.tr(viewModel.displayStatus.localizationKey))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(L10n.tr("trend_chart_legend"))
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
        }
    }

    private func pointColor(for status: BloodPressureStatus) -> Color {
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

    private var trendSummaryText: String {
        let systolicHighCount = viewModel.trendRecords.filter { $0.status == .systolicHigh || $0.status == .bothHigh }.count
        let diastolicHighCount = viewModel.trendRecords.filter { $0.status == .diastolicHigh || $0.status == .bothHigh }.count

        if systolicHighCount == 0 && diastolicHighCount == 0 {
            return L10n.tr("trend_summary_normal")
        }

        return L10n.format("trend_summary_counts", systolicHighCount, diastolicHighCount)
    }
}
