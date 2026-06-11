import SwiftUI

struct MiniTimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        Text(viewModel.formattedTime)
            .font(.custom("Avenir Next", size: 18))
            .fontWeight(.bold)
            .foregroundColor(settings.selectedTheme.textColor)
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minWidth: 90, minHeight: 32)
            .background(settings.selectedTheme.backgroundColor)
            .onTapGesture {
                viewModel.toggleStartPause()
            }
    }
}
