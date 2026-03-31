import SwiftUI

struct HistoryView: View {
    @ObservedObject var repository: InMemoryBloodPressureRepository

    var body: some View {
        Group {
            if repository.fetchAll().isEmpty {
                ContentUnavailableView(
                    L10n.tr("history_empty_title"),
                    systemImage: "list.bullet.rectangle",
                    description: Text(L10n.tr("history_empty_body"))
                )
            } else {
                List {
                    ForEach(repository.fetchAll()) { record in
                        NavigationLink {
                            RecordDetailView(record: record, onDelete: nil, repository: repository)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(record.measuredAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(record.systolic)/\(record.diastolic)")
                                        .font(.headline)
                                    Spacer()
                                    Text(L10n.tr(record.status.localizationKey))
                                        .font(.subheadline)
                                        .foregroundStyle(statusColor(for: record.status))
                                }

                                HStack {
                                    Text(L10n.tr("metric_heart_rate"))
                                    Spacer()
                                    Text("\(record.heartRate)")
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete { offsets in
                        let currentRecords = repository.fetchAll()
                        offsets.map { currentRecords[$0].id }.forEach(repository.deleteRecord)
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("history_title"))
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
