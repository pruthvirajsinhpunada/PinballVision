"""
PinballVision – View All Models in Blender GUI
Opens Blender and imports all exported USDZ pieces into one scene,
laid out in a nice showcase arrangement with lighting and camera.
"""

import bpy
import os
import math

MODELS_DIR = os.path.dirname(os.path.abspath(__file__))

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col)

def import_usdz(filename, location, rotation_z=0, scale=1.0):
    path = os.path.join(MODELS_DIR, filename)
    if not os.path.exists(path):
        print(f"  ⚠  Not found: {filename}")
        return
    before = set(bpy.data.objects.keys())
    bpy.ops.wm.usd_import(filepath=path)
    after  = set(bpy.data.objects.keys())
    new_objs = [bpy.data.objects[n] for n in (after - before)]
    for obj in new_objs:
        obj.location = location
        obj.rotation_euler.z = rotation_z
        obj.scale = (scale, scale, scale)
    print(f"  ✔  {filename}  →  {location}")

def setup_lighting():
    # Key light
    bpy.ops.object.light_add(type='AREA', location=(2, -2, 3))
    key = bpy.context.active_object
    key.data.energy = 500
    key.data.size   = 3
    key.rotation_euler = (math.radians(60), 0, math.radians(45))

    # Fill light (soft blue)
    bpy.ops.object.light_add(type='AREA', location=(-3, 1, 2))
    fill = bpy.context.active_object
    fill.data.energy = 150
    fill.data.color  = (0.4, 0.6, 1.0)

    # Neon rim light from below (cyan – arcade feel)
    bpy.ops.object.light_add(type='POINT', location=(0, 0, -0.5))
    rim = bpy.context.active_object
    rim.data.energy = 800
    rim.data.color  = (0.0, 1.0, 1.0)

def setup_camera():
    bpy.ops.object.camera_add(location=(0, -4.5, 1.2))
    cam = bpy.context.active_object
    cam.rotation_euler = (math.radians(82), 0, 0)
    bpy.context.scene.camera = cam

def set_viewport_shading():
    for area in bpy.context.screen.areas:
        if area.type == 'VIEW_3D':
            for space in area.spaces:
                if space.type == 'VIEW_3D':
                    space.shading.type = 'MATERIAL'
                    space.shading.use_scene_lights = True
                    space.shading.use_scene_world  = False
                    space.shading.studio_light      = 'forest.exr'

# ── Main ─────────────────────────────────────────────────────────────────────

clear_scene()

# Layout: table body centre, other parts spread around it
import_usdz("pinball_table_body.usdz",    location=( 0.00,  0.00, 0.00))
import_usdz("pinball_bumper.usdz",         location=(-1.20,  0.00, 0.00), scale=3.0)
import_usdz("pinball_flipper.usdz",        location=( 1.20,  0.20, 0.00), scale=3.0)
import_usdz("pinball_ball.usdz",           location=( 1.20, -0.30, 0.00), scale=3.0)
import_usdz("pinball_diagonal_guard.usdz", location=(-1.20, -0.30, 0.00), scale=4.0)
import_usdz("pinball_lane_led.usdz",       location=( 0.00,  1.20, 0.00), scale=8.0)

setup_lighting()
setup_camera()
set_viewport_shading()

# Frame all objects in viewport
bpy.ops.object.select_all(action='SELECT')
for area in bpy.context.screen.areas:
    if area.type == 'VIEW_3D':
        region = next((r for r in area.regions if r.type == 'WINDOW'), None)
        if region:
            with bpy.context.temp_override(area=area, region=region):
                bpy.ops.view3d.view_selected()
        break

print("\n=== All PinballVision models loaded — enjoy the view! ===\n")
