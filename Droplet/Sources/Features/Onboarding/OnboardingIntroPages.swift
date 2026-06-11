import SwiftUI

// MARK: - Page 1 - Welcome

extension OnboardingView {
    var page1View: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(previewTheme.workAccent.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(previewTheme.workAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Up Droplet")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(previewTheme.textColor)
                    Text("Build a focus rhythm before the timer starts.")
                        .font(.system(size: 12))
                        .foregroundColor(previewTheme.textColor.opacity(0.58))
                        .lineSpacing(3)
                }

                HStack(spacing: 5) {
                    cyclePill("Focus", color: previewTheme.workAccent)
                    tinyArrow
                    cyclePill("Break", color: previewTheme.breakAccent)
                    tinyArrow
                    cyclePill("Repeat", color: previewTheme.workAccent.opacity(0.8))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            timerMockup
                .frame(width: 178)
        }
        .padding(.horizontal, 34)
    }

    private var timerMockup: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9))
                    .foregroundColor(previewTheme.textColor.opacity(0.35))
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 10))
                    .foregroundColor(previewTheme.textColor.opacity(0.35))
            }

            Text("\(workDuration):00")
                .font(.custom("Avenir Next", size: 38))
                .fontWeight(.medium)
                .foregroundColor(previewTheme.textColor)
                .monospacedDigit()

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(previewTheme.textColor.opacity(0.15))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(previewTheme.workAccent)
                    .frame(width: 48, height: 4)
            }

            HStack(spacing: 6) {
                ForEach(0..<workflowCount, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? previewTheme.workAccent : previewTheme.textColor.opacity(0.22))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(previewTheme.textColor.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(previewTheme.textColor.opacity(0.08), lineWidth: 1)
        )
    }

    private func cyclePill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(5)
    }

    private var tinyArrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 7))
            .foregroundColor(previewTheme.textColor.opacity(0.3))
    }
}

// MARK: - Page 2 - Session Rhythm

extension OnboardingView {
    private var workDurationOptions: [Int] {
        [10, 15, 20, 25, 30, 45, 50, 60]
    }

    private var breakDurationOptions: [Int] {
        [3, 5, 10, 15]
    }

    private var longBreakDurationOptions: [Int] {
        [10, 15, 20, 30]
    }

    private var workflowOptions: [Int] {
        [2, 3, 4, 5]
    }

    var page2View: some View {
        VStack(spacing: 12) {
            onboardingTitle(
                "Session Rhythm",
                subtitle: "Pick the default focus, break, and long-break cadence."
            )

            HStack(alignment: .top, spacing: 12) {
                OnboardingPanel(theme: previewTheme) {
                    durationGrid(title: "Focus", options: workDurationOptions, selection: $workDuration)
                    durationGrid(title: "Short Break", options: breakDurationOptions, selection: $shortBreakDuration)
                }

                OnboardingPanel(theme: previewTheme) {
                    durationGrid(title: "Long Break", options: longBreakDurationOptions, selection: $longBreakDuration)
                    workflowGrid
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func durationGrid(title: String, options: [Int], selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(previewTheme.textColor.opacity(0.58))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(options, id: \.self) { minutes in
                    OnboardingChoiceButton(
                        title: "\(minutes)m",
                        theme: previewTheme,
                        isSelected: selection.wrappedValue == minutes
                    ) {
                        selection.wrappedValue = minutes
                    }
                }
            }
        }
    }

    private var workflowGrid: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Long Break After")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(previewTheme.textColor.opacity(0.58))

            HStack(spacing: 6) {
                ForEach(workflowOptions, id: \.self) { count in
                    OnboardingChoiceButton(
                        title: "\(count)",
                        subtitle: "flows",
                        theme: previewTheme,
                        isSelected: workflowCount == count
                    ) {
                        workflowCount = count
                    }
                }
            }
        }
    }
}

// MARK: - Page 3 - Daily Goal

extension OnboardingView {
    private var goalOptions: [(label: String, hours: Double)] {
        [
            ("30m", 0.5),
            ("1h", 1),
            ("1.5h", 1.5),
            ("2h", 2),
            ("3h", 3),
            ("4h", 4),
            ("5h", 5),
            ("6h", 6)
        ]
    }

    var page3View: some View {
        VStack(spacing: 13) {
            onboardingTitle(
                "Daily Goal",
                subtitle: "Choose the amount of focused work that fills today's droplet."
            )

            HStack(spacing: 16) {
                goalPreview

                OnboardingPanel(theme: previewTheme) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 2), spacing: 7) {
                        ForEach(goalOptions, id: \.label) { option in
                            OnboardingChoiceButton(
                                title: option.label,
                                subtitle: "per day",
                                theme: previewTheme,
                                isSelected: abs(dailyGoalHours - option.hours) < 0.1
                            ) {
                                dailyGoalHours = option.hours
                            }
                        }
                    }
                }
                .frame(width: 190)
            }
            .padding(.horizontal, 36)
        }
    }

    private var goalPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundColor(previewTheme.workAccent)
                Text("Goal Tracker")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
            }

            HStack(alignment: .bottom, spacing: 7) {
                let heights: [CGFloat] = [28, 48, 18, 64, 52, 10, 34]
                ForEach(0..<heights.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index == 3 ? previewTheme.workAccent : previewTheme.workAccent.opacity(0.38))
                        .frame(width: 17, height: heights[index])
                }
            }
            .frame(height: 74, alignment: .bottom)

            Text("\(formatGoal(dailyGoalHours)) per day")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(previewTheme.workAccent)

            Text("Widgets and weekly progress use the same goal.")
                .font(.system(size: 9))
                .foregroundColor(previewTheme.textColor.opacity(0.54))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(previewTheme.textColor.opacity(0.06)))
    }

    func formatGoal(_ hours: Double) -> String {
        let minutes = Int(hours * 60)
        let hourPart = minutes / 60
        let minutePart = minutes % 60

        if hourPart > 0 && minutePart > 0 {
            return "\(hourPart)h \(minutePart)m"
        } else if hourPart > 0 {
            return "\(hourPart)h"
        }
        return "\(minutePart)m"
    }
}

// MARK: - Shared title

extension OnboardingView {
    func onboardingTitle(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 21, weight: .bold))
                .foregroundColor(previewTheme.textColor)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(previewTheme.textColor.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }
}
