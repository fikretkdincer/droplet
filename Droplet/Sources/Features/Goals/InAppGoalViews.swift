import SwiftUI

struct InAppWeeklyProgressView: View {
    @ObservedObject var goalTracker = GoalTracker.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var weekOffset = 0
    @State private var hoveredDay: Date?

    var body: some View {
        VStack(spacing: 12) {
            header
            weekNavigation
            weekChart
            progressSummary
        }
        .padding(12)
    }

    private var header: some View {
        HStack {
            Button(action: { settings.navigateTo(.timer) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Goal Tracker")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(settings.selectedTheme.textColor)

            Spacer()

            Button(action: { settings.navigateTo(.goalSetup) }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
    }

    private var weekNavigation: some View {
        HStack {
            Button(action: { weekOffset -= 1 }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))

            Spacer()

            Text(goalTracker.getWeekRangeString(weekOffset: weekOffset))
                .font(.system(size: 11))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.8))

            Spacer()

            Button(action: { weekOffset += 1 }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundColor(settings.selectedTheme.textColor.opacity(weekOffset >= 0 ? 0.2 : 0.6))
            .disabled(weekOffset >= 0)
        }
        .padding(.horizontal, 16)
    }

    private var weekChart: some View {
        let weekData = goalTracker.getWeekData(weekOffset: weekOffset)

        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(weekData.enumerated()), id: \.offset) { _, day in
                let progress = goalTracker.dailyGoalMinutes > 0
                    ? Double(day.minutes) / Double(goalTracker.dailyGoalMinutes)
                    : 0
                let barColor: Color = progress >= 1.25 ? Color(hex: "FFD700") :
                    progress >= 1.0 ? Color(hex: "4CAF50") :
                    settings.selectedTheme.workAccent
                let isHovered = hoveredDay == day.date
                let barHeight = max(4, min(CGFloat(progress) * 60, 80))

                VStack(spacing: 2) {
                    Spacer(minLength: 0)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: 24, height: barHeight)
                        .shadow(color: progress >= 1.25 ? barColor.opacity(0.6) : .clear, radius: progress >= 1.25 ? 4 : 0)
                        .opacity(isHovered ? 0.7 : 1)

                    Text(day.dayName.prefix(1))
                        .font(.system(size: 8))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                        .frame(height: 10)
                }
                .frame(width: 24, height: 90, alignment: .bottom)
                .onHover { hovering in
                    hoveredDay = hovering ? day.date : nil
                }
            }
        }
        .frame(height: 90, alignment: .bottom)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var progressSummary: some View {
        let weekData = goalTracker.getWeekData(weekOffset: weekOffset)

        if let hoveredDay,
           let day = weekData.first(where: { $0.date == hoveredDay }) {
            Text(dayTooltip(date: day.date, minutes: day.minutes))
                .font(.system(size: 10))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.8))
                .transition(.opacity)
        } else if goalTracker.hasGoalSet {
            let progress = goalTracker.getTodayProgress()
            Text("Today: \(GoalTracker.formatMinutes(goalTracker.getTodayMinutes())) / \(GoalTracker.formatMinutes(goalTracker.dailyGoalMinutes)) (\(Int(progress * 100))%)")
                .font(.system(size: 10))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
        }
    }

    private func dayTooltip(date: Date, minutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        let dateString = formatter.string(from: date)
        let hours = minutes / 60
        let mins = minutes % 60

        if minutes == 0 {
            return "\(dateString) — No work"
        } else if hours > 0 && mins > 0 {
            return "\(dateString) — \(hours) hour\(hours == 1 ? "" : "s") \(mins) min"
        } else if hours > 0 {
            return "\(dateString) — \(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(dateString) — \(mins) min"
    }
}

struct InAppGoalSetupView: View {
    @ObservedObject var goalTracker = GoalTracker.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var selectedIndex = 5

    private let hourLabels = ["30m", "1h", "1.5h", "2h", "3h", "4h", "5h", "6h", "8h"]
    private let hourValues: [Double] = [0.5, 1, 1.5, 2, 3, 4, 5, 6, 8]

    var body: some View {
        VStack(spacing: 16) {
            header

            Text("How many hours per day?")
                .font(.system(size: 11))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(0..<hourLabels.count, id: \.self) { index in
                    Button(action: { selectedIndex = index }) {
                        Text(hourLabels[index])
                            .font(.system(size: 12, weight: selectedIndex == index ? .bold : .regular))
                            .foregroundColor(selectedIndex == index ? settings.selectedTheme.backgroundColor : settings.selectedTheme.textColor)
                            .frame(width: 40, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedIndex == index ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)

            Button(action: saveGoal) {
                Text("Save")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.backgroundColor)
                    .frame(width: 80, height: 28)
                    .background(settings.selectedTheme.workAccent)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .onAppear(perform: syncSelectionFromExistingGoal)
    }

    private var header: some View {
        HStack {
            Button(action: navigateBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Set Daily Goal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(settings.selectedTheme.textColor)

            Spacer()

            Image(systemName: "chevron.left")
                .font(.system(size: 14))
                .opacity(0)
        }
        .padding(.horizontal, 8)
    }

    private func navigateBack() {
        if goalTracker.hasGoalSet {
            settings.navigateTo(.weeklyProgress)
        } else {
            settings.navigateTo(.timer)
        }
    }

    private func saveGoal() {
        goalTracker.setDailyGoal(hours: hourValues[selectedIndex])
        settings.navigateTo(.weeklyProgress)
    }

    private func syncSelectionFromExistingGoal() {
        guard goalTracker.hasGoalSet else { return }
        let currentHours = Double(goalTracker.dailyGoalMinutes) / 60.0
        if let index = hourValues.firstIndex(where: { abs($0 - currentHours) < 0.1 }) {
            selectedIndex = index
        }
    }
}
