import Foundation

@MainActor
final class ReminderViewModel: ObservableObject {
    @Published private(set) var reminders: [ReminderItem] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let scheduler = ReminderNotificationScheduler()

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = documentsDirectory.appendingPathComponent("tensionote_reminders.json")
        scheduler.requestAuthorization()
        load()
        scheduler.sync(reminders: reminders)
    }

    func addReminder() {
        reminders.append(ReminderItem(hour: 9, minute: 0))
        sortReminders()
        persist()
        scheduler.sync(reminders: reminders)
    }

    func toggleReminder(_ id: UUID) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].enabled.toggle()
        persist()
        scheduler.sync(reminders: reminders)
    }

    func updateReminder(_ id: UUID, hour: Int, minute: Int) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].hour = hour
        reminders[index].minute = minute
        sortReminders()
        persist()
        scheduler.sync(reminders: reminders)
    }

    func deleteReminder(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
        persist()
        scheduler.sync(reminders: reminders)
    }

    func deleteReminder(_ id: UUID) {
        reminders.removeAll { $0.id == id }
        persist()
        scheduler.sync(reminders: reminders)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([ReminderItem].self, from: data),
              !decoded.isEmpty
        else {
            reminders = []
            return
        }
        reminders = decoded
        sortReminders()
    }

    private func persist() {
        guard let data = try? encoder.encode(reminders) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    private func sortReminders() {
        reminders.sort {
            if $0.hour == $1.hour {
                return $0.minute < $1.minute
            }
            return $0.hour < $1.hour
        }
    }
}
