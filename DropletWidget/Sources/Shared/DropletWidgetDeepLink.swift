import Foundation

enum DropletWidgetDeepLink {
    static let scheme = "droplet"
    static let openHost = "app"
    static let openPath = "/open"
    static let timerToggleHost = "timer"
    static let timerTogglePath = "/toggle"

    static var openURL: URL {
        URL(string: "\(scheme)://\(openHost)\(openPath)")!
    }

    static var timerToggleURL: URL {
        URL(string: "\(scheme)://\(timerToggleHost)\(timerTogglePath)")!
    }

    static func isOpen(_ url: URL) -> Bool {
        url.scheme == scheme &&
            url.host == openHost &&
            url.path == openPath
    }

    static func isTimerToggle(_ url: URL) -> Bool {
        url.scheme == scheme &&
            url.host == timerToggleHost &&
            url.path == timerTogglePath
    }
}
