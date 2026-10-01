"""Export original Blender meshes for RealityKit; see ../README.md to run."""
import bpy
import json
import os
from pathlib import Path

root = Path(os.environ.get('CLOCK_APP_ROOT', Path(__file__).resolve().parents[2]))
output = root / 'clock-app/Resources/Numerals.json'
glyphs = {}


def surface_uv(position, normal):
    # Box projection gives the front and extrusion sides equal texture density.
    # Match the renderer's vertical stretch without changing the Blender mesh.
    x, y, z = position
    y *= 1.25
    axis = max(range(3), key=lambda index: abs(normal[index]))
    sign = 1 if normal[axis] >= 0 else -1
    if axis == 0:
        u, v = -sign * z, y
    elif axis == 1:
        u, v = x, -sign * z
    else:
        u, v = sign * x, y
    return [round(0.5 + u / 4.5, 7), round(0.5 + v / 4.5, 7)]


for character in '0123456789:':
    mesh = bpy.data.meshes['Chamfer block ' + character]
    mesh.calc_loop_triangles()
    positions, normals, indices, texture_coordinates = [], [], [], []
    # Keep per-corner normals so the original flat chamfers remain crisp.
    for triangle in mesh.loop_triangles:
        # The source '4' has two collinear back-face triangles. They have no
        # visible area and cannot define a tangent basis for normal mapping.
        if triangle.area < 1e-10:
            continue
        for loop_index in triangle.loops:
            vertex = mesh.vertices[mesh.loops[loop_index].vertex_index]
            positions.append([round(v, 7) for v in vertex.co])
            normals.append([round(v, 7) for v in mesh.corner_normals[loop_index].vector])
            texture_coordinates.append(surface_uv(vertex.co, triangle.normal))
            indices.append(len(indices))
    glyphs[character] = dict(positions=positions, normals=normals, indices=indices,
                             textureCoordinates=texture_coordinates)
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(glyphs, separators=(',', ':')))
print(f'Exported {len(glyphs)} glyphs to {output}')
