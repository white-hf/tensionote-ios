import Foundation
import UserNotifications

final class ReminderNotificationScheduler {
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            completion?(granted)
        }
    }

    func fetchAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }

    func sync(reminders: [ReminderItem]) {
        let center = UNUserNotificationCenter.current()
        let enabledReminderIDs = Set(reminders.filter(\.enabled).map(\.id.uuidString))

        center.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .map(\.identifier)
                .filter { !enabledReminderIDs.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }

        reminders.filter(\.enabled).forEach { reminder in
            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute

            let content = UNMutableNotificationContent()
            content.title = L10n.tr("reminder_notification_title")
            content.body = L10n.tr("reminder_notification_body")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
