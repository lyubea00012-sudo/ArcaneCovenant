import CoreGraphics
import XCTest
@testable import ArcaneCovenant

@MainActor
final class GameSessionTests: XCTestCase {
    func testNewRunResetsCoreState() {
        let session = GameSession()
        session.startNewRun(viewport: CGSize(width: 300, height: 600))

        XCTAssertEqual(session.level, 1)
        XCTAssertEqual(session.health, 100)
        XCTAssertEqual(session.playerPosition, CGPoint(x: 150, y: 300))
        XCTAssertEqual(session.phase, .playing)
    }

    func testTickKeepsPlayerInsideArena() {
        let session = GameSession()
        session.startNewRun(viewport: CGSize(width: 300, height: 600))
        session.movement = CGVector(dx: -1_000, dy: -1_000)

        for _ in 0..<200 {
            session.tick(dt: 1.0 / 60.0, viewport: CGSize(width: 300, height: 600))
        }

        XCTAssertGreaterThanOrEqual(session.playerPosition.x, 24)
        XCTAssertGreaterThanOrEqual(session.playerPosition.y, 70)
    }
}
