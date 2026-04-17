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
        let category = record.regionalCategory
        return VStack(alignment: .leading, spacing: 8) {
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

                    Text(L10n.tr(category.localizationKey))
                        .font(.subheadline)
                        .foregroundStyle(category.tintColor)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(record.systolic)/\(record.diastolic)")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text(L10n.tr(category.localizationKey))
                        .font(.subheadline)
                        .foregroundStyle(category.tintColor)
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
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .background(category.backgroundColor)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(category.tintColor)
                .frame(width: 6)
                .padding(.vertical, 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
