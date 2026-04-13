import SwiftUI

struct FlipperButton: View {

    let label : String       // "L" or "R"
    let color : Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            guard !isPressed else { return }
            isPressed = true
            action()
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                await MainActor.run {
                    withAnimation(.spring(duration: 0.25, bounce: 0.4)) { isPressed = false }
                }
            }
        } label: {
            ZStack {
                // Outer glow halo
                Circle()
                    .fill(color.opacity(isPressed ? 0.35 : 0.12))
                    .frame(width: 72, height: 72)
                    .blur(radius: isPressed ? 10 : 5)

                // Neon ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [color, color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isPressed ? 2.5 : 1.8
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: color.opacity(isPressed ? 0.9 : 0.5),
                            radius: isPressed ? 14 : 6)

                // Inner fill
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(isPressed ? 0.5 : 0.2), .clear],
                            center: .center, startRadius: 0, endRadius: 28
                        )
                    )
                    .frame(width: 58, height: 58)

                // Label + arrow
                VStack(spacing: 2) {
                    Image(systemName: label == "L" ? "arrowtriangle.left.fill" : "arrowtriangle.right.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(color.opacity(0.7))
                    Text(label)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(isPressed ? .white : color)
                }
            }
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .animation(.spring(duration: 0.14, bounce: 0.5), value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label == "L" ? "Left Flipper" : "Right Flipper")
        .accessibilityHint("Activates the \(label == "L" ? "left" : "right") flipper to hit the ball")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Flipper Buttons") {
    HStack(spacing: 48) {
        FlipperButton(label: "L", color: .cyan)   { }
        FlipperButton(label: "R", color: .cyan)   { }
    }
    .padding(40)
    .background(.black)
}

#Preview("Flipper – Accent Colors") {
    HStack(spacing: 32) {
        FlipperButton(label: "L", color: .purple) { }
        FlipperButton(label: "R", color: .pink)   { }
    }
    .padding(40)
    .background(.black)
}
