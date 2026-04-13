import SwiftUI
#if !targetEnvironment(simulator)
import GameKit
#endif

@main
struct PinballVisionApp: App {

    @State private var gameModel    = GameModel()
    @State private var handTracking = HandTrackingManager()
    @State private var sound        = SoundManager()

    var body: some Scene {
        // visionOS always creates a UIWindowSceneSessionRoleApplication scene first.
        // This plain WindowGroup satisfies that role, then immediately opens the
        // volumetric game window and dismisses itself.
        WindowGroup {
            LauncherView()
                .environment(gameModel)
                .environment(handTracking)
                .environment(sound)
        }
        .defaultSize(width: 1, height: 1)

        // The 3-D volumetric pinball game
        WindowGroup(id: "pinball") {
            PinballVolumeView()
                .environment(gameModel)
                .environment(handTracking)
                .environment(sound)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 1.05, depth: 0.18, in: .meters)
    }
}

// MARK: - LauncherView

private struct LauncherView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss)    private var dismiss

    var body: some View {
        Color.clear
            .task {
                authenticateGameCenter()
                openWindow(id: "pinball")
                try? await Task.sleep(for: .milliseconds(400))
                dismiss()
            }
    }

    private func authenticateGameCenter() {
#if !targetEnvironment(simulator)
        GKLocalPlayer.local.authenticateHandler = { _, error in
            if let error { print("[GameCenter] Auth error: \(error)") }
        }
#endif
    }
}
