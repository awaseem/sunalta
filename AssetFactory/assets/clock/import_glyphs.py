"""Import the exported Three.js digit GLBs into the native clock's mesh bundle.

Run from any directory with Python 3. No third-party packages are required.
The source meshes, normals, and UVs are retained; only the common baseline is
centered for the native camera. This deliberately accepts the handoff's simple,
untransformed glTF scene rather than silently ignoring unsupported glTF features.
"""

from array import array
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parent
RESOURCES = ROOT.parents[2] / "clock-app" / "Resources"


def load_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError(f"Invalid GLB: {path.name}")
    chunks = {}
    offset = 12
    while offset < len(data):
        size, kind = struct.unpack_from("<I4s", data, offset)
        chunks[kind] = data[offset + 8:offset + 8 + size]
        offset += 8 + size
    return json.loads(chunks[b"JSON"]), chunks[b"BIN\x00"]


def accessor(document, binary, index):
    entry = document["accessors"][index]
    if "sparse" in entry or entry.get("normalized", False):
        raise ValueError("Sparse/normalized accessors are unsupported")
    view = document["bufferViews"][entry["bufferView"]]
    if view.get("buffer", 0) != 0:
        raise ValueError("Only the embedded GLB buffer is supported")
    component = {5126: "f", 5125: "I", 5123: "H", 5121: "B"}[entry["componentType"]]
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[entry["type"]]
    record = struct.Struct("<" + component * width)
    start = view.get("byteOffset", 0) + entry.get("byteOffset", 0)
    stride = view.get("byteStride", record.size)
    return [record.unpack_from(binary, start + i * stride) for i in range(entry["count"])]


def image(document, binary, texture_index):
    source = document["images"][document["textures"][texture_index]["source"]]
    if source["mimeType"] != "image/png":
        raise ValueError("Expected an embedded PNG material map")
    view = document["bufferViews"][source["bufferView"]]
    start = view.get("byteOffset", 0)
    return binary[start:start + view["byteLength"]]


def write_array(output, kind, values):
    data = array(kind, values)
    if sys.byteorder != "little":
        data.byteswap()
    output.write(data.tobytes())


def main():
    cap_height = json.loads((ROOT / "clock-config.json").read_text())["height"]
    glyphs = {}
    maps = None
    for character in "0123456789:":
        name = "colon" if character == ":" else f"digit-{character}"
        document, binary = load_glb(ROOT / "models" / f"{name}.glb")
        nodes = document["nodes"]
        positions, normals, coordinates, indices = [], [], [], []

        def visit(index):
            nonlocal maps
            node = nodes[index]
            if any(key in node for key in ("matrix", "translation", "rotation", "scale", "skin")):
                raise ValueError(f"Unexpected node transform/skin in {name}")
            if "mesh" in node:
                for primitive in document["meshes"][node["mesh"]]["primitives"]:
                    if primitive.get("mode", 4) != 4 or "targets" in primitive:
                        raise ValueError("Expected triangle meshes without morph targets")
                    attributes = primitive["attributes"]
                    p = accessor(document, binary, attributes["POSITION"])
                    n = accessor(document, binary, attributes["NORMAL"])
                    uv = accessor(document, binary, attributes["TEXCOORD_0"])
                    local = ([v[0] for v in accessor(document, binary, primitive["indices"])]
                             if "indices" in primitive else list(range(len(p))))
                    if len(p) != len(n) or len(p) != len(uv) or len(local) % 3 or any(i >= len(p) for i in local):
                        raise ValueError(f"Invalid mesh buffers in {name}")
                    base = len(positions)
                    positions.extend((x, y - cap_height / 2, z) for x, y, z in p)
                    normals.extend(n)
                    # glTF images use a top-left origin; native UVs use bottom-left.
                    coordinates.extend((u, 1 - v) for u, v in uv)
                    indices.extend(i + base for i in local)
                    material = document["materials"][primitive["material"]]
                    pbr = material["pbrMetallicRoughness"]
                    current_maps = (image(document, binary, pbr["baseColorTexture"]["index"]),
                                    image(document, binary, material["normalTexture"]["index"]))
                    if maps is not None and current_maps != maps:
                        raise ValueError("The native finish expects shared sandpaper maps")
                    if pbr["roughnessFactor"] != 0.94 or pbr["metallicFactor"] != 0:
                        raise ValueError("Update ClockAppearance to match the exported finish")
                    maps = current_maps
            for child in node.get("children", []):
                visit(child)

        for index in document["scenes"][document.get("scene", 0)]["nodes"]:
            visit(index)
        if not positions:
            raise ValueError(f"Empty glyph: {name}")
        glyphs[character] = positions, normals, coordinates, indices

    RESOURCES.mkdir(parents=True, exist_ok=True)
    destination = RESOURCES / "SculptedNumerals.clockmesh"
    with destination.open("wb") as output:
        output.write(b"CLKMESH1")
        output.write(struct.pack("<I", len(glyphs)))
        for character, (positions, normals, coordinates, indices) in glyphs.items():
            output.write(struct.pack("<III", ord(character), len(positions), len(indices)))
            for vectors in (positions, normals, coordinates):
                write_array(output, "f", (value for vector in vectors for value in vector))
            write_array(output, "I", indices)
    textures = RESOURCES / "Textures" / "Sandpaper"
    textures.mkdir(parents=True, exist_ok=True)
    for name, data in zip(("sandpaper-color.png", "sandpaper-normal.png"), maps):
        (textures / name).write_bytes(data)
    print(f"Imported {len(glyphs)} glyphs, {sum(len(g[3]) // 3 for g in glyphs.values()):,} triangles "
          f"into {destination.name} ({destination.stat().st_size / 1_000_000:.1f} MB)")


if __name__ == "__main__":
    main()
