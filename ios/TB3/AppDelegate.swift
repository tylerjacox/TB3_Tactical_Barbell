// TB3 iOS — AppDelegate (GoogleCast SDK initialization + notification delegate)

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let criteria = GCKDiscoveryCriteria(applicationID: AppConfig.castAppID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.stopReceiverApplicationWhenEndingSession = true
        options.startDiscoveryAfterFirstTapOnCastButton = true
        GCKCastContext.setSharedInstanceWith(options)

        // Disable default Cast notification/mini controller (we handle UI ourselves)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = false

        // Set notification delegate for foreground presentation + tap handling
        UNUserNotificationCenter.current().delegate = self

        return true
    }
}

// MARK: - Notification Handling

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    /// Present milestone notifications as banners even when app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        if id.hasPrefix("tb3_milestone") {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([])
        }
    }

    /// Handle notification tap — set flag and post notification for RootView.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        if id == "tb3_rest_timer_complete" {
            UserDefaults.standard.set(true, forKey: "tb3_notification_open_session")
            NotificationCenter.default.post(name: .tb3NotificationTapped, object: nil)
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let tb3NotificationTapped = Notification.Name("tb3NotificationTapped")
}
