import SwiftUI

struct DetailedRecordView: View {
    let repository: BloodPressureRepository
    let initialSystolic: String
    let initialDiastolic: String
    let initialHeartRate: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var systolic: String
    @State private var diastolic: String
    @State private var heartRate: String
    @State private var measuredAt = Date()
    @State private var note = ""
    @State private var selectedTags: Set<String> = []
    @State private var validationMessageKey: String?
    private let validator = RecordInputValidator()
    private let evaluator = BloodPressureStatusEvaluator()

    private let tagKeys = [
        "tag_morning",
        "tag_afternoon",
        "tag_evening",
        "tag_after_meal",
        "tag_after_exercise",
        "tag_after_medication",
        "tag_discomfort"
    ]

    init(
        repository: BloodPressureRepository,
        initialSystolic: String = "",
        initialDiastolic: String = "",
        initialHeartRate: String = "",
        onSaved: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.initialSystolic = initialSystolic
        self.initialDiastolic = initialDiastolic
        self.initialHeartRate = initialHeartRate
        self.onSaved = onSaved
        _systolic = State(initialValue: initialSystolic)
        _diastolic = State(initialValue: initialDiastolic)
        _heartRate = State(initialValue: initialHeartRate)
    }

    var body: some View {
        Form {
            Section(L10n.tr("record_basic_section")) {
                TextField(L10n.tr("metric_systolic"), text: Binding(
                    get: { systolic },
                    set: {
                        systolic = $0
                        validationMessageKey = nil
                    }
                ))
                    .keyboardType(.numberPad)
                TextField(L10n.tr("metric_diastolic"), text: Binding(
                    get: { diastolic },
                    set: {
                        diastolic = $0
                        validationMessageKey = nil
                    }
                ))
                    .keyboardType(.numberPad)
                TextField(L10n.tr("metric_heart_rate"), text: Binding(
                    get: { heartRate },
                    set: {
                        heartRate = $0
                        validationMessageKey = nil
                    }
                ))
                    .keyboardType(.numberPad)
                DatePicker(L10n.tr("record_measured_at"), selection: $measuredAt)
            }

            Section(L10n.tr("record_tags_section")) {
                ForEach(tagKeys, id: \.self) { key in
                    Button {
                        if selectedTags.contains(key) {
                            selectedTags.remove(key)
                        } else {
                            selectedTags.insert(key)
                        }
                    } label: {
                        HStack {
                            Text(L10n.tr(key))
                            Spacer()
                            if selectedTags.contains(key) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(L10n.tr("record_extra_section")) {
                TextField(L10n.tr("record_note"), text: Binding(
                    get: { note },
                    set: {
                        note = $0
                        validationMessageKey = nil
                    }
                ), axis: .vertical)
            }

            Section(L10n.tr("record_detail_result_section")) {
                HStack {
                    Text(L10n.tr("record_status_preview"))
                    Spacer()
                    Text(L10n.tr(previewStatus.localizationKey))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            }

            if let validationMessageKey {
                Section {
                    Text(L10n.tr(validationMessageKey))
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(L10n.tr("record_save_button")) {
                    saveRecord()
                }
            }
            .disabled(!canSaveRecord)
        }
        .navigationTitle(L10n.tr("home_detailed_entry_button"))
    }

    private func saveRecord() {
        guard
            let systolicValue = Int(systolic),
            let diastolicValue = Int(diastolic),
            let heartRateValue = Int(heartRate)
        else {
            validationMessageKey = "validation_enter_valid_numbers"
            return
        }

        guard validator.isValid(systolic: systolicValue, diastolic: diastolicValue, heartRate: heartRateValue) else {
            validationMessageKey = "validation_out_of_range"
            return
        }

        _ = repository.saveDetailedRecord(
            systolic: systolicValue,
            diastolic: diastolicValue,
            heartRate: heartRateValue,
            measuredAt: measuredAt,
            tags: orderedSelectedTags,
            note: note.isEmpty ? nil : note
        )
        validationMessageKey = nil
        onSaved()
        dismiss()
    }

    private var previewStatus: BloodPressureStatus {
        guard
            let systolicValue = Int(systolic),
            let diastolicValue = Int(diastolic)
        else {
            return .normal
        }
        return evaluator.evaluate(systolic: systolicValue, diastolic: diastolicValue)
    }

    private var orderedSelectedTags: [String] {
        tagKeys.filter { selectedTags.contains($0) }
    }

    private var canSaveRecord: Bool {
        guard
            let systolicValue = Int(systolic),
            let diastolicValue = Int(diastolic),
            let heartRateValue = Int(heartRate)
        else {
            return false
        }
        return validator.isValid(systolic: systolicValue, diastolic: diastolicValue, heartRate: heartRateValue)
    }
}
