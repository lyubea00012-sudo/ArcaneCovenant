import SwiftUI

struct GameView: View {
    let session: GameSession

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                arena(size: proxy.size)

                if session.phase == .title {
                    TitleOverlay {
                        session.startNewRun(viewport: proxy.size)
                    }
                } else {
                    HUD(session: session)
                    joystick
                    if session.phase == .choosingUpgrade {
                        UpgradeOverlay(session: session)
                    } else if session.phase == .gameOver {
                        GameOverOverlay(session: session) {
                            session.startNewRun(viewport: proxy.size)
                        }
                    }
                }
            }
            .background(Color(red: 0.035, green: 0.025, blue: 0.09))
            .ignoresSafeArea()
            .task {
                let clock = ContinuousClock()
                var previous = clock.now
                while !Task.isCancelled {
                    try? await clock.sleep(for: .milliseconds(16))
                    let now = clock.now
                    let dt = previous.duration(to: now)
                    previous = now
                    session.tick(dt: Double(dt.components.seconds) + Double(dt.components.attoseconds) / 1e18, viewport: proxy.size)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var joystick: some View {
        @Bindable var session = session
        return Joystick(movement: $session.movement)
    }

    private func arena(size: CGSize) -> some View {
        Canvas { context, _ in
            drawBackground(context: context, size: size)

            for orb in session.orbs {
                let rect = CGRect(x: orb.position.x - 4, y: orb.position.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(.mint))
            }

            for enemy in session.enemies {
                let rect = CGRect(
                    x: enemy.position.x - enemy.radius,
                    y: enemy.position.y - enemy.radius,
                    width: enemy.radius * 2,
                    height: enemy.radius * 2
                )
                context.fill(Path(roundedRect: rect, cornerRadius: enemy.radius * 0.35), with: .color(.pink.opacity(0.9)))
                context.stroke(Path(ellipseIn: rect.insetBy(dx: 3, dy: 3)), with: .color(.purple), lineWidth: 2)
            }

            for bolt in session.bolts {
                let glow = CGRect(x: bolt.position.x - 7, y: bolt.position.y - 7, width: 14, height: 14)
                context.fill(Path(ellipseIn: glow), with: .color(.cyan.opacity(0.25)))
                context.fill(Path(ellipseIn: glow.insetBy(dx: 4, dy: 4)), with: .color(.white))
            }

            let player = CGRect(x: session.playerPosition.x - 15, y: session.playerPosition.y - 15, width: 30, height: 30)
            context.fill(Path(ellipseIn: player), with: .color(.indigo))
            context.stroke(Path(ellipseIn: player.insetBy(dx: -4, dy: -4)), with: .color(.cyan.opacity(0.7)), lineWidth: 3)
            let hat = Path { path in
                path.move(to: CGPoint(x: session.playerPosition.x, y: session.playerPosition.y - 24))
                path.addLine(to: CGPoint(x: session.playerPosition.x - 13, y: session.playerPosition.y - 4))
                path.addLine(to: CGPoint(x: session.playerPosition.x + 13, y: session.playerPosition.y - 4))
                path.closeSubpath()
            }
            context.fill(hat, with: .color(.purple))
        }
        .accessibilityHidden(true)
    }

    private func drawBackground(context: GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.03, green: 0.02, blue: 0.09), Color(red: 0.08, green: 0.04, blue: 0.16)]),
            startPoint: .zero,
            endPoint: CGPoint(x: size.width, y: size.height)
        ))
        var grid = Path()
        stride(from: 0.0, through: size.width, by: 44).forEach {
            grid.move(to: CGPoint(x: $0, y: 0)); grid.addLine(to: CGPoint(x: $0, y: size.height))
        }
        stride(from: 0.0, through: size.height, by: 44).forEach {
            grid.move(to: CGPoint(x: 0, y: $0)); grid.addLine(to: CGPoint(x: size.width, y: $0))
        }
        context.stroke(grid, with: .color(.purple.opacity(0.12)), lineWidth: 1)
    }
}

private struct HUD: View {
    let session: GameSession

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Lv.\(session.level)", systemImage: "wand.and.stars")
                Spacer()
                Text(session.survivalText).monospacedDigit()
                Spacer()
                Label("\(session.defeated)", systemImage: "burst.fill")
            }
            .font(.headline)
            ProgressView(value: session.health, total: session.maxHealth).tint(.pink)
            ProgressView(value: Double(session.experience), total: Double(session.experienceNeeded)).tint(.cyan)
        }
        .padding(.horizontal, 20)
        .padding(.top, 52)
        .frame(maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("等级 \(session.level)，生命 \(Int(session.health))，击败 \(session.defeated)")
    }
}

private struct Joystick: View {
    @Binding var movement: CGVector
    @State private var knob = CGSize.zero

    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 2))
            .overlay {
                Circle().fill(.cyan.opacity(0.65)).frame(width: 44, height: 44).offset(knob)
            }
            .frame(width: 112, height: 112)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 26)
            .padding(.bottom, 28)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.translation.width, dy: value.translation.height)
                        let limited = vector.length > 38 ? vector.normalized * 38 : vector
                        knob = CGSize(width: limited.dx, height: limited.dy)
                        movement = limited
                    }
                    .onEnded { _ in
                        withAnimation(.snappy) { knob = .zero }
                        movement = .zero
                    }
            )
            .accessibilityLabel("移动摇杆")
    }
}

private struct TitleOverlay: View {
    let start: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "wand.and.stars.inverse").font(.system(size: 66)).foregroundStyle(.cyan)
            Text("奥术远征团").font(.system(size: 38, weight: .black, design: .rounded))
            Text("移动法师，咒术会自动寻找敌人。\n收集灵光，构筑属于你的法术组合。")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button(action: start) {
                Label("开始远征", systemImage: "play.fill")
                    .font(.title3.bold()).padding(.horizontal, 34).padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent).tint(.purple)
            .accessibilityIdentifier("start-run")
        }
        .padding(30)
    }
}

private struct UpgradeOverlay: View {
    let session: GameSession

    var body: some View {
        VStack(spacing: 16) {
            Text("咒术觉醒").font(.largeTitle.bold())
            Text("选择一项强化").foregroundStyle(.secondary)
            ForEach(session.offeredUpgrades) { upgrade in
                Button { session.choose(upgrade) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: upgrade.symbol).font(.title2).frame(width: 34)
                        VStack(alignment: .leading) {
                            Text(upgrade.title).font(.headline)
                            Text(upgrade.detail).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(14).frame(maxWidth: 330)
                }
                .buttonStyle(.bordered).tint(.cyan)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .padding()
    }
}

private struct GameOverOverlay: View {
    let session: GameSession
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("远征结束").font(.largeTitle.bold())
            Text("坚持 \(session.survivalText) · 击败 \(session.defeated)")
            Button("再次出发", action: retry).buttonStyle(.borderedProminent).tint(.purple)
        }
        .padding(30)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
    }
}

#Preview {
    GameView(session: GameSession())
}
