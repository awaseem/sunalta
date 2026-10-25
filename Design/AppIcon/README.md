# Theme app icons

The app icon is a close crop of the upper half of the sculpted **1** used by the clock. Its stem continues through the bottom edge. White uses black plastic, Midnight uses white plastic, and Grass uses the clock's procedural grass surface. Each uses the theme's background and authored lighting.

## Editable source and exports

- Mesh source: `Design/Blender/ClockSharp/clock-sharp.blend` (see its README and `THIRD_PARTY_NOTICES.md`).
- Runtime mesh: `clock-app/Resources/SharpNumerals.clockmesh`.
- Materials and light: `clock-app/Features/Themes/Definitions/`, `ClockAppearance+Materials.swift`, and the clock's `GrassSurface` implementation.
- Framing and export: `clock-app/Features/Themes/Debug/ThemeIconExporter.swift`. This uses RealityRenderer offscreen with the actual clock scene and is excluded from Release builds.
- Final assets: `clock-app/Assets.xcassets/{AppIcon,AppIconMidnight,AppIconGrass}.appiconset/`.
- App Store artwork: `clock-app/Assets.xcassets/AppIcon.appiconset/Any.png` (1024 × 1024, opaque sRGB).

All three sets provide Any, Dark, and grayscale Tinted images. Dark retains the selected material with a darker background. Tinted uses a light silhouette over black; iOS applies the user's chosen tint and derives the clear appearance. The files are square with no baked-in corner mask.

## Regenerate

Build and install the Debug app on an iPhone simulator, then launch it with `--export-theme-icons`. The export is independent of saved appearance adjustments, current theme, and Home Screen appearance. Wait for `Documents/ThemeIcons/complete.txt` in the app's data container.

```sh
# Replace SIMULATOR_UDID with the booted iPhone simulator's ID.
xcrun simctl launch SIMULATOR_UDID dev.ambitionsoftware.clock-app --export-theme-icons
xcrun simctl get_app_container SIMULATOR_UDID dev.ambitionsoftware.clock-app data
python3 Tools/import_theme_icons.py /path/from/previous/command/Documents/ThemeIcons
```

Stop an already-running app before launching with the export argument. The importer validates dimensions, opacity, and grayscale tinted images before copying all nine assets. Rebuild and reinstall to refresh the icon catalog.

## Theme synchronization

`AppTheme.appIconName` identifies a compiled alternate icon; White uses `nil` to restore the primary icon. `ThemeAppIcon` serializes asynchronous changes and coalesces pending selections. The app reconciles the selected theme on launch, theme changes, and foreground activation, without requesting an already-installed icon again. Failed requests are logged and can retry on the next selection or foreground activation.

iOS presents its standard confirmation alert after a successful icon change. There is no custom confirmation flow. Lighting and background adjustments inside a theme do not change its pre-rendered icon.

## Validation

- iPhone 17 simulator, iOS 27: theme selection and system confirmation; installed icons on Home Screen and in App Library; default, dark, tinted, and clear appearance.
- 12 theme/icon tests: saved settings, in-flight changes returning to the primary icon, failure/retry, foreground reconciliation, and avoiding duplicate updates.
- Unsigned generic iOS Release archive succeeds with no warnings or missing icon assets. A signed App Store distribution validation remains a release step.

Apple references: [asset catalog icons](https://developer.apple.com/documentation/xcode/configuring-your-app-icon), [alternate icons](https://developer.apple.com/documentation/xcode/configuring-your-app-to-use-alternate-app-icons).
