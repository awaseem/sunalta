# Third-party notices

## Foqos

Source: https://github.com/awaseem/foqos
Reference checkout: `4f6864ce9f821d0dcb873b253dfd786834a047a8`
License: MIT, copyright (c) 2024 Ali Waseem.

`Sunalta/Features/Alarms/Scanning/NFCScannerUtil.swift` adapts Foqos's `Foqos/Utils/NFCScannerUtil.swift` for reading alarm stop-target identifiers. It retains MiFare, ISO15693, and ISO7816 identifier scanning, uses the current Core NFC session API, delivers callbacks on the main actor, and handles cancellation and multiple tags. Profile URL reading and tag writing are omitted. `AlarmStopTarget` also uses Foqos's code-value normalization and NFC hex format.

The complete original notice is in `Sunalta/Licenses/Foqos-MIT.txt` and is included in the app bundle.

## CodeScanner

Source: https://github.com/twostraws/CodeScanner
Version: 2.5.2, revision `5e886430238944c7200fc9e10dbf2d9550dba865`.
License: MIT, copyright (c) 2021 Paul Hudson.

CodeScanner is linked through Swift Package Manager. The complete notice is in `Sunalta/Licenses/CodeScanner-MIT.txt` and is included in the app bundle.

## Sharp Blender numerals

Editable source: `Design/Blender/ClockSharp/clock-sharp.blend`.
Exporter and usage: `Tools/export_clock_meshes.py`.
Source and native-resource hashes: `Design/Blender/ClockSharp/export-manifest.json`.

The saved scene was supplied in the project's sharp Blender asset set. The app
uses its evaluated meshes, bevels, and corner normals, exported directly to
`Sunalta/Resources/SharpNumerals.clockmesh`. The `.blend` remains a development
source and is excluded from the iOS bundle. No Three.js code is retained or shipped.

The numeral outlines derive from the Impact outlines supplied in the original
handoff. They are an Impact approximation, not Obviously Condensed Black. Font
use and redistribution remain subject to the original font license; no external
model author or separate model license was provided with the supplied scene.

## Studio lighting

`Sunalta/Resources/ClockStudio.skybox/ClockStudio.exr` is Apple's unmodified
`studio_lighting_objectmode_v002.exr`, published for use in third-party renderers.

Source: https://developer.apple.com/sample-code/ar/studio_lighting_objectmode_v002.exr
Documentation: https://developer.apple.com/documentation/arkit/specifying-a-lighting-environment-in-ar-quick-look
