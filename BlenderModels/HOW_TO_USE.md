# PinballVision – Blender Model Pipeline

## Step 1 – Generate the models in Blender

1. Open **Blender 3.6 / 4.x**
2. Go to the **Scripting** workspace (top menu bar)
3. Click **Open** and select `generate_pinball_models.py` (this folder)
4. Click **Run Script** (▶ button or Numpad Enter)
5. Six `.usdz` files will appear in this folder:
   - `pinball_table_body.usdz`
   - `pinball_flipper.usdz`
   - `pinball_bumper.usdz`
   - `pinball_ball.usdz`
   - `pinball_diagonal_guard.usdz`
   - `pinball_lane_led.usdz`

## Step 2 – Add models to Xcode

Drag all `.usdz` files into your Xcode project navigator under
`PinballVision/` (make sure "Copy items if needed" is checked).

## Step 3 – Load them in Swift (PinballTableBuilder.swift)

Replace any `ModelEntity(mesh: MeshResource.generateXxx(...))` call
with the USDZ loader. Example:

```swift
// Ball
let ball = try! await ModelEntity(named: "pinball_ball")
// Bumper
let bumper = try! await ModelEntity(named: "pinball_bumper")
// Flipper
let flipper = try! await ModelEntity(named: "pinball_flipper")
```

Or synchronously (no async needed for bundled USDZ):

```swift
let ball = try! ModelEntity.loadModel(named: "pinball_ball")
```

## Customising colours / materials in Blender

Each object has its own PBR material. To change the bumper neon colour:
- Select the bumper cylinder in the 3D viewport
- Open the **Material Properties** panel (sphere icon)
- Adjust **Base Color** and **Emission Color** on the `NeonCyan` material
- Re-run the script (or export manually: File → Export → USD)

## Tips

- The flipper's **origin is at its pivot point** (left end) so RealityKit
  rotation works correctly out-of-the-box.
- All models are centred at world origin and use **metres** (matching
  RealityKit's coordinate system).
- Emission maps bake into the USDZ so the neon glow is visible even
  without a RealityKit `PointLightComponent`.
