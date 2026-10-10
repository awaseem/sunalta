# Sharp Blender numeral source

[`clock-sharp.blend`](clock-sharp.blend) is the editable source of the app's digits
0–9 and colon. It preserves the approved sharp Blender set, including the approved
seven, narrow bevels, raised ridges, and per-corner shading normals.

This file came from the project's supplied `clock-blender-sharp` asset set. It is
stored under Design/Blender alongside the other source assets; no external author or model
license is asserted. The source used the handoff's Impact-derived outlines. The
original font's license still governs those outlines and derived geometry; see
[`THIRD_PARTY_NOTICES.md`](../../../THIRD_PARTY_NOTICES.md).

The scene contains its meshes and modifiers without linked Blender libraries or
external images. Object locations arrange the editing scene and are not used by
the app. Edit the existing mesh objects in Blender; the exporter evaluates their
modifiers and centers their common baseline for the native camera.

## Export to the app

From the repository root, using the installed Blender:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python Tools/export_clock_meshes.py
```

The exporter reads the saved scene without modifying it. It writes
`clock-app/Resources/SharpNumerals.clockmesh` and `export-manifest.json`, which
records the source and resource SHA-256 hashes, Blender version, and mesh counts.
No JavaScript viewer, GLB export, or procedural geometry recipe is required.

Only the native mesh resource is bundled in iOS. The `.blend`, manifest, and export
script remain development sources. Swift supplies adaptive glossy plastic
materials and lighting; no texture maps are required.

The `CLKMESH2` resource contains an 8-byte signature and a little-endian UInt32
glyph count. Each glyph has UInt32 character, vertex count, and index count fields,
then Float32 XYZ positions, Float32 XYZ corner normals, and UInt32 triangle indices.
