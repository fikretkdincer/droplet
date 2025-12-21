import Foundation
import UserNotifications
import AppKit

/// Handles macOS system notifications and sounds for timer events
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        // Set delegate to allow notifications when app is in foreground
        UNUserNotificationCenter.current().delegate = self
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("⚠️ Notification permission denied")
                }
                if let error = error {
                    print("❌ Notification permission error: \(error)")
                }
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // This is called when a notification is about to be presented while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner, play sound, and update badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // This is called when user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    /// Play system alert sound for session end
    func playAlertSound() {
        // Play the system "Glass" sound (a pleasant beep)
        NSSound.beep()
        
        // Alternative: play a specific system sound
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
    }
    
    /// Play distinct sound for milestone notifications
    func playMilestoneSound() {
        // Use "Hero" or "Purr" for a different, uplifting sound
        if let sound = NSSound(named: "Hero") {
            sound.play()
        } else if let sound = NSSound(named: "Purr") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    func sendNotification(title: String, body: String) {
        // Play sound immediately
        playAlertSound()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to send notification: \(error)")
                    // Fallback: show alert dialog
                    self?.showAlertFallback(title: title, body: body)
                } else {
                    print("✅ Notification sent: \(title)")
                }
            }
        }
    }
    
    /// Fallback alert dialog when notifications fail
    private func showAlertFallback(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func sendWorkEndNotification() {
        sendNotification(
            title: "Work Session Complete!",
            body: "Time for a break. You've earned it!"
        )
    }
    
    func sendBreakEndNotification() {
        sendNotification(
            title: "Break Over!",
            body: "Ready to focus again?"
        )
    }
    
    func sendLongBreakEndNotification() {
        sendNotification(
            title: "Long Break Over!",
            body: "Great job! Ready for another workflow?"
        )
    }
    
    /// Send a custom notification (for milestones, etc.)
    func sendCustomNotification(title: String, body: String) {
        // Use distinct milestone sound
        playMilestoneSound()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send milestone notification: \(error)")
            }
        }
    }
}

