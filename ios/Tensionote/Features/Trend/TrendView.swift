import Charts
import SwiftUI

struct TrendView: View {
    let records: [BloodPressureRecord]
    @State private var selectedRecordID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if records.isEmpty {
                    ContentUnavailableView(
                        L10n.tr("trend_empty_title"),
                        systemImage: "chart.xyaxis.line",
                        description: Text(L10n.tr("trend_empty_body"))
                    )
                } else {
                    let evaluator = RegionalBloodPressureEvaluator()
                    Chart(records) { record in
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
                    .frame(height: 260)

                    if let selectedRecord {
                        let category = selectedRecord.regionalCategory
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.tr(category.localizationKey))
                                .font(.headline)
                                .foregroundStyle(category.tintColor)
                            Text(selectedRecord.measuredAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(selectedRecord.systolic)/\(selectedRecord.diastolic)")
                                .font(.title3.weight(.semibold))
                            HStack {
                                Text(L10n.tr("metric_heart_rate"))
                                Spacer()
                                Text("\(selectedRecord.heartRate)")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }

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

                    ForEach(Array(records.reversed())) { record in
                        Button {
                            selectedRecordID = record.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.measuredAt.formatted(date: .abbreviated, time: .omitted))
                                    Text(L10n.tr(record.regionalCategory.localizationKey))
                                        .font(.caption)
                                        .foregroundStyle(record.regionalCategory.tintColor)
                                }
                                Spacer()
                                Text("\(record.systolic)/\(record.diastolic)")
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(selectedRecordID == record.id ? record.regionalCategory.backgroundColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(L10n.tr("trend_title"))
        .onAppear {
            syncSelectedRecord()
        }
        .onChange(of: records) { _ in
            syncSelectedRecord()
        }
    }

    private var selectedRecord: BloodPressureRecord? {
        if let selectedRecordID,
           let record = records.first(where: { $0.id == selectedRecordID }) {
            return record
        }
        return records.last
    }

    private var trendSummaryText: String {
        let evaluator = RegionalBloodPressureEvaluator()
        let systolicHighCount = records.filter {
            evaluator.standard.isSystolicAboveHypertensionThreshold($0.systolic)
        }.count
        let diastolicHighCount = records.filter {
            evaluator.standard.isDiastolicAboveHypertensionThreshold($0.diastolic)
        }.count
        if systolicHighCount == 0 && diastolicHighCount == 0 {
            return L10n.tr("trend_summary_normal")
        }

        return L10n.format("trend_summary_counts", systolicHighCount, diastolicHighCount)
    }

    private func syncSelectedRecord() {
        if let selectedRecordID,
           records.contains(where: { $0.id == selectedRecordID }) {
            return
        }

        self.selectedRecordID = records.last?.id
    }
}
