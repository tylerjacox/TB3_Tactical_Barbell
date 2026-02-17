// TB3 iOS — AppDelegate (GoogleCast SDK initialization)

import UIKit

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

        return true
    }
}
