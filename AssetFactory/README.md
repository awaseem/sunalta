# AssetFactory

An offline Three.js workshop for creating, presenting, and exporting 3D assets.
The shared viewer discovers asset folders automatically. Each asset supplies its
geometry and materials; camera controls, framing, studio lighting, backdrops,
PNG export, and GLB export are shared.

## Start the workshop

From the repository root:

```sh
python3 AssetFactory/serve.py
```

Open http://127.0.0.1:8770. No npm install or CDN is needed. Use `--port 8771`
if another process owns the default port. Choose an asset and a view, drag to
orbit, scroll/pinch to zoom, and right-drag to pan. **Reset camera** restores the
front view; **Angled view** shows the depth. The backdrop can be studio, dark,
or transparent checkerboard. Lighting is shared across recipes.

**Reload assets** rediscovers folders and refreshes source/config files. Direct
links such as `?asset=clock&view=stacked` reopen a particular presentation.
Invalid manifests or model contracts produce errors instead of silent replacements.

## Make another asset

```sh
python3 AssetFactory/new_asset.py desk-object --label "Desk object"
```

Edit `AssetFactory/assets/desk-object/asset.mjs`, then click **Reload assets**.
The scaffolder refuses to overwrite an existing asset. The included `rounded-block`
recipe demonstrates the same template without any clock dependencies.

```text
AssetFactory/
  assets/
    clock/             Sculpted digits, configuration, maps, native importer
    rounded-block/     Example standalone procedural model
    <asset-name>/
      asset.json       Display name, description, entry module
      asset.mjs        Geometry/material recipe
      models/          Exported GLBs
      png/             Generated transparent previews (ignored)
      manifest.json    Generated export metadata (ignored)
  templates/asset.mjs   Starting point for new recipes
  studio.mjs           Shared lighting, framing, stats, resource disposal
  viewer.mjs           Catalog selection, rendering, export
  vendor/              Shared offline Three.js runtime and exporters
  serve.py             Catalog endpoint and scoped local export server
  new_asset.py         Asset scaffolder
  AGENTS.md            Instructions for coding agents
```

## Recipe contract

An asset folder needs `asset.json`:

```json
{
  "label": "Desk object",
  "description": "A sculpted object for the clock app.",
  "module": "asset.mjs"
}
```

Its entry module imports the shared Three.js runtime and exports `createAsset`:

```js
import * as THREE from 'three';

export async function createAsset({ renderer, reportProgress }) {
  reportProgress('Building the object…');
  const object = new THREE.Group();
  object.add(new THREE.Mesh(
    new THREE.BoxGeometry(1, 2, .5),
    new THREE.MeshStandardMaterial({ color: 0x4c776e, roughness: .5 }),
  ));
  return { models: [{ id: 'main', label: 'Main model', object }] };
}
```

`models` is a nonempty array of exportable Object3Ds. Optional `views` use the same
`{ id, label, object }` shape to present compositions, variants, or arrangements;
they are preview-only. The viewer lists views first, followed by individual models.
IDs are unique lowercase slugs (letters, digits, hyphens), at most 64 characters.
Keep original model transforms intentional and use clones for presentation layouts.
The module may return a `dispose()` callback for additional resources/listeners.

For sets that need identical PNG sizing and a shared baseline, return an optional
`exportFrame: { pixels: [600, 900], center: [0, 1.856, 0], width: 2, height: 3.712,
margin: .45 }`. Without this, each model is fitted automatically to a 900×900 PNG.
This affects PNG framing only; GLBs preserve model coordinates and real materials.

Read [AGENTS.md](AGENTS.md) before creating or modifying assets.

## Export

Click **Export all GLBs + PNGs**. Output is scoped to the selected asset:

- `models/<model-id>.glb`: real geometry, materials, and embedded texture maps.
- `png/<model-id>.png`: transparent front view under the shared studio lights.
- `manifest.json`: output filenames, PNG frames, and pixel/world scale metadata.

Export restores the camera and backdrop afterward. Models remain reusable in the
viewer. GLBs are source deliverables; generated PNGs/manifests are ignored. The
local server binds only to loopback and only accepts exports into registered asset
folders. Native integration is a separate, asset-specific step.

## Clock integration

The `clock` recipe preserves the sculpted Impact approximation, its analytical
normals, closed backs/sidewalls, and seeded sandpaper finish from the handoff.
It exports digits `0–9` and a colon. The browser also presents the native app's
stacked `HH` / `MM` composition, using the same 15% vertical stretch in the view.

After exporting the clock's eleven GLBs:

```sh
python3 AssetFactory/assets/clock/import_glyphs.py
```

The importer updates `clock-app/Resources/SculptedNumerals.clockmesh` and the
shared sandpaper PNG maps. Its compact native buffers retain the GLB geometry,
normals, and UVs, with the 3.712-unit cap height centered for the native camera.
It rejects unsupported scene transforms or material differences. Other assets
export independently and are not automatically added to the iOS app.

The iOS clock caches these native meshes and displays leading-zero hours above
minutes, without a visible colon. Light mode uses black sandpaper; dark mode uses
smooth white plastic. Orbit gestures, lighting controls, projected shadows, and
scroll snapshots remain available. Browser lighting and tone mapping can differ
from RealityKit.

`AssetFactory` is visible in Xcode and excluded from the app target. Native resources
under `clock-app/Resources` are bundled automatically; app builds run no generators.
The dense clock geometry and the handoff's existing ridge transitions on 6 and 7
are preserved. Three.js/font provenance is recorded in `THIRD_PARTY_NOTICES.md`.
