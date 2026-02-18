// TB3 iOS — Strava Integration State

import Foundation

@Observable
final class StravaState {
    var isConnected = false
    var isLoading = false
    var athleteName: String?
    var autoShare: Bool = UserDefaults.standard.bool(forKey: "tb3_strava_auto_share")
    var lastShareError: String?
    var lastShareSuccess: Bool?
}
