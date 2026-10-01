# Third-party code

## Foqos

Source: https://github.com/awaseem/foqos
Reference checkout: `4f6864ce9f821d0dcb873b253dfd786834a047a8`
License: MIT, copyright (c) 2024 Ali Waseem.

`clock-app/Services/Scanning/NFCScannerUtil.swift` adapts Foqos's `Foqos/Utils/NFCScannerUtil.swift` for reading alarm stop-target identifiers. It retains MiFare, ISO15693, and ISO7816 identifier scanning, uses the current Core NFC session API, delivers callbacks on the main actor, and handles cancellation and multiple tags. Profile URL reading and tag writing are omitted. `AlarmStopTarget` also uses Foqos's code-value normalization and NFC hex format.

The complete original notice is in `clock-app/Licenses/Foqos-MIT.txt` and is included in the app bundle.

## CodeScanner

Source: https://github.com/twostraws/CodeScanner
Version: 2.5.2, revision `5e886430238944c7200fc9e10dbf2d9550dba865`.
License: MIT, copyright (c) 2021 Paul Hudson.

CodeScanner is linked through Swift Package Manager. The complete notice is in `clock-app/Licenses/CodeScanner-MIT.txt` and is included in the app bundle.

## Poly Haven — Clock surfaces

Light- and dark-mode numerals: Hangar Concrete Floor by Dimitrios Savva.
Source: https://polyhaven.com/a/hangar_concrete_floor

Bundled alternative surface: Plastered Wall by Amal Kumar.
Source: https://polyhaven.com/a/plastered_wall

Both assets are CC0 (https://polyhaven.com/license). Their original 1K JPEG diffuse, OpenGL normal, roughness, and ambient-occlusion maps are bundled in `clock-app/Resources/Textures/HangarConcrete` and `clock-app/Resources/Textures/PlasteredWall`. Each material loads asynchronously on first use and is shared between clock views.

# Scanner integration

Retain an `NFCScannerUtil` instance for the lifetime of the scanning flow, set `onTagScanned` / `onError`, and call `scan(alarmName:)`. Call `cancel()` when leaving that flow. Use `NFCResult.id` as the `.nfc` target's `codeValue`.

Future camera views can import `CodeScanner` and present `CodeScannerView`. Use the successful `ScanResult.string` as the `.qrCode` target's `codeValue` for both QR codes and barcodes.

Camera and NFC usage descriptions, the NFC `TAG` entitlement, and ISO7816 application identifiers are configured. Device signing must provision NFC access for the app identifier. Actual scans require device testing; no scanning screen has been added yet.
