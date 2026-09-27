# Design assets

`Blender/daybreak-chamfered-block.blend` is the editable source for the chamfered block numerals. It contains a clock composition and the full digit set with a colon.

The iOS app renders the original meshes in RealityKit. `clock-app/Resources/Numerals.json` contains local-space vertices, triangle indices, and per-corner normals for `0–9` and `:`. Keeping the corner normals preserves the flat chamfers. The app uses matte white material on the original geometry, a charcoal shadow-receiving backdrop, and a fixed upper-right directional light, following the supplied visual reference. The Blender source materials are unchanged.

To regenerate after editing the Blender source, run from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background \
  DesignAssets/Blender/daybreak-chamfered-block.blend \
  --python DesignAssets/Blender/export_numerals.py
```

Alternatively, run in Blender's Python console with the source file open:

```python
p = '/absolute/path/to/clock-app/DesignAssets/Blender/export_numerals.py'
exec(compile(open(p).read(), p, 'exec'), {'__file__': p, '__name__': '__main__'})
```

The exporter leaves the Blender scene unchanged. The `DesignAssets` folder appears in Xcode but is not included in the app bundle; the exported JSON is included automatically by the app's synchronized resource group.

The preview shows local time as `HH:mm`, including a leading zero, and updates every minute. Front-facing numerals use tight spacing based on their mesh bounds and rest in the top third of the safe area. Drag to orbit the camera horizontally or vertically (up to about 26 degrees) while the numerals stay anchored. The light and shadow-receiving backdrop stay fixed in world space. Releasing returns the camera to its front-facing view with a damped spring; Reduce Motion returns it immediately. The rest of the screen is intentionally empty. The target supports iPhone and iPad only, with iOS 27 as the existing minimum deployment version.

Blender files are tracked with Git LFS through `.gitattributes`. Install Git LFS and run `git lfs install` when setting up a new checkout.
