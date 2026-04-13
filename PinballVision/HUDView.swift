import SwiftUI

struct HUDView: View {

    @Environment(GameModel.self) private var gameModel

    @State private var scoreFlash  : Bool    = false
    @State private var eventOpacity: Double  = 0
    @State private var eventOffset : CGFloat = 0
    @State private var lastEventID : UUID?

    var body: some View {
        VStack(spacing: 10) {

            // Score block
            scoreBlock

            // Combo badge
            if gameModel.combo >= 3 {
                comboBadge
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal:   .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }

            // Ball save indicator
            if gameModel.ballSaveActive {
                ballSaveIndicator
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal:   .opacity
                    ))
            }

            // Lives
            livesRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            if let event = gameModel.lastEvent {
                VStack(spacing: 1) {
                    if event.multiplier > 1 {
                        Text("×\(event.multiplier)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                    }
                    Text("+\(event.points)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(
                            event.multiplier >= 5 ? Color.yellow :
                            event.multiplier >= 3 ? Color.orange : Color.cyan
                        )
                }
                .shadow(color: event.multiplier > 1 ? .orange.opacity(0.9) : .cyan.opacity(0.7), radius: 8)
                .opacity(eventOpacity)
                .offset(y: eventOffset - 28)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.cyan.opacity(0.5), .purple.opacity(0.3)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
        )
        .shadow(color: .cyan.opacity(0.15), radius: 20)
        .animation(.spring(duration: 0.3), value: gameModel.combo)
        // Score flash on change
        .onChange(of: gameModel.score) { _, _ in
            withAnimation(.spring(duration: 0.12)) { scoreFlash = true }
            Task {
                try? await Task.sleep(for: .milliseconds(280))
                await MainActor.run {
                    withAnimation(.spring(duration: 0.2)) { scoreFlash = false }
                }
            }
        }
        // Score event popup
        .onChange(of: gameModel.lastEvent) { _, event in
            guard let event, event.id != lastEventID else { return }
            lastEventID = event.id
            showScorePopup(event)
        }
    }

    // MARK: - Score block

    private var scoreBlock: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(3)

                Text(gameModel.score.formatted())
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .cyan.opacity(0.9)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .cyan.opacity(scoreFlash ? 1.0 : 0.4),
                            radius: scoreFlash ? 18 : 6)
                    .scaleEffect(scoreFlash ? 1.08 : 1.0)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.spring(duration: 0.25), value: gameModel.score)
                    .accessibilityLabel("Score: \(gameModel.score)")
            }
            .frame(maxWidth: .infinity)

            // Best
            VStack(alignment: .trailing, spacing: 1) {
                Text("BEST")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(2)
                Text(gameModel.highScore.formatted())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange.opacity(0.85))
            }
        }
    }

    // MARK: - Combo badge

    private var comboBadge: some View {
        let nextThreshold = gameModel.combo < 6 ? 6 : gameModel.combo < 10 ? 10 : 20
        let prevThreshold = gameModel.combo < 6 ? 3 : gameModel.combo < 10 ? 6  : 10
        let progress      = Double(gameModel.combo - prevThreshold) / Double(nextThreshold - prevThreshold)

        return VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("\(gameModel.combo)× HIT  \(gameModel.multiplierLabel ?? "")")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1)
            }
            .foregroundStyle(.black)

            // Progress bar toward next multiplier tier
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.25))
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: geo.size.width * min(progress, 1.0))
                        .animation(.spring(duration: 0.3), value: gameModel.combo)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing),
            in: Capsule()
        )
        .shadow(color: .yellow.opacity(0.6), radius: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(gameModel.combo) hit combo, \(gameModel.multiplierLabel ?? "") multiplier active")
    }

    // MARK: - Ball save indicator

    private var ballSaveIndicator: some View {
        HStack(spacing: 5) {
            Image(systemName: "shield.fill")
                .font(.system(size: 10, weight: .bold))
            Text("BALL SAVE")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(1)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(
            LinearGradient(colors: [.green, .mint],
                           startPoint: .leading, endPoint: .trailing),
            in: Capsule()
        )
        .shadow(color: .green.opacity(0.7), radius: 7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ball save active")
        .accessibilityHint("Your next drain will be saved automatically")
    }

    // MARK: - Lives row

    private var livesRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<3) { i in
                Image(systemName: i < gameModel.lives ? "heart.fill" : "heart")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(
                        i < gameModel.lives
                            ? AnyShapeStyle(LinearGradient(colors: [.red, .pink],
                                                           startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Color.white.opacity(0.2))
                    )
                    .shadow(color: i < gameModel.lives ? .red.opacity(0.8) : .clear, radius: 6)
                    .animation(.spring(duration: 0.3).delay(Double(i) * 0.06), value: gameModel.lives)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lives: \(gameModel.lives) of 3")
    }

    // MARK: - Score popup helper

    private func showScorePopup(_ event: ScoreEvent) {
        eventOffset  = 0
        eventOpacity = 1
        withAnimation(.easeOut(duration: 0.8)) {
            eventOffset  = -28
            eventOpacity = 0
        }
    }
}

// MARK: - Preview

#Preview("HUD – Active Combo") {
    HUDView()
        .environment({
            let m = GameModel(); m.score = 12_400; m.highScore = 25_000
            m.lives = 2; m.combo = 5; return m
        }())
        .padding(20).background(.black)
}

#Preview("HUD – Single Life") {
    HUDView()
        .environment({ let m = GameModel(); m.score = 3_100; m.lives = 1; return m }())
        .padding(20).background(.black)
}

#Preview("HUD – Fresh") {
    HUDView()
        .environment(GameModel())
        .padding(20)
        .background(.black)
}
