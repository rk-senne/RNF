import Foundation
import UserNotifications

final class NotificationScheduler {

    enum NotificationType: String {
        case morning
        case evening
    }

    private enum Identifier {
        static let morning = "rnf.notification.morning"
        static let evening = "rnf.notification.evening"
    }

    private let center: UNUserNotificationCenter
    private let analyticsService: AnalyticsService

    init(
        center: UNUserNotificationCenter = .current(),
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.center = center
        self.analyticsService = analyticsService
    }

    func requestPermission() async throws -> Bool {

        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleMorningNotification(at time: DateComponents) async throws {

        let content = UNMutableNotificationContent()
        content.title = "RNF"
        content.body = "Begin the day with discipline."
        content.sound = .default
        content.userInfo = ["notification_type": NotificationType.morning.rawValue]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Identifier.morning,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.morning])
        try await center.add(request)
    }

    func scheduleEveningNotification(at time: DateComponents) async throws {

        let content = UNMutableNotificationContent()
        content.title = "RNF"
        content.body = "Finish strong. Complete today's habits."
        content.sound = .default
        content.userInfo = ["notification_type": NotificationType.evening.rawValue]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Identifier.evening,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.evening])
        try await center.add(request)
    }

    func trackNotificationOpened(
        userId: UUID,
        notificationType: NotificationType,
        date: Date = Date()
    ) async {
        await analyticsService.trackEvent(
            .notificationOpened,
            properties: [
                "user_id": userId.uuidString,
                "notification_type": notificationType.rawValue,
                "timestamp": Self.analyticsTimestamp(for: date)
            ]
        )
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        AnalyticsTimestamp.string(for: date)
    }

}
