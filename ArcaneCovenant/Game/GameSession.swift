import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class GameSession {
    enum Phase: Equatable {
        case title
        case playing
        case choosingUpgrade
        case gameOver
    }

    private(set) var phase: Phase = .title
    private(set) var enemies: [Enemy] = []
    private(set) var bolts: [MagicBolt] = []
    private(set) var orbs: [ExperienceOrb] = []
    private(set) var playerPosition: CGPoint = CGPoint(x: 200, y: 400)
    private(set) var health = 100.0
    private(set) var maxHealth = 100.0
    private(set) var level = 1
    private(set) var experience = 0
    private(set) var defeated = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var offeredUpgrades: [UpgradeKind] = []

    var movement = CGVector.zero

    private var movementSpeed: CGFloat = 155
    private var boltDamage = 26.0
    private var castInterval: TimeInterval = 0.72
    private var castCooldown: TimeInterval = 0
    private var spawnCooldown: TimeInterval = 0
    private var projectileCount = 1

    var experienceNeeded: Int { 5 + (level - 1) * 4 }
    var survivalText: String {
        let total = Int(elapsed)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    func startNewRun(viewport: CGSize = CGSize(width: 390, height: 844)) {
        phase = .playing
        enemies.removeAll()
        bolts.removeAll()
        orbs.removeAll()
        playerPosition = CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        health = 100
        maxHealth = 100
        level = 1
        experience = 0
        defeated = 0
        elapsed = 0
        movementSpeed = 155
        boltDamage = 26
        castInterval = 0.72
        castCooldown = 0
        spawnCooldown = 0
        projectileCount = 1
        movement = .zero
    }

    func tick(dt: TimeInterval, viewport: CGSize) {
        guard phase == .playing, viewport.width > 0, viewport.height > 0 else { return }
        let step = min(dt, 1.0 / 20.0)
        elapsed += step

        movePlayer(dt: step, viewport: viewport)
        spawnCooldown -= step
        castCooldown -= step

        if spawnCooldown <= 0 {
            spawnEnemy(in: viewport)
            spawnCooldown = max(0.22, 0.85 - elapsed * 0.004)
        }
        if castCooldown <= 0, !enemies.isEmpty {
            castBolt()
            castCooldown = castInterval
        }

        updateEnemies(dt: step)
        updateBolts(dt: step, viewport: viewport)
        collectOrbs()
        resolveHits()

        if health <= 0 {
            health = 0
            phase = .gameOver
        }
    }

    func choose(_ upgrade: UpgradeKind) {
        guard phase == .choosingUpgrade else { return }
        switch upgrade {
        case .rapidCasting:
            castInterval = max(0.2, castInterval * 0.85)
        case .arcanePower:
            boltDamage *= 1.25
        case .fleetFooted:
            movementSpeed *= 1.12
        case .vitality:
            maxHealth += 20
            health = min(maxHealth, health + 35)
        case .multishot:
            projectileCount = min(5, projectileCount + 1)
        }
        offeredUpgrades.removeAll()
        phase = .playing
    }

    private func movePlayer(dt: TimeInterval, viewport: CGSize) {
        let velocity = movement.normalized * movementSpeed * CGFloat(dt)
        let next = playerPosition + velocity
        playerPosition = CGPoint(
            x: min(max(next.x, 24), viewport.width - 24),
            y: min(max(next.y, 70), viewport.height - 32)
        )
    }

    private func spawnEnemy(in viewport: CGSize) {
        let side = Int.random(in: 0..<4)
        let point: CGPoint
        switch side {
        case 0: point = CGPoint(x: .random(in: 0...viewport.width), y: -24)
        case 1: point = CGPoint(x: viewport.width + 24, y: .random(in: 0...viewport.height))
        case 2: point = CGPoint(x: .random(in: 0...viewport.width), y: viewport.height + 24)
        default: point = CGPoint(x: -24, y: .random(in: 0...viewport.height))
        }
        let toughness = 1 + elapsed / 90
        enemies.append(Enemy(
            position: point,
            health: 38 * toughness,
            speed: .random(in: 34...58) + CGFloat(elapsed / 15),
            radius: .random(in: 12...18)
        ))
    }

    private func castBolt() {
        guard let target = enemies.min(by: {
            $0.position.distance(to: playerPosition) < $1.position.distance(to: playerPosition)
        }) else { return }
        let base = CGVector(
            dx: target.position.x - playerPosition.x,
            dy: target.position.y - playerPosition.y
        ).normalized
        let baseAngle = atan2(base.dy, base.dx)
        for index in 0..<projectileCount {
            let offset = CGFloat(index) - CGFloat(projectileCount - 1) / 2
            let angle = baseAngle + offset * 0.16
            let direction = CGVector(dx: cos(angle), dy: sin(angle))
            bolts.append(MagicBolt(
                position: playerPosition,
                velocity: direction * 360,
                damage: boltDamage
            ))
        }
    }

    private func updateEnemies(dt: TimeInterval) {
        for index in enemies.indices {
            let direction = CGVector(
                dx: playerPosition.x - enemies[index].position.x,
                dy: playerPosition.y - enemies[index].position.y
            ).normalized
            enemies[index].position = enemies[index].position + direction * enemies[index].speed * CGFloat(dt)
        }

        var touching = 0
        enemies.removeAll { enemy in
            if enemy.position.distance(to: playerPosition) < enemy.radius + 14 {
                touching += 1
                return true
            }
            return false
        }
        health -= Double(touching) * 12
    }

    private func updateBolts(dt: TimeInterval, viewport: CGSize) {
        for index in bolts.indices {
            bolts[index].position = bolts[index].position + bolts[index].velocity * CGFloat(dt)
            bolts[index].age += dt
        }
        bolts.removeAll { bolt in
            bolt.age > 2 || bolt.position.x < -40 || bolt.position.x > viewport.width + 40 ||
                bolt.position.y < -40 || bolt.position.y > viewport.height + 40
        }
    }

    private func resolveHits() {
        var spentBolts = Set<UUID>()
        var defeatedEnemies = Set<UUID>()

        for bolt in bolts {
            guard let index = enemies.firstIndex(where: {
                !defeatedEnemies.contains($0.id) && $0.position.distance(to: bolt.position) < $0.radius + 6
            }) else { continue }
            enemies[index].health -= bolt.damage
            spentBolts.insert(bolt.id)
            if enemies[index].health <= 0 {
                defeatedEnemies.insert(enemies[index].id)
                orbs.append(ExperienceOrb(position: enemies[index].position, value: 1))
                defeated += 1
            }
        }

        bolts.removeAll { spentBolts.contains($0.id) }
        enemies.removeAll { defeatedEnemies.contains($0.id) }
    }

    private func collectOrbs() {
        var gained = 0
        orbs.removeAll { orb in
            if orb.position.distance(to: playerPosition) < 42 {
                gained += orb.value
                return true
            }
            return false
        }
        guard gained > 0 else { return }
        experience += gained
        if experience >= experienceNeeded {
            experience -= experienceNeeded
            level += 1
            offeredUpgrades = Array(UpgradeKind.allCases.shuffled().prefix(3))
            phase = .choosingUpgrade
        }
    }
}
