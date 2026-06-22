import SwiftUI

@main
struct ArcaneCovenantApp: App {
    @State private var session = GameSession()
    @State private var intentRouter = AppIntentRouter.shared

    var body: some Scene {
        WindowGroup {
            GameView(session: session)
                .onChange(of: intentRouter.startRequestID) {
                    session.startNewRun()
                }
        }
    }
}
