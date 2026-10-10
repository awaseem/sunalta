"""Export the saved alarm-clock model with UVs, separate materials, and hand pivots.

blender --background --factory-startup --python Tools/export_alarm_clock.py
The source is read without saving or replacing any authored edits.
"""

import hashlib
import json
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Design/Blender/AlarmClock/alarm-clock.blend"
DESTINATION = ROOT / "clock-app/Resources/AlarmClock.usdz"


def main():
    if not bpy.app.background:
        raise RuntimeError("Export in a separate background process")
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    root = bpy.data.objects["AlarmClock"]
    bpy.ops.object.select_all(action="DESELECT")
    # Curves become portable meshes; all hand roots retain their local axle origins.
    for obj in list(root.children_recursive):
        if obj.type in {"CURVE", "FONT"}:
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.convert(target="MESH")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [root, *root.children_recursive]:
        obj.select_set(True)
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.usd_export(
        filepath=str(DESTINATION), selected_objects_only=True,
        export_animation=False, export_uvmaps=True, export_normals=True,
        export_materials=True, export_lights=False, export_cameras=False,
        generate_preview_surface=True, triangulate_meshes=True,
        convert_orientation=True, export_global_forward_selection="NEGATIVE_Z",
        export_global_up_selection="Y", export_custom_properties=False,
    )
    meshes = [obj for obj in root.children_recursive if obj.type == "MESH"]
    for obj in meshes:
        obj.data.calc_loop_triangles()
    manifest = {
        "source": str(SOURCE.relative_to(ROOT)),
        "sourceSHA256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "resource": str(DESTINATION.relative_to(ROOT)),
        "resourceSHA256": hashlib.sha256(DESTINATION.read_bytes()).hexdigest(),
        "blenderVersion": bpy.app.version_string,
        "casingGroup": "Casing",
        "hands": ["HourHand", "MinuteHand"],
        "upAxis": "Y", "faceNormal": "+Z", "handRotationAxis": "Z",
        "meshes": len(meshes),
        "triangles": sum(len(obj.data.loop_triangles) for obj in meshes),
    }
    SOURCE.with_name("export-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Exported {manifest['meshes']} meshes to {DESTINATION}")


if __name__ == "__main__":
    main()
