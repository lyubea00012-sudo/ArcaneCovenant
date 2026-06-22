import AppIntents

struct StartArcaneRunIntent: AppIntent {
    static let title: LocalizedStringResource = "开始奥术远征"
    static let description = IntentDescription("打开奥术远征团并立即开始新一局")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppIntentRouter.shared.requestNewRun()
        return .result(dialog: "远征已经准备好了。")
    }
}

struct ArcaneCovenantShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartArcaneRunIntent(),
            phrases: [
                "用 \(.applicationName) 开始远征",
                "在 \(.applicationName) 开始新游戏"
            ],
            shortTitle: "开始远征",
            systemImageName: "wand.and.stars"
        )
    }
}
