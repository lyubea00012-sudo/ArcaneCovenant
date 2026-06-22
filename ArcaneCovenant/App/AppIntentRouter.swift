import Foundation
import Observation

@MainActor
@Observable
final class AppIntentRouter {
    static let shared = AppIntentRouter()

    private(set) var startRequestID = UUID()

    private init() {}

    func requestNewRun() {
        startRequestID = UUID()
    }
}
