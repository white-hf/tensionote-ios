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
                    Chart(records) { record in
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
                    .frame(height: 260)

                    if let selectedRecord {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.tr(selectedRecord.status.localizationKey))
                                .font(.headline)
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

                    Text(L10n.tr("trend_chart_legend"))
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
                                    Text(L10n.tr(record.status.localizationKey))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(record.systolic)/\(record.diastolic)")
                            }
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
        let systolicHighCount = records.filter { $0.status == .systolicHigh || $0.status == .bothHigh }.count
        let diastolicHighCount = records.filter { $0.status == .diastolicHigh || $0.status == .bothHigh }.count
        if systolicHighCount == 0 && diastolicHighCount == 0 {
            return L10n.tr("trend_summary_normal")
        }

        return L10n.format("trend_summary_counts", systolicHighCount, diastolicHighCount)
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

    private func syncSelectedRecord() {
        if let selectedRecordID,
           records.contains(where: { $0.id == selectedRecordID }) {
            return
        }

        self.selectedRecordID = records.last?.id
    }
}
