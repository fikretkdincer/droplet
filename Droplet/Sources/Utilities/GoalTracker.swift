import Foundation

/// Tracks daily work goals and progress
class GoalTracker: ObservableObject {
    static let shared = GoalTracker()
    
    /// Daily goal in minutes (0 = not set)
    @Published var dailyGoalMinutes: Int = 0
    
    /// Work history: date string (yyyy-MM-dd) -> minutes worked
    @Published var workHistory: [String: Int] = [:]
    
    /// Milestones already notified for each day to avoid duplicates
    private var notifiedMilestones: [String: Set<Int>] = [:]
    
    /// Milestone thresholds (percentages)
    static let milestones = [25, 50, 75, 100, 125]
    
    /// Milestone messages
    static let milestoneMessages: [Int: (title: String, body: String)] = [
        25: ("Great Start!", "That's a great start! Keep going!"),
        50: ("Halfway There!", "Halfway there, keep pushing!"),
        75: ("Almost There!", "Almost complete, you can do this!"),
        100: ("Goal Complete!", "Amazing work! You've hit your daily goal! 🎉"),
        125: ("Overachiever!", "We're pushing even harder, huh?!")
    ]
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    var hasGoalSet: Bool {
        dailyGoalMinutes > 0
    }
    
    private init() {
        loadData()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        dailyGoalMinutes = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        
        if let data = UserDefaults.standard.data(forKey: "workHistory"),
           let history = try? JSONDecoder().decode([String: Int].self, from: data) {
            workHistory = history
        }
        
        if let data = UserDefaults.standard.data(forKey: "notifiedMilestones"),
           let milestones = try? JSONDecoder().decode([String: [Int]].self, from: data) {
            // Convert [Int] to Set<Int>
            notifiedMilestones = milestones.mapValues { Set($0) }
        }
    }
    
    private func saveData() {
        UserDefaults.standard.set(dailyGoalMinutes, forKey: "dailyGoalMinutes")
        
        if let data = try? JSONEncoder().encode(workHistory) {
            UserDefaults.standard.set(data, forKey: "workHistory")
        }
        
        // Convert Set<Int> to [Int] for encoding
        let milestonesArray = notifiedMilestones.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(milestonesArray) {
            UserDefaults.standard.set(data, forKey: "notifiedMilestones")
        }
    }
    
    // MARK: - Goal Management
    
    func setDailyGoal(hours: Double) {
        dailyGoalMinutes = Int(hours * 60)
        saveData()
    }
    
    // MARK: - Session Recording
    
    /// Record a completed work session and check for milestones
    /// Returns any new milestone reached (for notification)
    func recordWorkSession(minutes: Int) -> Int? {
        let today = dateFormatter.string(from: Date())
        let previousMinutes = workHistory[today] ?? 0
        let newMinutes = previousMinutes + minutes
        workHistory[today] = newMinutes
        
        // Check for milestone crossings
        let newMilestone = checkForNewMilestone(date: today, previousMinutes: previousMinutes, newMinutes: newMinutes)
        
        saveData()
        return newMilestone
    }
    
    private func checkForNewMilestone(date: String, previousMinutes: Int, newMinutes: Int) -> Int? {
        guard dailyGoalMinutes > 0 else { return nil }
        
        let previousPercent = (previousMinutes * 100) / dailyGoalMinutes
        let newPercent = (newMinutes * 100) / dailyGoalMinutes
        
        print("[GoalTracker] Previous: \(previousMinutes)m (\(previousPercent)%), New: \(newMinutes)m (\(newPercent)%), Goal: \(dailyGoalMinutes)m")
        
        var todayMilestones = notifiedMilestones[date] ?? []
        var highestNewMilestone: Int? = nil
        
        // Find the HIGHEST new milestone crossed (not first)
        for milestone in Self.milestones {
            if previousPercent < milestone && newPercent >= milestone && !todayMilestones.contains(milestone) {
                print("[GoalTracker] Milestone \(milestone)% crossed!")
                todayMilestones.insert(milestone)
                highestNewMilestone = milestone
            }
        }
        
        if highestNewMilestone != nil {
            notifiedMilestones[date] = todayMilestones
        }
        
        return highestNewMilestone
    }
    
    // MARK: - Week Data
    
    /// Get work data for a week (weekOffset: 0 = current, -1 = last week, etc.)
    func getWeekData(weekOffset: Int = 0) -> [(date: Date, minutes: Int, dayName: String)] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        guard var weekStart = calendar.date(from: components) else { return [] }
        
        // Apply week offset
        if weekOffset != 0 {
            weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: weekStart) ?? weekStart
        }
        
        var result: [(Date, Int, String)] = []
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE" // Mon, Tue, etc.
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let dateString = dateFormatter.string(from: date)
            let minutes = workHistory[dateString] ?? 0
            let dayName = dayFormatter.string(from: date)
            result.append((date, minutes, dayName))
        }
        
        return result
    }
    
    /// Get the date range string for a week
    func getWeekRangeString(weekOffset: Int = 0) -> String {
        let weekData = getWeekData(weekOffset: weekOffset)
        guard let first = weekData.first?.date, let last = weekData.last?.date else {
            return "This Week"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    /// Get today's progress percentage
    func getTodayProgress() -> Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        let today = dateFormatter.string(from: Date())
        let minutes = workHistory[today] ?? 0
        return Double(minutes) / Double(dailyGoalMinutes)
    }
    
    /// Get minutes worked today
    func getTodayMinutes() -> Int {
        let today = dateFormatter.string(from: Date())
        return workHistory[today] ?? 0
    }
    
    /// Format minutes as hours string (e.g., "2h 30m")
    static func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}
