import Foundation
import Combine
import UserNotifications

// MARK: - Notification Manager

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {
        Task { await checkAuthorization() }
    }

    // MARK: - Authorization

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Local Notifications

    /// Утренний брифинг — ежедневно в заданное время
    func scheduleMorningBriefing(hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Доброе утро"
        content.body = "Ваш ежедневный брифинг готов. Посмотрите план на день."
        content.sound = .default
        content.categoryIdentifier = "morning_briefing"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_briefing", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Напоминание о транзакции — ежедневно вечером
    func scheduleFinanceReminder(hour: Int = 20, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Финансы"
        content.body = "Не забудьте записать расходы за сегодня."
        content.sound = .default
        content.categoryIdentifier = "finance_reminder"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "finance_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Напоминание о здоровье — еженедельно
    func scheduleHealthCheckReminder(weekday: Int = 1, hour: Int = 10) {
        let content = UNMutableNotificationContent()
        content.title = "Здоровье"
        content.body = "Проверьте свои показатели здоровья на этой неделе."
        content.sound = .default
        content.categoryIdentifier = "health_reminder"

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "health_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// AI-инсайт — кастомное уведомление
    func scheduleAIInsight(title: String, body: String, after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ai_insight"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "ai_insight_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Manage

    /// Активировать все уведомления (вызывается при включении тоггла)
    func enableAllScheduled() {
        scheduleMorningBriefing()
        scheduleFinanceReminder()
        scheduleHealthCheckReminder()
    }

    /// Удалить все запланированные уведомления
    func disableAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Удалить конкретное уведомление
    func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
