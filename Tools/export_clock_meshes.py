"""Export the saved sharp Blender scene for RealityKit without regenerating its geometry.

Run Blender --background --factory-startup --python Tools/export_clock_meshes.py.
The source .blend is opened read-only and is never saved by this script.
"""

from array import array
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

import bpy

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ThirdParty/Blender/ClockSharp/clock-sharp.blend"
DESTINATION = ROOT / "clock-app/Resources/SharpNumerals.clockmesh"
MANIFEST = SOURCE.with_name("export-manifest.json")
CHARACTERS = "0123456789:"


def evaluated_surface(character, depsgraph):
    name = "Colon" if character == ":" else "Digit 7 — approved" if character == "7" else f"Digit {character}"
    glyph = bpy.data.objects.get(name)
    if glyph is None or glyph.type != "MESH":
        raise ValueError(f"Missing Blender mesh: {name}")
    evaluated = glyph.evaluated_get(depsgraph)
    surface = evaluated.to_mesh()
    try:
        surface.calc_loop_triangles()
        positions, normals, indices, lookup = [], [], [], {}
        for triangle in surface.loop_triangles:
            for loop_index in triangle.loops:
                position = surface.vertices[surface.loops[loop_index].vertex_index].co
                normal = surface.corner_normals[loop_index].vector
                values = tuple(round(value, 8) for value in (*position, *normal))
                if not all(math.isfinite(value) for value in values):
                    raise ValueError(f"Non-finite mesh data: {name}")
                if values not in lookup:
                    lookup[values] = len(positions)
                    positions.append(values[:3])
                    normals.append(values[3:])
                indices.append(lookup[values])
        if not positions or not indices:
            raise ValueError(f"Empty Blender mesh: {name}")
        # Object locations arrange the editing scene. Keep each glyph's local
        # coordinates; the app positions its own four persistent digit slots.
        return positions, normals, indices
    finally:
        evaluated.to_mesh_clear()


def write_array(output, kind, values):
    data = array(kind, values)
    if sys.byteorder != "little":
        data.byteswap()
    output.write(data.tobytes())


def main():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    if bpy.data.libraries:
        raise ValueError("The source scene must include its meshes without external Blender libraries")
    depsgraph = bpy.context.evaluated_depsgraph_get()
    glyphs = {character: evaluated_surface(character, depsgraph) for character in CHARACTERS}
    low = min(position[1] for character in "0123456789" for position in glyphs[character][0])
    high = max(position[1] for character in "0123456789" for position in glyphs[character][0])
    center_y = (low + high) / 2
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    temporary = DESTINATION.with_suffix(".tmp")
    with temporary.open("wb") as output:
        # v2: little-endian glyph count, then code/vertex/index counts followed
        # by Float32 positions, Float32 corner normals, and UInt32 indices.
        # The glossy Blender surfaces use no UVs or texture maps.
        output.write(b"CLKMESH2")
        output.write(struct.pack("<I", len(glyphs)))
        for character, (positions, normals, indices) in glyphs.items():
            output.write(struct.pack("<III", ord(character), len(positions), len(indices)))
            write_array(output, "f", (value for x, y, z in positions for value in (x, y - center_y, z)))
            write_array(output, "f", (value for vector in normals for value in vector))
            write_array(output, "I", indices)
    temporary.replace(DESTINATION)
    manifest = {
        "source": str(SOURCE.relative_to(ROOT)),
        "sourceSHA256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "blenderVersion": bpy.app.version_string,
        "resource": str(DESTINATION.relative_to(ROOT)),
        "resourceSHA256": hashlib.sha256(DESTINATION.read_bytes()).hexdigest(),
        "format": "CLKMESH2",
        "centerYOffset": center_y,
        "glyphs": {character: {"vertices": len(positions), "triangles": len(indices) // 3}
                   for character, (positions, _, indices) in glyphs.items()},
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
    triangles = sum(len(indices) // 3 for _, _, indices in glyphs.values())
    print(f"Exported {len(glyphs)} sharp Blender glyphs ({triangles:,} triangles) to {DESTINATION}")


if __name__ == "__main__":
    main()
