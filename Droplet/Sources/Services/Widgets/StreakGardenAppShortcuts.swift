import AppIntents

struct StreakGardenAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextStreakGardenMonthIntent(),
            phrases: [
                "Show next Streak Garden month in \(.applicationName)"
            ],
            shortTitle: "Next Garden Month",
            systemImageName: "chevron.right"
        )

        AppShortcut(
            intent: PreviousStreakGardenMonthIntent(),
            phrases: [
                "Show previous Streak Garden month in \(.applicationName)"
            ],
            shortTitle: "Previous Garden Month",
            systemImageName: "chevron.left"
        )

        AppShortcut(
            intent: ResetStreakGardenMonthIntent(),
            phrases: [
                "Show current Streak Garden month in \(.applicationName)"
            ],
            shortTitle: "Current Garden Month",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: StartTimerBucketIntent(),
            phrases: [
                "Start \(.applicationName)",
                "Pause \(.applicationName)",
                "Toggle Droplet Timer in \(.applicationName)"
            ],
            shortTitle: "Toggle Timer",
            systemImageName: "drop.fill"
        )
    }
}
