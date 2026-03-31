import Foundation

struct ReminderItem: Identifiable, Equatable, Codable {
    let id: UUID
    var hour: Int
    var minute: Int
    var enabled: Bool

    init(id: UUID = UUID(), hour: Int, minute: Int, enabled: Bool = true) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.enabled = enabled
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let components = DateComponents(hour: hour, minute: minute)
        let date = Calendar.current.date(from: components) ?? .now
        return formatter.string(from: date)
    }
}
