# Working in AssetFactory

This folder is the project's offline Three.js asset workshop. Prefer procedural
geometry and ordinary JavaScript modules for new models. The app renders imported
meshes in RealityKit; the viewer is a development tool and is not bundled in iOS.

## Create an asset

1. Run `python3 AssetFactory/new_asset.py <asset-id> --label "Display name"`
   from the repository root. Use a lowercase slug for the asset ID.
2. Work inside `AssetFactory/assets/<asset-id>/`. Edit `asset.mjs` and add local
   textures, configuration, or geometry helpers there. The viewer discovers the
   folder's `asset.json`; do not hardcode new assets into `viewer.mjs` or the server.
3. Import Three.js with `import * as THREE from 'three'`. This resolves to the
   shared, vendored version. Do not add a CDN, npm dependency, or a second copy of
   Three.js for a routine geometry task.
4. Export `async function createAsset({ renderer, reportProgress })`. Return
   `{ models: [{ id, label, object }], views?: [{ id, label, object }] }`.
   Objects must be Three.js Object3D instances containing actual geometry.
   Model and view IDs must be unique lowercase slugs within the asset, at most
   64 characters; views must not reuse a model ID. See the template and README.
5. Keep the exported model's origin, scale, and transforms intentional. Put
   display-only arrangements in `views` using clones, not in the original models.
   The viewer handles bounds, camera, lighting, orbit, background, PNGs, and GLBs.
6. Use `new URL('./config.json', import.meta.url)` for local files. `loadJSON` in
   `../../studio.mjs` checks fetch failures. Call `reportProgress` and yield with
   `await new Promise(requestAnimationFrame)` during long generation loops.
7. Prefer closed geometry, consistent winding, finite normals, and UVs when
   materials need maps. Choose mesh density deliberately. Keep material maps local
   and small where practical. Preserve texture/material provenance in project notices.

## Preview and deliver

- Start `python3 AssetFactory/serve.py` and open http://127.0.0.1:8770.
  `--port <number>` is available when the default port is already occupied.
- Click **Reload assets** after editing code/config or adding a folder. Both the
  catalog and imported modules refresh. The asset/view selection is kept in the URL.
- Check front and angled views and the intended proportions in the browser.
  Export all models; verify the success message and files in that asset's `models/`.
- PNGs and generated manifests are ignored. Source modules, manifests (`asset.json`),
  configurations, textures, and exported GLBs belong in version control.
- Dispose custom event listeners or resources through an optional returned
  `dispose()` callback. The viewer disposes geometry, materials, and material maps
  automatically when switching assets. Avoid background animation loops unless
  the task requires them; static models are the normal export target.
- Do not introduce persistent tests or test runners; the user removed the previous
  test suite. Use syntax checks and direct preview/export checks for asset changes.

## Clock assets

The `clock` recipe contains the approved sculpted geometry and material maps.
Preserve its geometry algorithm when changing the workshop. Its native conversion
is deliberately specific to the clock's untransformed triangle scenes and shared
finish. After exporting clock GLBs, run:

```sh
python3 AssetFactory/assets/clock/import_glyphs.py
```

This updates `clock-app/Resources/SculptedNumerals.clockmesh` and the sandpaper
maps. Other assets export GLB/PNG independently; do not pass arbitrary models to
the clock importer or change native app resources without a requested integration.
