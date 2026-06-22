import CoreGraphics
import Foundation
import SwiftUI

struct Enemy: Identifiable {
    let id = UUID()
    var position: CGPoint
    var health: Double
    var speed: CGFloat
    var radius: CGFloat
}

struct MagicBolt: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var damage: Double
    var age: TimeInterval = 0
}

struct ExperienceOrb: Identifiable {
    let id = UUID()
    var position: CGPoint
    var value: Int
}

enum UpgradeKind: String, CaseIterable, Identifiable {
    case rapidCasting
    case arcanePower
    case fleetFooted
    case vitality
    case multishot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rapidCasting: "迅捷咏唱"
        case .arcanePower: "奥术增幅"
        case .fleetFooted: "风行步"
        case .vitality: "生命涌泉"
        case .multishot: "分裂咒弹"
        }
    }

    var detail: String {
        switch self {
        case .rapidCasting: "施法间隔缩短 15%"
        case .arcanePower: "咒弹伤害提高 25%"
        case .fleetFooted: "移动速度提高 12%"
        case .vitality: "回复并增加 20 点生命"
        case .multishot: "每次施法额外发射一枚咒弹"
        }
    }

    var symbol: String {
        switch self {
        case .rapidCasting: "bolt.fill"
        case .arcanePower: "sparkles"
        case .fleetFooted: "wind"
        case .vitality: "heart.fill"
        case .multishot: "circle.hexagongrid.fill"
        }
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

extension CGVector {
    var length: CGFloat { hypot(dx, dy) }

    var normalized: CGVector {
        guard length > 0 else { return .zero }
        return CGVector(dx: dx / length, dy: dy / length)
    }

    static func *(lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
}
