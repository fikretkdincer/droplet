import Foundation
import ServiceManagement

/// Manages launch at login functionality using SMAppService (macOS 13+)
class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool = false
    
    private init() {
        // Check initial status
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
    
    /// Toggle launch at login
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ Registered as login item")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("✅ Unregistered from login items")
                }
                isEnabled = SMAppService.mainApp.status == .enabled
            } catch {
                print("❌ Failed to update login item status: \(error)")
            }
        }
    }
}
