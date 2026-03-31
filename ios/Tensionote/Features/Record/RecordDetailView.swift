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
                detailRow(titleKey: "metric_systolic", value: "\(currentRecord.systolic)")
                detailRow(titleKey: "metric_diastolic", value: "\(currentRecord.diastolic)")
                detailRow(titleKey: "metric_heart_rate", value: "\(currentRecord.heartRate)")
                detailRow(
                    titleKey: "record_status_preview",
                    value: L10n.tr(currentRecord.status.localizationKey)
                )
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

    private var repositoryPublisher: AnyPublisher<[BloodPressureRecord], Never> {
        if let observableRepository = repository as? InMemoryBloodPressureRepository {
            return observableRepository.$records.eraseToAnyPublisher()
        }
        return Just([]).eraseToAnyPublisher()
    }

    private func detailRow(titleKey: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(L10n.tr(titleKey))
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
    }
}
