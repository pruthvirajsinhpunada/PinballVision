import ARKit
import SwiftUI
import Observation

// MARK: - HandTrackingManager
//
// Lets the player control flippers with natural hand pinch gestures:
//   Left  hand pinch  →  left  flipper
//   Right hand pinch  →  right flipper
//
// Works in both the simulator (no hands → button fallback) and on real hardware.

@Observable
final class HandTrackingManager {

    // MARK: - State
    var isSupported  : Bool = false
    var isRunning    : Bool = false
    var leftPinching : Bool = false   // mirrored into GameModel by PinballVolumeView
    var rightPinching: Bool = false

    // MARK: - Private
    private let session      = ARKitSession()
    private let handProvider = HandTrackingProvider()
    private var trackingTask : Task<Void, Never>?

    private static let pinchThreshold: Float = 0.030   // 3 cm

    // MARK: - Lifecycle

    func start() {
        guard HandTrackingProvider.isSupported else {
            isSupported = false
            return
        }
        isSupported = true

        trackingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await session.run([handProvider])
                isRunning = true
                for await update in handProvider.anchorUpdates {
                    process(update.anchor)
                }
            } catch {
                print("[HandTracking] Session error: \(error)")
            }
        }
    }

    func stop() {
        trackingTask?.cancel()
        session.stop()
        isRunning     = false
        leftPinching  = false
        rightPinching = false
    }

    // MARK: - Process anchor

    @MainActor
    private func process(_ anchor: HandAnchor) {
        guard anchor.isTracked,
              let skeleton = anchor.handSkeleton else { return }

        let thumbTip = skeleton.joint(.thumbTip)
        let indexTip = skeleton.joint(.indexFingerTip)

        guard thumbTip.isTracked, indexTip.isTracked else { return }

        // Positions in anchor (hand) space
        let thumbPos  = SIMD3<Float>(anchor.originFromAnchorTransform * thumbTip.anchorFromJointTransform.columns.3)
        let indexPos  = SIMD3<Float>(anchor.originFromAnchorTransform * indexTip.anchorFromJointTransform.columns.3)
        let distance  = simd_distance(thumbPos, indexPos)
        let isPinching = distance < Self.pinchThreshold

        switch anchor.chirality {
        case .left:  leftPinching  = isPinching
        case .right: rightPinching = isPinching
        }
    }
}

// MARK: - SIMD4 → SIMD3 helper

private extension SIMD3<Float> {
    init(_ v: SIMD4<Float>) { self = SIMD3(v.x, v.y, v.z) }
}
