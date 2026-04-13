# PinballVision

A fully playable pinball game for **Apple Vision Pro**, built with SwiftUI, RealityKit, and ARKit hand tracking. Play in a volumetric window floating in your space — no controllers needed.

---

## Features

- **Hand tracking** — pinch your left/right fingers to flip; no physical controllers required
- **Procedural physics table** — bumpers, slingshots, rollover lanes, and a gutter built entirely with RealityKit physics bodies
- **Synthesized audio** — every sound (bumper hit, flipper snap, ball drain, game over) is generated in real-time with AVAudioEngine; no audio asset files
- **Scoring system** — combo multiplier (up to ×10), per-target scoring, animated score popups
- **Ball save** — automatic one-time save on the first drain per ball
- **Game Center** — leaderboard integration with your high score submitted on game over
- **Onboarding** — shown once per install, explains controls with animated overlay
- **Accessibility** — VoiceOver labels on all interactive elements

---

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 16+ |
| visionOS SDK | 2.0+ |
| Device | Apple Vision Pro |
| Swift | 5.9+ |

> Simulator is supported for UI development but physics and hand tracking require a real device.

---

## Project Structure

```
PinballVision/
├── PinballVisionApp.swift       # App entry point, volumetric WindowGroup
├── GameModel.swift              # @Observable game state (score, lives, combo, ball save)
├── PinballTableBuilder.swift    # Builds entire table procedurally (walls, bumpers, slingshots, lanes)
├── PinballVolumeView.swift      # Main RealityView — physics, collision, attachments
├── HandTrackingManager.swift    # ARKit HandTrackingProvider, pinch gesture detection
├── SoundManager.swift           # AVAudioEngine synthesized sound effects
├── HUDView.swift                # Score, lives, combo badge, ball save indicator
├── FlipperButton.swift          # Left/right flipper tap buttons with neon style
├── SplashOverlay.swift          # Title screen with animated play button
├── GameOverOverlay.swift        # Game over screen with final score and replay
├── OnboardingOverlay.swift      # First-launch instruction screen
└── Assets.xcassets/             # App icon (3-layer visionOS format)

BlenderModels/
├── pinball_table_body.usdz      # Table shell (procedural fallback used at runtime)
├── pinball_flipper.usdz         # Flipper arm model
├── pinball_bumper.usdz          # Circular bumper model
├── pinball_ball.usdz            # Steel ball model
├── pinball_lane_led.usdz        # Rollover lane LED strip
└── pinball_diagonal_guard.usdz  # Slingshot guard model
```

---

## Getting Started

1. Clone the repo
   ```bash
   git clone https://github.com/pruthvirajsinhpunada/PinballVision.git
   cd PinballVision
   ```

2. Open in Xcode
   ```bash
   open PinballVision.xcodeproj
   ```

3. Set your **Team** in *Signing & Capabilities* (required for hand tracking entitlement)

4. Select the **Apple Vision Pro** destination and run

---

## Controls

| Action | Gesture |
|---|---|
| Left flipper | Pinch left hand (index + thumb) |
| Right flipper | Pinch right hand (index + thumb) |
| Launch ball | Tap the LAUNCH button |
| Left flipper (tap) | Tap the L button in the volume |
| Right flipper (tap) | Tap the R button in the volume |

---

## Scoring

| Target | Base Points |
|---|---|
| Bumper | 100 × multiplier |
| Slingshot | 50 × multiplier |
| Rollover lane | 25 × multiplier |

Multiplier increases with consecutive bumper hits:
- 3–5 hits → ×2
- 6–9 hits → ×3
- 10–14 hits → ×5
- 15+ hits → ×10

---

## Game Center

The leaderboard ID is `com.pruthvirajsinh.PinballVision.highscore`. Create a matching leaderboard in App Store Connect before submitting to the App Store.

---

## App Store Prep Checklist

- [x] `NSHandsTrackingUsageDescription` in Info.plist
- [x] `com.apple.developer.game-center` entitlement
- [x] `PrivacyInfo.xcprivacy` privacy manifest (UserDefaults CA92.1)
- [x] visionOS 3-layer app icon structure (back / middle / front)
- [ ] Add `icon_back.png`, `icon_middle.png`, `icon_front.png` (1024×1024) to AppIcon.appiconset
- [ ] Create Game Center leaderboard in App Store Connect
- [ ] Archive and upload via Xcode → TestFlight

---

## Built With

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) — UI layer
- [RealityKit](https://developer.apple.com/documentation/realitykit) — 3D rendering and physics
- [ARKit](https://developer.apple.com/documentation/arkit) — hand tracking
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine) — real-time audio synthesis
- [GameKit](https://developer.apple.com/documentation/gamekit) — Game Center leaderboards

---

## License

MIT License. See [LICENSE](LICENSE) for details.
