import SwiftUI

struct HistoryView: View {
    @ObservedObject var repository: InMemoryBloodPressureRepository

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    L10n.tr("history_empty_title"),
                    systemImage: "list.bullet.rectangle",
                    description: Text(L10n.tr("history_empty_body"))
                )
            } else {
                List {
                    ForEach(records) { record in
                        NavigationLink {
                            RecordDetailView(record: record, onDelete: nil, repository: repository)
                        } label: {
                            recordRow(record)
                        }
                    }
                    .onDelete { offsets in
                        let currentRecords = records
                        offsets.map { currentRecords[$0].id }.forEach(repository.deleteRecord)
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("history_title"))
    }

    private var records: [BloodPressureRecord] {
        repository.fetchAll()
    }

    private func recordRow(_ record: BloodPressureRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.measuredAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(record.systolic)/\(record.diastolic)")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(L10n.tr("metric_heart_rate"))
                            Text("\(record.heartRate)")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(L10n.tr(record.status.localizationKey))
                        .font(.subheadline)
                        .foregroundStyle(statusColor(for: record.status))
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(record.systolic)/\(record.diastolic)")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text(L10n.tr(record.status.localizationKey))
                        .font(.subheadline)
                        .foregroundStyle(statusColor(for: record.status))
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(L10n.tr("metric_heart_rate"))
                        Text("\(record.heartRate)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
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
}
