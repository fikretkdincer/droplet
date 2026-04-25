import Foundation
import AppKit

class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()

    private let releasesURL = "https://github.com/fikretkdincer/droplet/releases/latest"

    private override init() { super.init() }

    func checkForUpdates() {
        if let url = URL(string: releasesURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
