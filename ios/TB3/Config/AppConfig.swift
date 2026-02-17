// TB3 iOS — App Configuration
// Values injected via .xcconfig or hardcoded for initial development.

import Foundation

enum AppConfig {
    // Cognito — populated from CloudFormation outputs
    static let cognitoRegion = "us-west-2"
    static let cognitoUserPoolId = "us-west-2_JwSNJXX9t"
    static let cognitoClientId = "7ebq8hk7m52uqp636n31s7ussb"
    static let cognitoDomain = "https://tb3-auth.auth.us-west-2.amazoncognito.com"

    // API Gateway
    static let apiURL = "https://rjqj1843lb.execute-api.us-west-2.amazonaws.com"

    // OAuth
    static let oauthCallbackScheme = "tb3"
    static let oauthCallbackURL = "tb3://callback"
    static let oauthScopes = ["email", "openid", "profile"]

    // Chromecast
    static let castAppID = "6BA96B8F"
    static let castNamespace = "urn:x-cast:com.tb3.workout"

    // Offline grace period
    static let offlineGraceDays = 7

    // Sync interval
    static let syncIntervalSeconds: TimeInterval = 300 // 5 minutes

    // App version
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
}
