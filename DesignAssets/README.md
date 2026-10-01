# Sculpted clock assets

`ThreeJS/` is the editable, offline Three.js source from the clock handoff. The asset set is digits `0–9` and a colon retained for the asset preview. It contains no weekday words, weekday symbols, or AM/PM assets.

The iOS app continues to render real meshes in RealityKit. `ThreeJS/models/` holds the exported GLBs. `ThreeJS/import_glyphs.py` imports their front faces, backs, sidewalls, analytical normals, and UVs into `clock-app/Resources/SculptedNumerals.clockmesh`, and extracts their shared sandpaper PNG maps. The compact binary format avoids decoding large arrays of JSON floats at launch. Imported geometry is not simplified; the common 3.712-unit cap height is centered around the native clock origin. UVs are converted from the glTF image origin to native texture coordinates.

`ClockGlyphAssets` builds and caches native mesh prototypes. `SculptedClockView` displays two stacked rows (`HH` above `MM`) with aligned digit columns, leading zeros, and no visible colon. Digits are stretched vertically by 15% in the native scene, and the time updates every minute. The same assets render the alarm preview. Orbit gestures, spring return, lighting controls, projected shadows, and scroll snapshots remain available. The stack is centered above the home controls and fitted inside the alarm preview.

Light mode uses the exported black sandpaper color and normal maps, roughness 0.94, and no metalness. Dark mode uses smooth white plastic with no grain or normal map and roughness 0.25. These presets are defined in `ClockAppearance.swift`. RealityKit lighting and tone mapping can differ from the browser preview.

## Edit and export

From the repository root:

```sh
python3 DesignAssets/ThreeJS/serve.py
```

Open http://127.0.0.1:8770. No npm install or CDN is required. Drag to orbit, scroll/pinch to zoom, and right-drag/two-finger drag to pan. Edit `clock-config.json` for ridge paths and proportions, `sculpted-type.mjs` for geometry, and `sandpaper.mjs` for the finish. The task-specific geometry code from the handoff is preserved.

Click **Export PNGs + 3D models** to regenerate all eleven GLBs and optional transparent PNGs. Then import the GLBs for iOS:

```sh
python3 DesignAssets/ThreeJS/import_glyphs.py
```

Commit the source GLBs, native mesh bundle, and extracted maps together. PNG exports and their manifest are ignored because the native app renders the 3D geometry directly. The importer requires the untransformed triangle scenes and shared material maps emitted by this preview; it fails on unsupported input rather than discarding scene transforms or material differences.

`DesignAssets` is visible in Xcode but excluded from the app target. Native meshes and textures under `clock-app/Resources` are bundled automatically by Xcode's synchronized app group. No asset-generation tool runs during an app build.

The original handoff contains dense geometry and notes ridge transitions on 6 and 7 that have not been redesigned in this migration. Device performance should be assessed before adding more instances. Font provenance and the vendored Three.js license are documented in `THIRD_PARTY_NOTICES.md`.
