import SwiftUI

struct SplashOverlay: View {

    @Environment(GameModel.self) private var gameModel

    @State private var ringRotation : Double  = 0
    @State private var pulseScale   : CGFloat = 1.0
    @State private var glowRadius   : CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.2))
                .padding(.vertical, 16)
            scoreSection
            Spacer(minLength: 16)
            playButton
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 28)
        .frame(width: 300)
        .background(
            ZStack {
                // Solid dark base — visible in visionOS passthrough
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.04, green: 0.04, blue: 0.12))
                // Neon rings behind content
                backgroundRings
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    LinearGradient(
                        colors: [.cyan.opacity(0.9), .purple.opacity(0.6), .pink.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 1.5
                )
        )
        .shadow(color: .cyan.opacity(0.35), radius: 40)
        .onAppear { animateIn() }
    }

    // MARK: - Background rings

    private var backgroundRings: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let size = 140.0 + Double(i) * 60
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [.cyan, .purple, .pink, .cyan],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(ringRotation + Double(i) * 90))
                    .opacity(0.22)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [.cyan.opacity(0.4), .clear],
                        center: .center, startRadius: 0, endRadius: 40))
                    .frame(width: 72, height: 72)
                    .blur(radius: 6)

                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .white],
                                       startPoint: .top, endPoint: .bottom))
                    .shadow(color: .cyan, radius: glowRadius)
            }
            .padding(.bottom, 2)

            Text("PINBALL")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, Color(red: 0.7, green: 0.3, blue: 1.0), .pink],
                        startPoint: .leading, endPoint: .trailing))
                .shadow(color: .cyan.opacity(0.8), radius: glowRadius)

            Text("VISION PRO EDITION")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(4)
        }
    }

    // MARK: - Score section

    private var scoreSection: some View {
        VStack(spacing: 4) {
            Text("BEST SCORE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(3)

            Text(gameModel.highScore == 0 ? "---" : gameModel.highScore.formatted())
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange],
                                   startPoint: .top, endPoint: .bottom))
                .shadow(color: .orange.opacity(0.6), radius: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Play button

    private var playButton: some View {
        Button {
            gameModel.startGame()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("TAP TO PLAY")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .tracking(2)
            }
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.cyan, Color(red: 0.3, green: 0.8, blue: 1.0)],
                    startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .cyan.opacity(0.7), radius: pulseScale * 16)
            .scaleEffect(pulseScale)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start Game")
        .accessibilityHint("Begins a new pinball game")
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            glowRadius = 24
        }
    }
}

#Preview {
    SplashOverlay()
        .environment(GameModel())
        .frame(width: 400, height: 600)
        .background(.black)
}
