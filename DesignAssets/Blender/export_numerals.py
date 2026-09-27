"""Export original Blender meshes for RealityKit; see ../README.md to run."""
import bpy
import json
import os
from pathlib import Path

root = Path(os.environ.get('CLOCK_APP_ROOT', Path(__file__).resolve().parents[2]))
output = root / 'clock-app/Resources/Numerals.json'
glyphs = {}
for character in '0123456789:':
    mesh = bpy.data.meshes['Chamfer block ' + character]
    mesh.calc_loop_triangles()
    positions, normals, indices = [], [], []
    # Keep per-corner normals so the original flat chamfers remain crisp.
    for triangle in mesh.loop_triangles:
        for loop_index in triangle.loops:
            vertex = mesh.vertices[mesh.loops[loop_index].vertex_index]
            positions.append([round(v, 7) for v in vertex.co])
            normals.append([round(v, 7) for v in mesh.corner_normals[loop_index].vector])
            indices.append(len(indices))
    glyphs[character] = dict(positions=positions, normals=normals, indices=indices)
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(glyphs, separators=(',', ':')))
print(f'Exported {len(glyphs)} glyphs to {output}')
