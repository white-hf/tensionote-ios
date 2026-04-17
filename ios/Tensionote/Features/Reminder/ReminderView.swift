import UIKit
import SwiftUI

struct ReminderView: View {
    @StateObject private var viewModel = ReminderViewModel()
    @State private var reminderPendingDeletion: ReminderItem?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tr("reminder_notification_status_title"))
                        .font(.headline)
                    Text(L10n.tr(viewModel.notificationStatusKey))
                        .foregroundStyle(.secondary)
                    if viewModel.notificationStatusKey == "reminder_notification_status_denied" {
                        Button(L10n.tr("reminder_notification_open_settings")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else if viewModel.notificationStatusKey == "reminder_notification_status_not_determined"
                                || viewModel.notificationStatusKey == "reminder_notification_status_unknown" {
                        Button(L10n.tr("reminder_notification_request")) {
                            viewModel.requestNotificationAuthorization()
                        }
                    }
                    Text(L10n.tr(viewModel.notificationStatusHelpKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if viewModel.reminders.isEmpty {
                ContentUnavailableView(
                    L10n.tr("reminder_empty_title"),
                    systemImage: "bell.slash",
                    description: Text(L10n.tr("reminder_empty_body"))
                )
            } else {
                ForEach(viewModel.reminders) { reminder in
                    reminderRow(reminder)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .onDelete(perform: viewModel.deleteReminder)
            }
        }
        .listStyle(.plain)
        .alert(
            L10n.tr("reminder_delete_confirm_title"),
            isPresented: Binding(
                get: { reminderPendingDeletion != nil },
                set: { if !$0 { reminderPendingDeletion = nil } }
            ),
            presenting: reminderPendingDeletion
        ) { reminder in
            Button(L10n.tr("common_cancel"), role: .cancel) {
                reminderPendingDeletion = nil
            }
            Button(L10n.tr("common_delete"), role: .destructive) {
                viewModel.deleteReminder(reminder.id)
                reminderPendingDeletion = nil
            }
        } message: { _ in
            Text(L10n.tr("reminder_delete_confirm_body"))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.tr("reminder_add")) {
                    viewModel.addReminder()
                }
            }
        }
        .navigationTitle(L10n.tr("reminder_title"))
    }

    @ViewBuilder
    private func reminderRow(_ reminder: ReminderItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.timeLabel)
                        .font(.title3.weight(.semibold))
                    Text(L10n.tr("reminder_every_day"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { reminder.enabled },
                    set: { _ in viewModel.toggleReminder(reminder.id) }
                ))
                .labelsHidden()
            }

            DatePicker(
                "",
                selection: reminderDateBinding(for: reminder),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                reminderPendingDeletion = reminder
            } label: {
                Text(L10n.tr("common_delete"))
            }
            .buttonStyle(.borderless)
            .tint(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func reminderDateBinding(for reminder: ReminderItem) -> Binding<Date> {
        Binding(
            get: {
                let components = DateComponents(hour: reminder.hour, minute: reminder.minute)
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                viewModel.updateReminder(
                    reminder.id,
                    hour: components.hour ?? reminder.hour,
                    minute: components.minute ?? reminder.minute
                )
            }
        )
    }
}
