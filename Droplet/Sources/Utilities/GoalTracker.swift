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
    static let milestones = GoalProgress.defaultMilestones
    
    /// Milestone messages
    static let milestoneMessages: [Int: (title: String, body: String)] = [
        25: ("Great Start!", "That's a great start! Keep going!"),
        50: ("Halfway There!", "Halfway there, keep pushing!"),
        75: ("Almost There!", "Almost complete, you can do this!"),
        100: ("Goal Complete!", "Amazing work! You've hit your daily goal! 🎉"),
        125: ("Overachiever!", "We're pushing even harder, huh?!")
    ]
    
    var hasGoalSet: Bool {
        dailyGoalMinutes > 0
    }
    
    private init() {
        loadData()
        syncWidgetStore()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        let registry = DropletWidgetStore.shared
        dailyGoalMinutes = registry.dailyGoalMinutes
        workHistory = registry.workHistory

        // Preserve existing installs that saved goal data before widgets used the shared app-group registry.
        if dailyGoalMinutes == 0 {
            dailyGoalMinutes = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        }

        if workHistory.isEmpty,
           let data = UserDefaults.standard.data(forKey: "workHistory"),
           let legacyHistory = try? JSONDecoder().decode([String: Int].self, from: data) {
            workHistory = legacyHistory
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

        syncGoalProgressRegistry()
    }

    private func syncWidgetStore() {
        DropletWidgetStore.shared.sync(
            dailyGoalMinutes: dailyGoalMinutes,
            workHistory: workHistory,
            selectedThemeRaw: SettingsManager.shared.selectedThemeRaw
        )
    }

    private func syncGoalProgressRegistry() {
        DropletWidgetStore.shared.syncGoalProgress(
            dailyGoalMinutes: dailyGoalMinutes,
            workHistory: workHistory
        )
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
        let today = FocusHistory.dayKey()
        let previousMinutes = workHistory[today] ?? 0
        var history = FocusHistory(minutesByDay: workHistory)
        let newMinutes = history.record(minutes: minutes)
        workHistory = history.minutesByDay
        
        // Check for milestone crossings
        let newMilestone = checkForNewMilestone(date: today, previousMinutes: previousMinutes, newMinutes: newMinutes)
        
        saveData()
        return newMilestone
    }
    
    private func checkForNewMilestone(date: String, previousMinutes: Int, newMinutes: Int) -> Int? {
        guard dailyGoalMinutes > 0 else { return nil }
        
        let progress = GoalProgress(dailyGoalMinutes: dailyGoalMinutes, minutesWorked: newMinutes)
        let previousPercent = GoalProgress(dailyGoalMinutes: dailyGoalMinutes, minutesWorked: previousMinutes).percent
        let newPercent = progress.percent

        print("[GoalTracker] Previous: \(previousMinutes)m (\(previousPercent)%), New: \(newMinutes)m (\(newPercent)%), Goal: \(dailyGoalMinutes)m")

        var todayMilestones = notifiedMilestones[date] ?? []
        let highestNewMilestone = progress.highestCrossedMilestone(
            previousMinutes: previousMinutes,
            milestones: Self.milestones,
            alreadyNotified: todayMilestones
        )

        if let highestNewMilestone {
            for milestone in Self.milestones where previousPercent < milestone && newPercent >= milestone {
                todayMilestones.insert(milestone)
            }
            print("[GoalTracker] Milestone \(highestNewMilestone)% crossed!")
            notifiedMilestones[date] = todayMilestones
        }
        
        return highestNewMilestone
    }
    
    // MARK: - Week Data
    
    /// Get work data for a week (weekOffset: 0 = current, -1 = last week, etc.)
    func getWeekData(weekOffset: Int = 0) -> [(date: Date, minutes: Int, dayName: String)] {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        let records = FocusHistory(minutesByDay: workHistory)
            .weekRecords(containing: targetDate, weekStartWeekday: 2, calendar: calendar)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE" // Mon, Tue, etc.
        
        return records.map { record in
            (record.date, record.minutes, dayFormatter.string(from: record.date))
        }
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
        GoalProgress(dailyGoalMinutes: dailyGoalMinutes, minutesWorked: getTodayMinutes()).ratio
    }
    
    /// Get minutes worked today
    func getTodayMinutes() -> Int {
        FocusHistory(minutesByDay: workHistory).minutes()
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
