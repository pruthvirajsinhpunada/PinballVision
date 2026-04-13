import SwiftUI
import RealityKit
#if !targetEnvironment(simulator)
import GameKit
#endif

struct PinballVolumeView: View {

    @Environment(GameModel.self)           private var gameModel
    @Environment(HandTrackingManager.self) private var handTracking
    @Environment(SoundManager.self)        private var sound

    @State private var leftFlipper      : Entity?
    @State private var rightFlipper     : Entity?
    @State private var ball             : Entity?
    @State private var collisionSub     : EventSubscription?
    @State private var bumperEntities   : [String: Entity] = [:]
    @State private var slingshotEntities: [String: Entity] = [:]
    @State private var laneEntities     : [String: Entity] = [:]

    // Onboarding — show once per install
    @State private var showOnboarding =
        !UserDefaults.standard.bool(forKey: "PinballOnboardingSeen")

    private let leftRest   : Float = -.pi / 7.2
    private let leftActive : Float =  .pi / 4.5
    private let rightRest  : Float =  .pi / 7.2
    private let rightActive: Float = -.pi / 4.5

    var body: some View {
        RealityView { content, attachments in
            // Build on a background thread — USDZ loads don't block the render thread.
            let ents = await Task.detached(priority: .userInitiated) {
                PinballTableBuilder.build()
            }.value

            leftFlipper  = ents.leftFlipper
            rightFlipper = ents.rightFlipper
            ball         = ents.ball
            content.add(ents.root)

            // Cache named entities for flash effects
            for i in 0..<5 {
                if let e = ents.root.findEntity(named: "bumper_\(i)") {
                    bumperEntities["bumper_\(i)"] = e
                }
            }
            for i in 0..<2 {
                if let e = ents.root.findEntity(named: "slingshot_\(i)") {
                    slingshotEntities["slingshot_\(i)"] = e
                }
            }
            for i in 0..<3 {
                if let e = ents.root.findEntity(named: "lane_\(i)") {
                    laneEntities["lane_\(i)"] = e
                }
            }

            // Guard prevents duplicate subscriptions
            if collisionSub == nil {
                collisionSub = content.subscribe(to: CollisionEvents.Began.self) { event in
                    handleCollision(event)
                }
            }

            handTracking.start()

            place(attachments, id: "hud",        at: SIMD3( 0.00,  0.57,  0.08), in: &content)
            place(attachments, id: "leftBtn",    at: SIMD3(-0.23, -0.50,  0.08), in: &content)
            place(attachments, id: "rightBtn",   at: SIMD3( 0.23, -0.50,  0.08), in: &content)
            place(attachments, id: "launch",     at: SIMD3( 0.00, -0.51,  0.08), in: &content)
            place(attachments, id: "splash",     at: SIMD3( 0.00,  0.08,  0.12), in: &content)
            place(attachments, id: "gameover",   at: SIMD3( 0.00,  0.08,  0.12), in: &content)
            place(attachments, id: "onboarding", at: SIMD3( 0.00,  0.08,  0.16), in: &content)

        } attachments: {
            Attachment(id: "hud")      { HUDView().environment(gameModel) }
            Attachment(id: "leftBtn")  { FlipperButton(label: "L", color: .cyan) { activateFlipper(.left)  } }
            Attachment(id: "rightBtn") { FlipperButton(label: "R", color: .cyan) { activateFlipper(.right) } }
            Attachment(id: "launch")   { launchButton }

            Attachment(id: "splash") {
                Group {
                    if gameModel.state == .splash { SplashOverlay().environment(gameModel) }
                }
                .animation(.easeInOut(duration: 0.35), value: gameModel.state)
            }

            Attachment(id: "gameover") {
                Group {
                    if gameModel.state == .gameOver { GameOverOverlay().environment(gameModel) }
                }
                .animation(.easeInOut(duration: 0.35), value: gameModel.state)
            }

            // Onboarding floats slightly in front of splash, shown once per install
            Attachment(id: "onboarding") {
                Group {
                    if showOnboarding && gameModel.state == .splash {
                        OnboardingOverlay { showOnboarding = false }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showOnboarding)
            }
        }
        .onChange(of: gameModel.leftFlipperActive)  { _, on in rotateFlipper(leftFlipper,  angle: on ? leftActive  : leftRest)  }
        .onChange(of: gameModel.rightFlipperActive) { _, on in rotateFlipper(rightFlipper, angle: on ? rightActive : rightRest) }
        .onChange(of: gameModel.launchCommand)    { _, on in guard on else { return }; launchBall();     gameModel.launchCommand    = false }
        .onChange(of: gameModel.resetBallCommand) { _, on in guard on else { return }; repositionBall(); gameModel.resetBallCommand = false }
        .onChange(of: handTracking.leftPinching) { _, pinch in
            guard gameModel.state == .playing else { return }
            gameModel.leftFlipperActive = pinch
            if pinch { sound.playFlipper() }
        }
        .onChange(of: handTracking.rightPinching) { _, pinch in
            guard gameModel.state == .playing else { return }
            gameModel.rightFlipperActive = pinch
            if pinch { sound.playFlipper() }
        }
        .onChange(of: gameModel.state) { _, state in
            if state == .gameOver {
                submitScore(gameModel.score)
                sound.playGameOver()
            }
        }
    }

    // MARK: - Launch button

    private var launchButton: some View {
        Group {
            if gameModel.state == .playing {
                Button {
                    gameModel.launchCommand = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 13))
                        Text("LAUNCH")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(2)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(colors: [.cyan, .teal],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .shadow(color: .cyan.opacity(0.6), radius: 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Launch Ball")
                .accessibilityHint("Fires the ball onto the playfield")
            }
        }
    }

    // MARK: - Helpers

    private func place(_ attachments: RealityViewAttachments,
                       id: String,
                       at position: SIMD3<Float>,
                       in content: inout RealityViewContent) {
        if let e = attachments.entity(for: id) {
            e.position = position
            content.add(e)
        }
    }

    private func rotateFlipper(_ entity: Entity?, angle: Float) {
        entity?.transform.rotation = simd_quatf(angle: angle, axis: [0, 0, 1])
    }

    private func activateFlipper(_ side: FlipperSide) {
        guard gameModel.state == .playing else { return }
        sound.playFlipper()
        switch side {
        case .left:
            gameModel.leftFlipperActive = true
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                await MainActor.run { gameModel.leftFlipperActive = false }
            }
        case .right:
            gameModel.rightFlipperActive = true
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                await MainActor.run { gameModel.rightFlipperActive = false }
            }
        }
    }

    private func launchBall() {
        repositionBall()
        guard let ball else { return }
        var motion = PhysicsMotionComponent()
        motion.linearVelocity = SIMD3(Float.random(in: -0.35...0.35), 6.5, 0)
        ball.components.set(motion)
        sound.playLaunch()
        gameModel.activateBallSave()
    }

    private func repositionBall() {
        guard let ball else { return }
        ball.components.set(PhysicsMotionComponent())
        ball.position = SIMD3(0, -0.15, 0)
    }

    // MARK: - Collision handling

    private func handleCollision(_ event: CollisionEvents.Began) {
        let a = event.entityA.name
        let b = event.entityB.name

        // Bumpers — advance combo, bright flash
        if let name = [a, b].first(where: { $0.hasPrefix("bumper") }) {
            Task { @MainActor in
                gameModel.hitBumper()
                sound.playBumperHit(multiplier: gameModel.multiplier)
                flashEntity(named: name, in: bumperEntities, peak: 18_000, rest: 4_500)
            }
            return
        }

        // Slingshots — flat score, magenta flash
        if let name = [a, b].first(where: { $0.hasPrefix("slingshot") }) {
            Task { @MainActor in
                gameModel.hitSlingshot()
                sound.playSlingshotHit()
                flashEntity(named: name, in: slingshotEntities, peak: 12_000, rest: 2_800)
            }
            return
        }

        // Rollover lanes — flat score, lane glow spike
        if let name = [a, b].first(where: { $0.hasPrefix("lane") }) {
            Task { @MainActor in
                gameModel.hitLane()
                sound.playLaneScore()
                flashEntity(named: name, in: laneEntities, peak: 3_000, rest: 500)
            }
            return
        }

        // Gutter — ball drain
        if a == "gutter" || b == "gutter" {
            Task { @MainActor in
                gameModel.ballLost()
                // game over sound fires via onChange(of: gameModel.state)
                if gameModel.state == .playing {
                    sound.playBallLost()
                }
            }
        }
    }

    /// Generic light-intensity flash for bumpers, slingshots, and lanes.
    private func flashEntity(named name: String,
                             in cache: [String: Entity],
                             peak: Float, rest: Float) {
        guard let entity = cache[name] else { return }
        if var light = entity.components[PointLightComponent.self] {
            light.intensity = peak
            entity.components.set(light)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            if var light = entity.components[PointLightComponent.self] {
                light.intensity = rest
                entity.components.set(light)
            }
        }
    }

    private func submitScore(_ score: Int) {
#if !targetEnvironment(simulator)
        guard GKLocalPlayer.local.isAuthenticated else { return }
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score, context: 0, player: GKLocalPlayer.local,
                    leaderboardIDs: [GameConfig.leaderboardID]
                )
            } catch {
                print("[GameCenter] Submit error: \(error)")
            }
        }
#endif
    }
}

// MARK: - FlipperSide

enum FlipperSide { case left, right }

// MARK: - Constants

private enum GameConfig {
    static let leaderboardID = "com.pruthvirajsinh.PinballVision.highscore"
}

// MARK: - Preview

#Preview("HUD + Buttons") {
    let m: GameModel = {
        let m = GameModel(); m.score = 5_200; m.lives = 2; m.combo = 4
        m.state = .playing; return m
    }()
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            HUDView().environment(m).padding(.top, 30)
            Spacer()
            HStack {
                FlipperButton(label: "L", color: .cyan) { }
                Spacer()
                FlipperButton(label: "R", color: .cyan) { }
            }
            .padding(.horizontal, 28).padding(.bottom, 30)
        }
    }
    .frame(width: 360, height: 600)
}
