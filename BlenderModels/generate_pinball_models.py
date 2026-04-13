"""
PinballVision – Blender 5.0 Model Generator (headless / background mode)
Run with:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python generate_pinball_models.py
"""

import bpy
import math
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── Helpers ──────────────────────────────────────────────────────────────────

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)


def apply_all(obj):
    bpy.context.view_layer.objects.active = obj
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)


def shade_smooth(obj):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()


def add_bevel(obj, width=0.004, segments=3):
    mod = obj.modifiers.new("Bevel", 'BEVEL')
    mod.width        = width
    mod.segments     = segments
    mod.limit_method = 'ANGLE'
    mod.angle_limit  = math.radians(30)


def add_subsurf(obj, levels=2):
    mod = obj.modifiers.new("Subsurf", 'SUBSURF')
    mod.levels           = levels
    mod.render_levels    = levels
    mod.subdivision_type = 'CATMULL_CLARK'


def pbr_material(name, base_color, metallic=0.0, roughness=0.5,
                 emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf  = nodes.get("Principled BSDF")

    bsdf.inputs["Base Color"].default_value  = (*base_color, 1.0)
    bsdf.inputs["Metallic"].default_value    = metallic
    bsdf.inputs["Roughness"].default_value   = roughness

    if emission_color and emission_strength > 0:
        bsdf.inputs["Emission Color"].default_value    = (*emission_color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength

    return mat


def export_usdz(obj, filename):
    """Deselect all, select only obj, export as .usdz."""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    path = os.path.join(OUTPUT_DIR, filename)
    bpy.ops.wm.usd_export(
        filepath               = path,
        selected_objects_only  = True,
        export_animation       = False,
        export_materials       = True,
        export_uvmaps          = True,
        export_normals         = True,
        export_meshes          = True,
        export_lights          = False,
        export_cameras         = False,
        generate_preview_surface = True,
        convert_world_material = False,
        export_textures_mode   = 'NEW',
        overwrite_textures     = True,
    )
    print(f"  ✔  {filename}")


# ── 1. Pinball Table Body ────────────────────────────────────────────────────

def make_table_body():
    clear_scene()

    chrome_mat = pbr_material("Chrome",
                              base_color=(0.85, 0.85, 0.85),
                              metallic=0.95, roughness=0.08)
    surface_mat = pbr_material("TableSurface",
                               base_color=(0.02, 0.02, 0.08),
                               metallic=0.0, roughness=0.95)

    def make_box(name, loc, dims, mat):
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = dims
        bpy.ops.object.transform_apply(scale=True)
        obj.data.materials.append(mat)
        return obj

    panel = make_box("TablePanel", (0, 0, 0),    (0.44, 1.00, 0.005), surface_mat)
    lwall = make_box("WallLeft",   (-0.227, 0, 0.065), (0.014, 1.028, 0.13),  chrome_mat)
    rwall = make_box("WallRight",  ( 0.227, 0, 0.065), (0.014, 1.028, 0.13),  chrome_mat)
    twall = make_box("WallTop",    (0,  0.507, 0.065), (0.468, 0.014, 0.13),  chrome_mat)

    for obj in [panel, lwall, rwall, twall]:
        add_bevel(obj, width=0.003, segments=3)
        bpy.context.view_layer.objects.active = obj
        apply_all(obj)
        shade_smooth(obj)

    # Join into one object
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [panel, lwall, rwall, twall]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = panel
    bpy.ops.object.join()
    table = bpy.context.active_object
    table.name = "PinballTableBody"

    export_usdz(table, "pinball_table_body.usdz")


# ── 2. Flipper ───────────────────────────────────────────────────────────────

def make_flipper():
    clear_scene()

    # Tapered wedge: wide at pivot, narrow at tip
    verts = [
        (0.000, -0.010,  0.026), (0.160, -0.006,  0.026),
        (0.000, -0.010, -0.026), (0.160, -0.006, -0.026),
        (0.000,  0.010,  0.026), (0.160,  0.006,  0.026),
        (0.000,  0.010, -0.026), (0.160,  0.006, -0.026),
    ]
    faces = [
        (0, 2, 3, 1),   # bottom
        (4, 5, 7, 6),   # top
        (0, 1, 5, 4),   # front
        (2, 6, 7, 3),   # back
        (0, 4, 6, 2),   # pivot end
        (1, 3, 7, 5),   # tip end
    ]
    mesh = bpy.data.meshes.new("FlipperMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()

    obj = bpy.data.objects.new("Flipper", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    mat = pbr_material("FlipperChrome",
                       base_color=(0.92, 0.92, 0.95),
                       metallic=0.95, roughness=0.06)
    obj.data.materials.append(mat)

    add_bevel(obj, width=0.005, segments=4)
    apply_all(obj)
    shade_smooth(obj)

    export_usdz(obj, "pinball_flipper.usdz")


# ── 3. Bumper ────────────────────────────────────────────────────────────────

def make_bumper():
    clear_scene()

    R = 0.032
    H = 0.058

    # Core neon cylinder
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=R, depth=H,
                                        location=(0, 0, 0))
    body = bpy.context.active_object
    body.name = "BumperBody"
    body.data.materials.append(
        pbr_material("NeonCyan", (0.0, 1.0, 1.0), metallic=0.0, roughness=0.15,
                     emission_color=(0.0, 1.0, 1.0), emission_strength=3.0))
    add_bevel(body, width=0.003, segments=2)
    apply_all(body)
    shade_smooth(body)

    # Outer glow shell
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=R + 0.006,
                                        depth=H + 0.002, location=(0, 0, 0))
    glow = bpy.context.active_object
    glow.name = "BumperGlow"
    glow.data.materials.append(
        pbr_material("NeonGlow", (0.0, 1.0, 1.0), metallic=0.0, roughness=0.5,
                     emission_color=(0.0, 1.0, 1.0), emission_strength=1.2))
    shade_smooth(glow)

    # Bright top cap
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=R * 0.6,
                                        depth=0.004,
                                        location=(0, 0, H / 2 + 0.003))
    cap = bpy.context.active_object
    cap.name = "BumperCap"
    cap.data.materials.append(
        pbr_material("BumperCapMat", (1.0, 1.0, 1.0), metallic=0.0,
                     roughness=0.1, emission_color=(1.0, 1.0, 1.0),
                     emission_strength=5.0))
    shade_smooth(cap)

    # Chrome base ring
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=R + 0.004,
                                        depth=0.006,
                                        location=(0, 0, -H / 2 - 0.001))
    base = bpy.context.active_object
    base.name = "BumperBase"
    base.data.materials.append(
        pbr_material("BumperChrome", (0.8, 0.8, 0.8),
                     metallic=0.9, roughness=0.1))
    shade_smooth(base)

    # Join all bumper pieces
    bpy.ops.object.select_all(action='DESELECT')
    for o in [body, glow, cap, base]:
        o.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    bumper = bpy.context.active_object
    bumper.name = "PinballBumper"

    export_usdz(bumper, "pinball_bumper.usdz")


# ── 4. Steel Ball ────────────────────────────────────────────────────────────

def make_ball():
    clear_scene()

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=4, radius=0.023,
                                          location=(0, 0, 0))
    ball = bpy.context.active_object
    ball.name = "PinballBall"
    ball.data.materials.append(
        pbr_material("MirrorChrome", (1.0, 1.0, 1.0),
                     metallic=1.0, roughness=0.03))
    add_subsurf(ball, levels=2)
    apply_all(ball)
    shade_smooth(ball)

    export_usdz(ball, "pinball_ball.usdz")


# ── 5. Diagonal Guard ────────────────────────────────────────────────────────

def make_diagonal_guard():
    clear_scene()

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    guard = bpy.context.active_object
    guard.name = "DiagonalGuard"
    guard.scale = (0.13, 0.014, 0.065)
    bpy.ops.object.transform_apply(scale=True)
    guard.data.materials.append(
        pbr_material("GuardChrome", (0.75, 0.75, 0.78),
                     metallic=0.85, roughness=0.15))
    add_bevel(guard, width=0.004, segments=3)
    apply_all(guard)
    shade_smooth(guard)

    export_usdz(guard, "pinball_diagonal_guard.usdz")


# ── 6. Lane LED Dot ──────────────────────────────────────────────────────────

def make_lane_led():
    clear_scene()

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.005,
                                        depth=0.002, location=(0, 0, 0))
    led = bpy.context.active_object
    led.name = "LaneLED"
    led.rotation_euler.x = math.radians(90)
    bpy.ops.object.transform_apply(rotation=True)
    led.data.materials.append(
        pbr_material("LEDBlue", (0.4, 0.6, 1.0), metallic=0.0, roughness=0.1,
                     emission_color=(0.4, 0.6, 1.0), emission_strength=8.0))
    shade_smooth(led)

    export_usdz(led, "pinball_lane_led.usdz")


# ── Main ─────────────────────────────────────────────────────────────────────

print("\n=== PinballVision – Generating Blender 5 Models ===\n")
make_table_body()
make_flipper()
make_bumper()
make_ball()
make_diagonal_guard()
make_lane_led()
print("\n=== All done! Files in:", OUTPUT_DIR, "===\n")
