"""Author an editable ringing bell in a new Blender scene, preserving existing scenes.

Run through Blender MCP with runpy.run_path(..., run_name="__main__").
The app applies the selected clock material and animates the two named pivots.
"""

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Design/Blender/RingingBell/ringing-bell.blend"
DESTINATION = ROOT / "Sunalta/Resources/RingingBell.usdz"


def empty(name, parent=None, location=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.location = location
    return obj


def finish(obj, name, material, parent, location):
    obj.name = name
    obj.parent = parent
    obj.location = location
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def main():
    if bpy.data.objects.get("RingingBell"):
        raise RuntimeError("RingingBell already exists; edit it instead of replacing it")
    scene = bpy.data.scenes.new("Ringing Bell Studio")
    bpy.context.window.scene = scene
    scene.unit_settings.system = "METRIC"
    material = bpy.data.materials.new("Bell_ThemeBlackPlastic")
    material.diffuse_color = (0.0027, 0.0027, 0.0027, 1)
    material.use_nodes = True
    shader = material.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = material.diffuse_color
    shader.inputs["Metallic"].default_value = 0
    shader.inputs["Roughness"].default_value = 0.16
    shader.inputs["Coat Weight"].default_value = 0.8
    shader.inputs["Coat Roughness"].default_value = 0.08

    root = empty("RingingBell")
    swing = empty("BellSwing", root, (0, 0, 1.28))
    # A continuous hollow shell: crown, flared skirt, rolled lip, then inner wall.
    profile = [(0.001, 1.04), (0.18, 1.04), (0.32, 1.00), (0.43, 0.90),
               (0.51, 0.73), (0.55, 0.48), (0.59, 0.16), (0.67, -0.15),
               (0.80, -0.40), (0.98, -0.57), (1.08, -0.62), (1.10, -0.67),
               (1.08, -0.73), (1.02, -0.76), (0.96, -0.73), (0.93, -0.67),
               (0.75, -0.47), (0.61, -0.21), (0.51, 0.14), (0.47, 0.47),
               (0.42, 0.69), (0.31, 0.84), (0.17, 0.91), (0.001, 0.91)]
    segments = 64
    vertices = [(r * math.cos(math.tau * j / segments),
                 r * math.sin(math.tau * j / segments), z - 1.28)
                for r, z in profile for j in range(segments)]
    faces = []
    for i in range(len(profile) - 1):
        for j in range(segments):
            a, b = i * segments + j, i * segments + (j + 1) % segments
            faces.append((a, a + segments, b + segments, b))
    faces += [tuple(reversed(range(segments))),
              tuple((len(profile) - 1) * segments + j for j in range(segments))]
    mesh = bpy.data.meshes.new("HollowBellShell")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    shell = bpy.data.objects.new("BellShell", mesh)
    bpy.context.collection.objects.link(shell)
    finish(shell, "BellShell", material, swing, (0, 0, 0))
    subdivision = shell.modifiers.new("Soft molded edges", "SUBSURF")
    subdivision.levels = subdivision.render_levels = 2

    bpy.ops.mesh.primitive_torus_add(major_radius=0.19, minor_radius=0.065,
                                   major_segments=64, minor_segments=16,
                                   rotation=(math.pi / 2, 0, 0))
    finish(bpy.context.object, "CrownLoop", material, swing, (0, 0, -0.025))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=0.16)
    crown = finish(bpy.context.object, "CrownMount", material, swing, (0, 0, -0.24))
    crown.scale = (1, 1, 0.55)

    clapper = empty("ClapperSwing", swing, (0, 0, -0.38))
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.047, depth=1.68)
    finish(bpy.context.object, "ClapperStem", material, clapper, (0, 0, -0.84))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=0.22)
    finish(bpy.context.object, "ClapperBall", material, clapper, (0, 0, -1.72))

    scene.world = bpy.data.worlds.new("BellStudioWorld")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.35
    for name, location, power, size in [
        ("Large softbox", (-3, -4, 5), 700, 4),
        ("Edge softbox", (3, 1, 3), 900, 3),
        ("Front fill", (1, -4, 0), 120, 2),
    ]:
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name, light.data.energy, light.data.size = name, power, size
        light.rotation_euler = (-light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(3, -8, -1.7))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0.2)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type, camera.data.ortho_scale = "ORTHO", 3.6
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.render.resolution_x = scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "AgX"
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [root, *root.children_recursive]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = shell
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.wm.usd_export(
        filepath=str(DESTINATION), selected_objects_only=True,
        export_animation=False, export_uvmaps=True, export_normals=True,
        export_materials=True, export_lights=False, export_cameras=False,
        generate_preview_surface=True, triangulate_meshes=True,
        convert_orientation=True, export_global_forward_selection="NEGATIVE_Z",
        export_global_up_selection="Y", export_custom_properties=False,
    )
    manifest = {"source": str(SOURCE.relative_to(ROOT)),
                "resource": str(DESTINATION.relative_to(ROOT)),
                "pivots": ["BellSwing", "ClapperSwing"], "upAxis": "Y",
                "ringAxis": "Z", "material": "replaced by theme.clock.numeralMaterial()"}
    SOURCE.with_name("export-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    # Leave the authored model framed in the open Blender window.
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_perspective = "CAMERA"
            area.spaces.active.shading.type = "MATERIAL"


if __name__ == "__main__":
    main()
