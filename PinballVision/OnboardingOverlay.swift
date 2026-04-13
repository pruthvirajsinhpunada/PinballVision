import SwiftUI

private let kOnboardingSeenKey = "PinballOnboardingSeen"

struct OnboardingOverlay: View {

    let onDismiss: () -> Void

    @State private var visible = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ───────────────────────────────────────────────────
            VStack(spacing: 6) {
                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple],
                                       startPoint: .top, endPoint: .bottom))
                    .shadow(color: .cyan.opacity(0.6), radius: 10)

                Text("HOW TO PLAY")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .white],
                                       startPoint: .leading, endPoint: .trailing))
            }
            .padding(.bottom, 20)

            Divider().overlay(.white.opacity(0.15))
                .padding(.bottom, 18)

            // ── Instructions ─────────────────────────────────────────────
            VStack(spacing: 14) {
                row(icon: "hand.pinch.fill",
                    color: .cyan,
                    title: "PINCH TO FLIP",
                    body: "Pinch your left or right hand to activate the matching flipper.")

                row(icon: "circle.grid.2x1.fill",
                    color: .purple,
                    title: "TAP L / R BUTTONS",
                    body: "Tap the on-screen L and R buttons as an alternative to hand gestures.")

                row(icon: "arrow.up.circle.fill",
                    color: .teal,
                    title: "LAUNCH THE BALL",
                    body: "Hit LAUNCH to fire the ball. You get a 2.5 s ball-save on every launch.")

                row(icon: "bolt.fill",
                    color: .yellow,
                    title: "BUILD COMBOS",
                    body: "Hit bumpers in quick succession to multiply your score — up to ×5!")

                row(icon: "line.3.horizontal",
                    color: .green,
                    title: "CROSS ROLLOVER LANES",
                    body: "The three glowing lines award bonus points every time the ball passes through.")
            }

            Spacer(minLength: 20)

            // ── Dismiss ───────────────────────────────────────────────────
            Button {
                UserDefaults.standard.set(true, forKey: kOnboardingSeenKey)
                withAnimation(.easeIn(duration: 0.2)) { visible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
            } label: {
                Text("GOT IT — LET'S PLAY")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(.black)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.cyan, Color(red: 0.3, green: 0.8, blue: 1)],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .cyan.opacity(0.5), radius: 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(width: 320)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.04, green: 0.04, blue: 0.14))
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(colors: [.cyan.opacity(0.8), .purple.opacity(0.5)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5)
            }
        )
        .shadow(color: .cyan.opacity(0.25), radius: 30)
        .scaleEffect(visible ? 1 : 0.88)
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.3)) { visible = true }
        }
    }

    // MARK: - Row helper

    private func row(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28)
                .shadow(color: color.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                Text(body)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    OnboardingOverlay { }
        .frame(width: 400, height: 700)
        .background(.black)
}
