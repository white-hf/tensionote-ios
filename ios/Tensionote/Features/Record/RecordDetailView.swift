import Combine
import SwiftUI

struct RecordDetailView: View {
    @State var record: BloodPressureRecord
    let onDelete: (() -> Void)?
    let repository: BloodPressureRepository?
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        Form {
            Section(L10n.tr("record_detail_result_section")) {
                metricSummaryRow
            }

            Section(L10n.tr("record_detail_info_section")) {
                detailRow(
                    titleKey: "record_measured_at",
                    value: currentRecord.measuredAt.formatted(date: .abbreviated, time: .shortened)
                )
                if !currentRecord.tags.isEmpty {
                    detailRow(
                        titleKey: "record_tags_section",
                        value: TagLocalization.localizedLabels(for: currentRecord.tags)
                    )
                }
                if let note = currentRecord.note, !note.isEmpty {
                    detailRow(titleKey: "record_note", value: note)
                }
            }

            if let repository {
                Section {
                    Button(L10n.tr("record_delete_button"), role: .destructive) {
                        repository.deleteRecord(id: currentRecord.id)
                        onDelete?()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("record_detail_title"))
        .toolbar {
            if let repository {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("record_edit_title")) {
                        showEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let repository {
                NavigationStack {
                    EditRecordView(repository: repository, record: currentRecord) { updatedRecord in
                        record = updatedRecord
                    }
                }
                .id(currentRecord.id)
            }
        }
        .onReceive(repositoryPublisher) { _ in
            guard let repository else { return }
            if let refreshed = repository.fetchRecord(id: record.id) {
                record = refreshed
            } else {
                dismiss()
            }
        }
    }

    private var currentRecord: BloodPressureRecord {
        repository?.fetchRecord(id: record.id) ?? record
    }

    private var metricSummaryRow: some View {
        let category = currentRecord.regionalCategory
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("metric_systolic"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("\(currentRecord.systolic)")
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("metric_diastolic"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("\(currentRecord.diastolic)")
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("metric_heart_rate"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("\(currentRecord.heartRate)")
                        .font(.title3.weight(.semibold))
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(L10n.tr("record_status_preview"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(L10n.tr(category.localizationKey))
                        .font(.headline)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(category.tintColor)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                labeledMetric(titleKey: "metric_systolic", value: "\(currentRecord.systolic)")
                labeledMetric(titleKey: "metric_diastolic", value: "\(currentRecord.diastolic)")
                labeledMetric(titleKey: "metric_heart_rate", value: "\(currentRecord.heartRate)")
                labeledMetric(titleKey: "record_status_preview", value: L10n.tr(category.localizationKey), tintColor: category.tintColor)
            }
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var repositoryPublisher: AnyPublisher<[BloodPressureRecord], Never> {
        if let observableRepository = repository as? InMemoryBloodPressureRepository {
            return observableRepository.$records.eraseToAnyPublisher()
        }
        return Just([]).eraseToAnyPublisher()
    }

    private func detailRow(titleKey: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                Text(L10n.tr(titleKey))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr(titleKey))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(value)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private func labeledMetric(titleKey: String, value: String, tintColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tr(titleKey))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(titleKey == "record_status_preview" ? .headline : .title3.weight(.semibold))
                .multilineTextAlignment(.leading)
                .foregroundStyle(titleKey == "record_status_preview" ? tintColor : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
