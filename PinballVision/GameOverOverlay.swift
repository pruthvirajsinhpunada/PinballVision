import SwiftUI

struct GameOverOverlay: View {

    @Environment(GameModel.self) private var gameModel

    @State private var scoreVisible   : Bool   = false
    @State private var recordVisible  : Bool   = false
    @State private var buttonsVisible : Bool   = false
    @State private var cardScale      : CGFloat = 0.85
    @State private var recordGlow     : CGFloat = 8

    var body: some View {
        ZStack {
            // Dark vignette
            Color.black.opacity(0.70).ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                gameOverTitle

                Divider().overlay(.white.opacity(0.12))
                    .padding(.vertical, 20)

                // Score reveal
                scorePanel

                // New record badge
                if gameModel.isNewRecord {
                    recordBadge
                        .opacity(recordVisible ? 1 : 0)
                        .scaleEffect(recordVisible ? 1 : 0.6)
                        .padding(.top, 12)
                }

                Spacer(minLength: 24)

                // Actions
                actionButtons
                    .opacity(buttonsVisible ? 1 : 0)
                    .offset(y: buttonsVisible ? 0 : 16)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .frame(maxWidth: 300)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.red.opacity(0.6), .purple.opacity(0.5), .pink.opacity(0.4)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ), lineWidth: 1.2
                    )
            )
            .shadow(color: .red.opacity(0.2), radius: 40)
            .scaleEffect(cardScale)
        }
        .onAppear { animateIn() }
    }

    // MARK: - Title

    private var gameOverTitle: some View {
        VStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .red.opacity(0.7), radius: 12)

            Text("GAME OVER")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange, .yellow],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .shadow(color: .red.opacity(0.4), radius: 10)
        }
    }

    // MARK: - Score panel

    private var scorePanel: some View {
        VStack(spacing: 16) {
            // Final score
            VStack(spacing: 3) {
                Text("FINAL SCORE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(3)

                Text(gameModel.score.formatted())
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 8)
                    .opacity(scoreVisible ? 1 : 0)
                    .scaleEffect(scoreVisible ? 1 : 0.7)
            }

            // Best score
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
                Text("BEST  \(gameModel.highScore.formatted())")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - New record badge

    private var recordBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 13))
            Text("NEW HIGH SCORE!")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .tracking(1)
            Image(systemName: "star.fill")
                .font(.system(size: 13))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing),
            in: Capsule()
        )
        .shadow(color: .yellow.opacity(0.7), radius: recordGlow)
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Play Again
            Button {
                withAnimation(.easeIn(duration: 0.2)) { cardScale = 0.85 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    gameModel.startGame()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text("PLAY AGAIN")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .tracking(1)
                }
                .foregroundStyle(.black)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [.cyan, Color(red: 0.3, green: 0.7, blue: 1)],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .shadow(color: .cyan.opacity(0.5), radius: 12)
            }
            .buttonStyle(.plain)

            // Back to menu
            Button {
                withAnimation(.easeInOut(duration: 0.35)) {
                    gameModel.state = .splash
                }
            } label: {
                Text("MAIN MENU")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Animation

    private func animateIn() {
        // Reset to initial values first so re-appearing (e.g. after Play Again) re-animates cleanly.
        cardScale      = 0.85
        scoreVisible   = false
        recordVisible  = false
        buttonsVisible = false
        recordGlow     = 8

        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            cardScale = 1.0
        }
        withAnimation(.spring(duration: 0.6).delay(0.3)) {
            scoreVisible = true
        }
        if gameModel.isNewRecord {
            withAnimation(.spring(duration: 0.5, bounce: 0.4).delay(0.7)) {
                recordVisible = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.7)) {
                recordGlow = 20
            }
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            buttonsVisible = true
        }
    }
}

// MARK: - Preview

#Preview("Game Over – Normal") {
    GameOverOverlay()
        .environment({ let m = GameModel(); m.score = 4_800; m.lives = 0; m.state = .gameOver; return m }())
        .frame(width: 400, height: 600).background(.black)
}

#Preview("Game Over – New Record") {
    GameOverOverlay()
        .environment({
            let m = GameModel(); m.score = 18_250; m.lives = 0
            m.isNewRecord = true; m.state = .gameOver; return m
        }())
        .frame(width: 400, height: 600).background(.black)
}
