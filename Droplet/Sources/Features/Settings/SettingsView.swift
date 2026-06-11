import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        VStack(spacing: 0) {
            MacNavigationHeader(
                title: "Settings",
                theme: settings.selectedTheme,
                backAction: { settings.navigateTo(.timer) }
            )

            ScrollView {
                VStack(spacing: 16) {
                    SettingsModeSection()
                    TimerSettingsSection()
                    CustomDurationsSettingsSection()
                    AppearanceSettingsSection()
                    MusicSettingsSection()
                    SoundSettingsSection()
                    BehaviorSettingsSection()
                }
                .padding(12)
            }
        }
    }
}
