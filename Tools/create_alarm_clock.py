"""Create a six-mesh twin-bell clock in an isolated background Blender process."""

import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Design/Blender/AlarmClock/alarm-clock.blend"


def material(name, color, roughness, coat=0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Coat Weight"].default_value = coat
    return result


def empty(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def mesh_object(name, vertices, faces, mat, parent, smooth=False):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    mesh.materials.append(mat)
    for polygon in mesh.polygons:
        polygon.use_smooth = smooth
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def lathe(name, profile, segments, mat, parent):
    # Cylindrical UVs keep authored casing textures usable on every rounded part.
    vertices = [(radius * math.cos(math.tau * j / segments), -depth,
                 radius * math.sin(math.tau * j / segments))
                for radius, depth in profile for j in range(segments + 1)]
    faces = []
    for i in range(len(profile) - 1):
        for j in range(segments):
            a = i * (segments + 1) + j
            faces.append((a, a + 1, a + segments + 2, a + segments + 1))
    obj = mesh_object(name, vertices, faces, mat, parent, smooth=True)
    uv = obj.data.uv_layers.new(name="UVMap")
    lengths = [0.0]
    for a, b in zip(profile, profile[1:]):
        lengths.append(lengths[-1] + math.dist(a, b))
    for polygon in obj.data.polygons:
        for loop in polygon.loop_indices:
            i, j = divmod(obj.data.loops[loop].vertex_index, segments + 1)
            uv.data[loop].uv = (j / segments, lengths[i] / lengths[-1])
    return obj


def join(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    bpy.context.object.name = name
    # Bake the active part's transform so RealityKit measures the combined mesh directly.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def casing(mat, parent):
    profile = [(0.001, -0.64), (1.12, -0.64), (1.19, -0.58), (1.23, -0.46),
               (1.23, 0.17), (1.20, 0.24), (1.14, 0.26), (1.075, 0.24),
               (1.055, 0.19), (0.001, 0.19)]
    parts = [lathe("Shell", profile, 64, mat, parent)]
    bell_profile = [(0.001, 0), (0.46, 0), (0.46, 0.035),
                    (0.38, 0.19), (0.20, 0.31), (0.001, 0.35)]
    for side in [-1, 1]:
        bell = lathe("Bell", bell_profile, 32, mat, parent)
        bell.location = (side * 0.78, 0, 1.12)
        bell.rotation_mode = "QUATERNION"
        bell.rotation_quaternion = Vector((0, -1, 0)).rotation_difference(
            Vector((side * 0.38, 0, 0.925)).normalized())
        parts.append(bell)
    join(parts, "Shell")


def rod(start, end, radius, mat, parent):
    start, end = Vector(start), Vector(end)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius,
                                       depth=(end - start).length, location=(start + end) / 2)
    obj = bpy.context.object
    obj.parent = parent
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference((end - start).normalized())
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = len(polygon.vertices) == 4
    return obj


def hardware(mat, parent):
    parts = []
    for side in [-1, 1]:
        parts.append(rod((side * 0.68, 0, -0.92), (side * 0.96, -0.06, -1.50), 0.065, mat, parent))
        parts.append(rod((side * 0.50, 0, 0.97), (side * 0.78, 0, 1.26), 0.045, mat, parent))
    parts.append(rod((0, 0, 1.15), (0, 0, 1.60), 0.025, mat, parent))
    parts.append(rod((-0.13, 0, 1.61), (0.13, 0, 1.61), 0.045, mat, parent))
    parts.append(rod((0, -0.24, 0), (0, -0.28, 0), 0.07, mat, parent))
    # A low-resolution curve gives the handle a readable silhouette without small details.
    curve = bpy.data.curves.new("Handle", "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth, curve.bevel_resolution = 0.035, 1
    spline = curve.splines.new("POLY")
    points = [(-0.66, 0, 1.42), (-0.60, 0, 1.83), (-0.50, 0, 1.98),
              (-0.30, 0, 2.05), (0.30, 0, 2.05), (0.50, 0, 1.98),
              (0.60, 0, 1.83), (0.66, 0, 1.42)]
    spline.points.add(len(points) - 1)
    for point, xyz in zip(spline.points, points):
        point.co = (*xyz, 1)
    obj = bpy.data.objects.new("Handle", curve)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
    parts.append(bpy.context.object)
    join(parts, "Hardware")


def hand(name, length, width, depth, mat, parent):
    pivot = empty(name, parent)
    pivot.location.y = -depth
    outline = [(-width, -0.08), (width, -0.08), (width, length),
               (0, length + 0.04), (-width, length)]
    mesh_object(name + "Shape", [(x, 0, z) for x, z in outline],
                [tuple(range(len(outline)))], mat, pivot)


def main():
    if not bpy.app.background:
        raise RuntimeError("Use a separate background process, leaving the open scene untouched")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    black = material("Casing_GlossyBlack", (0.0027, 0.0027, 0.0027), 0.16, coat=0.8)
    white = material("Dial_White", (0.91, 0.915, 0.9), 0.8)
    ink = material("Dial_Ink", (0.008, 0.009, 0.012), 0.8)
    metal = material("Hardware_Silver", (0.32, 0.34, 0.36), 0.28)
    metal.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.8
    root = empty("AlarmClock")
    casing(black, empty("Casing", root))
    hardware(metal, root)
    dial = empty("Dial", root)
    face = [(1.065 * math.cos(math.tau * i / 64), -0.205,
             1.065 * math.sin(math.tau * i / 64)) for i in range(64)]
    mesh_object("Face", face, [tuple(range(64))], white, dial)

    # Twelve flat marks share one mesh and one material; no raised lettering.
    vertices, faces = [], []
    for index in range(12):
        angle = math.tau * index / 12
        length = 0.15 if index % 3 == 0 else 0.08
        start = len(vertices)
        for x, z in [(-0.018, 0.96 - length), (0.018, 0.96 - length),
                     (0.018, 0.96), (-0.018, 0.96)]:
            vertices.append((x * math.cos(angle) + z * math.sin(angle), -0.211,
                             z * math.cos(angle) - x * math.sin(angle)))
        faces.append(tuple(range(start, start + 4)))
    mesh_object("HourMarks", vertices, faces, ink, dial)
    hand("HourHand", 0.52, 0.045, 0.23, ink, root)
    hand("MinuteHand", 0.78, 0.026, 0.245, ink, root)

    # Editing preview only: the exporter includes just the AlarmClock hierarchy.
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("StudioWorld")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.5
    bpy.ops.object.camera_add(location=(0.5, -7, 1.4))
    camera = bpy.context.object
    camera.rotation_euler = (-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type, camera.data.ortho_scale = "ORTHO", 4.3
    scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(-3, -4, 5))
    light = bpy.context.object
    light.data.energy, light.data.size = 650, 4
    light.rotation_euler = (-light.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.render.resolution_x = scene.render.resolution_y = 600
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    bpy.context.preferences.filepaths.save_version = 0
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    print(f"Saved simple clock to {SOURCE}")


if __name__ == "__main__":
    main()
