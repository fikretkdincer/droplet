import Foundation

enum DropletWidgetDeepLink {
    static let scheme = "droplet"
    static let timerToggleHost = "timer"
    static let timerTogglePath = "/toggle"

    static var timerToggleURL: URL {
        URL(string: "\(scheme)://\(timerToggleHost)\(timerTogglePath)")!
    }

    static func isTimerToggle(_ url: URL) -> Bool {
        url.scheme == scheme &&
            url.host == timerToggleHost &&
            url.path == timerTogglePath
    }
}
