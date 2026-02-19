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

    // Spotify
    static let spotifyClientId = "afae49575c4f4c23a604d8eed2d9b4c4"
    static let spotifyCallbackScheme = "tb3"
    static let spotifyCallbackURL = "tb3://spotify"
    static let spotifyAuthURL = "https://accounts.spotify.com/authorize"
    static let spotifyTokenProxyURL = "\(apiURL)/spotify/token"
    static let spotifyAPIBaseURL = "https://api.spotify.com/v1"

    // Strava
    static let stravaClientId = "203521"
    static let stravaCallbackScheme = "tb3"
    static let stravaCallbackURL = "tb3://tb3"
    static let stravaAuthURL = "https://www.strava.com/oauth/authorize"
    static let stravaTokenProxyURL = "\(apiURL)/strava/token"
    static let stravaAPIBaseURL = "https://www.strava.com/api/v3"
    static let stravaDeauthorizeURL = "https://www.strava.com/oauth/deauthorize"

    // App version
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
}
