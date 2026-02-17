// TB3 iOS — Cast State (mirrors services/cast.ts castState signal)

import Foundation

@Observable
final class CastState {
    var available = false
    var connected = false
    var isLoading = false
    var deviceName: String?
}
