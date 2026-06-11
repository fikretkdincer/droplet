import SwiftUI

enum MacTimerFontWeight {
    static func weight(for rawValue: String) -> Font.Weight {
        switch rawValue {
        case "Thin": return .thin
        case "Light": return .light
        case "Regular": return .regular
        case "Medium": return .medium
        case "DemiBold": return .semibold
        case "Bold": return .bold
        default: return .medium
        }
    }
}

struct TimerProgressBar: View {
    let totalSeconds: Int
    let remainingSeconds: Int
    let color: Color
    let backgroundColor: Color

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .frame(height: 4)

            GeometryReader { proxy in
                let ratio = progressRatio
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: proxy.size.width * ratio, height: 4)
                    .animation(.linear(duration: 1), value: ratio)
            }
        }
        .frame(height: 4)
    }

    private var progressRatio: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = Double(totalSeconds - remainingSeconds)
        return min(max(elapsed / Double(totalSeconds), 0), 1)
    }
}

struct TimerWorkflowDots: View {
    let count: Int
    let mode: TimerMode
    let completedWorkflows: Int
    let color: Color
    let inactiveColor: Color
    var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: 4 * scale) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(isHighlighted(index) ? color : inactiveColor)
                    .frame(width: 6 * scale, height: 6 * scale)
            }
        }
    }

    private func isHighlighted(_ index: Int) -> Bool {
        mode == .longBreak ||
            (mode == .work && index <= completedWorkflows) ||
            (mode != .work && index < completedWorkflows)
    }
}

struct TimerPillButton: View {
    let title: String
    let color: Color
    var scale: CGFloat = 1
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10 * scale, weight: .medium))
                .foregroundColor(color)
                .padding(.horizontal, 10 * scale)
                .padding(.vertical, 4 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 6 * scale)
                        .fill(color.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}
