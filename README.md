# Sunalta

A simple, sculpted alarm clock for iPhone, designed to get you physically out of bed. Scan an NFC tag or QR code to stop your alarm and start your day on your feet.

Built with SwiftUI. Open `Sunalta.xcodeproj` and run the `Sunalta` scheme. The project currently targets iOS 27 and uses the Swift 6 language mode.

The minimal Astro website lives in [`sites/sunalta`](sites/sunalta/README.md). Run `npm ci` and `npm run dev` from that directory for a local preview.

`sites/` is website-only and has no Xcode target membership. Keep it outside the app, widget, and test targets' synchronized source folders and resource phases. Debug and Release also exclude the `sites` folder reference through `EXCLUDED_SOURCE_FILE_NAMES` and omit `sites` from recursive search paths; all three native targets inherit these settings. Target membership is the main boundary: Xcode's filename exclusions are not recursive, so do not add individual website files to native targets. Website source, dependencies, build output, and asset-export scripts stay separate from the iOS app; build the website with npm.

Sunalta uses a fresh app identity: `dev.ambitionsoftware.sunalta` for the app and `dev.ambitionsoftware.sunalta.SunaltaWidgets` for its widget extension. Register both bundle identifiers and the shared App Group `group.dev.ambitionsoftware.sunalta` for signed device builds. The URL scheme is `sunalta`, and tip product IDs use the `sunalta_tip_` prefix.

## Brand and product copy

Use **Sunalta** consistently as the app name. Keep the language simple, direct, and encouraging. Lead with the sculpted clock and the practical reason to get out of bed; avoid vague promises about calm or productivity.

- **Standard subheading:** A simple, sculpted alarm clock.
- **Website description:** Get out of bed and scan an NFC tag or QR code to stop your alarm. Start your day on your feet.
- **Closing line:** Start your day on your feet.
- **Footer:** Made in Calgary, AB by [Ali Waseem](https://x.com/softwarecuddler).

The scan requirement applies to alarms configured with an NFC or QR stop target. Product explanations should make this clear when describing setup; Sunalta also supports ordinary alarms.

The website pairs this copy with the White theme's sculpted numerals and Apple's official black **Download on the App Store** badge. Use the supplied badge unchanged, at least 40 px high with one-quarter-height clear space, following [Apple's marketing guidelines](https://developer.apple.com/app-store/marketing/guidelines/). The local preview shows the badge without a link until `PUBLIC_APP_STORE_URL` is configured. See the [website README](sites/sunalta/README.md) for development, SEO, and asset details.

## Active alarm screen

Ringing and snoozed alarms remain active until stopped (or scanned, for QR/NFC alarms). Snooze keeps the alarm screen open with a resting bell and a countdown replacing the Snooze button. The native Close button returns to the alarms page without ending the session. Its primary-color, text-only “Active alarm” toolbar island reopens the session; scheduled alarms that have not rung do not show an island. A snoozed alarm that rings again brings its screen back automatically.

Sixteen of each theme's home-screen creatures cross the alarm screen from left to right in two spread-out groups of eight, behind the numbers, bell, text, and controls. They fade in near the left edge and fade out near the right, following the home screen's shallow curves and staggered starts. Each bird crosses in roughly five seconds. All sixteen finish before a 2.5-second quiet pause; the next bell swing peak starts the next group. These passive flybys continue during snooze without affecting alarm behavior. Reduce Motion disables the decorative motion.

For an interactive simulator check, add `--preview-active-alarm` to the Debug scheme's launch arguments. This uses an isolated in-memory alarm and simulated AlarmKit operations, with a one-minute snooze that automatically rings again. It does not schedule real system alerts. Optional arguments: `--preview-snoozed`, `--preview-alarm-island`, `--preview-12-hour`, and `--preview-scan-alarm` (QR).

Check Snooze → countdown replaces the Snooze button → Close → Active alarm toolbar island → reopen → Stop. Also leave the screen closed until snooze expires, and confirm it returns to ringing. Stop should remove the island. QR/NFC alarms must still require a matching scan, including during snooze. Use a device to check real AlarmKit notifications and Lock Screen actions.

The alarm countdown Live Activity uses the same White, Midnight, and Grass palette as the app, read from the shared widget preferences. Scan and stop actions use capsule controls; the Dynamic Island and system ringing alert use contrasting monochrome controls on their system-owned dark surfaces. AlarmKit controls the ringing alert's layout. Existing scheduled alarms adopt the updated alert tint on the next app refresh; active sessions are left intact. `AlarmCountdownPreview.swift` includes NFC, QR, snooze, and larger-text previews. Verify the system alert, scan reminder, and scan action on a physical device.

Run the session regression tests with:

```sh
xcodebuild test -project Sunalta.xcodeproj -scheme Sunalta \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  -only-testing:SunaltaTests/AlarmSessionTests
```

## Home Screen clock widget

The initial widget supports **Small (`systemSmall`)** only. It shows an abbreviated weekday above a large single row of hours and minutes, separated by a wider gap, with an optional AM/PM label beside the weekday in 12-hour mode. It follows the app's White, Midnight, or Grass theme and clock-format settings. The weekday and time use the same entry date, calendar, locale, and time zone. All themes use four layers captured through `ClockRenderView`, preserving the home page's camera, materials, and key lighting, including Grass's actual blade geometry. The weekday accent light shines down from the header onto the tops of the hour digits. The row is captured in its final position and scales uniformly with the widget; the extension composes bundled images rather than running a 3D renderer. Custom lighting/background adjustments and animation remain app-only. Tinted and clear Home Screen appearances desaturate the same scene layers, using Midnight's lighter material for otherwise-black White numerals.

The app and widget share one versioned presentation snapshot through the App Group `group.dev.ambitionsoftware.sunalta`. Enable that App Group for both bundle identifiers when provisioning a device build. Existing app preferences remain in place; launching the app publishes them to the shared suite. Only changed snapshots request a reload. The widget has no access to the SwiftData alarm store. Tapping it opens `sunalta://clock`, dismissing settings or the alarm editor and returning to the clock; a ringing alarm retains priority.

The provider supplies six hours of minute-aligned entries and requests a new timeline after an hour. This avoids requesting an extension reload every minute and provides a buffer when reloads are delayed. Entries advance by absolute time across midnight and daylight-saving changes, and format in the widget's local calendar, locale, and time zone. WidgetKit controls delivery and may delay or coalesce updates; this is not a seconds-accurate clock. Device testing should include background refresh restrictions, travel between time zones, and long periods without opening the app. See [Apple's timeline guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

`SmallClockWidget.swift` includes previews for all three themes. Check tinted/clear appearances and larger text sizes with the preview controls. Regression tests cover the shared snapshot and timeline boundaries. The existing alarm Live Activity and Dynamic Island remain in the same widget bundle. Larger widgets, next-alarm content, and Lock Screen widget families are deferred from issue #18.

### Regenerating widget artwork

Launch a Debug build with `--export-widget-scenes` and keep it foregrounded until `Documents/WidgetScenes/<theme>/complete.txt` exists for all three themes. Import with:

```sh
python3 Scripts/import-widget-scenes.py /path/to/app/Documents/WidgetScenes
```

Each theme exports 40 transparent layers: ten numerals in each position of the final widget row. Each layer uses the same camera and crop, including Grass's blade tips. Grass's widget numerals are widened by 16% within their columns for fuller shapes and tighter visible gaps. `ClockWidgetComposition` shares the header and numeral framing between the exporter and live widget layout. The accent uses each theme's default color, brightness, spread, and reach, aimed downward from a fixed reference weekday area; the label itself remains localized SwiftUI text. This is a baked approximation of the abbreviated label's light, not a new render for each weekday or text size. Each export also includes a `preview.png` showing Mon at 09:41. The importer validates the complete set and calendar-layout marker before copying unchanged PNGs into the asset catalog. Source/image hashes are in `Design/WidgetScenes/export-manifest.json`. Re-export after changing the mesh, composition, materials, or theme lighting. The app icon export (`--export-theme-icons`) retains its original framing.

## Support and tips

Support is available through the Donations button grouped with Settings at the bottom left of the alarms page and under Settings → About → Support. Tips are optional, one-time consumable in-app purchases; they do not unlock features or create a subscription. The page uses StoreKit's localized product prices and only shows thanks after a verified transaction succeeds.

### App Store Connect setup

These consumables are configured in the [Sunalta App Store Connect record](https://appstoreconnect.apple.com/apps/6830356035/distribution/iaps) (`dev.ambitionsoftware.sunalta`). The product IDs must match `TipStore.productIDs` exactly.

| Product ID | Type | Reference and display name | US base price | English description |
| --- | --- | --- | --- | --- |
| `sunalta_tip_small` | Consumable | Small Tip | $1.99 USD | A small thank you for Sunalta. |
| `sunalta_tip_generous` | Consumable | Generous Tip | $4.99 USD | Support the development of Sunalta. |
| `sunalta_tip_extra` | Consumable | Extra Generous Tip | $9.99 USD | Give extra support to Sunalta development. |

ASC IDs are `6830937132` (small), `6830937088` (generous), and `6830937128` (extra). Each has en-US and en-CA metadata, a US base price with Apple's automatic localized prices, availability in all 175 current storefronts, review instructions, and a screenshot of the tip screen. All three were verified as `READY_TO_SUBMIT` on November 4, 2026; they have not been submitted for review.

Before release:

1. Include these initial consumables with the app version submitted for review. [Submission guide](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
2. Complete the app's availability and any outstanding Paid Apps agreement, tax, or banking setup in App Store Connect.
3. Test the configured products in Apple's sandbox. In the Xcode scheme, set Run → Options → StoreKit Configuration to None **and disable the `--local-storekit` launch argument**. Allow time for new product metadata to reach the sandbox. TestFlight and App Store builds always use Apple's catalog.

This is developer tipping through Apple in-app purchase under [App Review Guideline 3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase).

### Local testing

`Sunalta/Resources/SupportTips.storekit` contains the three local test products and is selected in the shared scheme's Run options. The Run and Test actions also pass `--local-storekit`. For Debug simulator builds, this starts and retains an `SKTestSession` during app initialization, before the transaction listener opens a StoreKit connection. Initializing the session later in a test can leave that connection pointed at the sandbox and return an empty product list.

When using XcodeBuildMCP, pass `launchArgs: ["--local-storekit"]` to `build_run_sim`. When launching directly, use `xcrun simctl launch booted dev.ambitionsoftware.sunalta --local-storekit`. These launches do not apply Xcode's scheme options automatically. Local purchases use Apple's simulated store without real charges. The startup helper is compiled only into Debug simulator builds; device and Release builds do not link StoreKitTest.

`TipStoreTests` uses `SKTestSession` to exercise the purchase flow. Run it from Xcode's Test Navigator or run:

```sh
xcodebuild test -project Sunalta.xcodeproj -scheme Sunalta \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  -only-testing:SunaltaTests/TipStoreTests
```

For manual checks, use Xcode's StoreKit transaction manager to simulate approval of pending purchases and StoreKit errors. Check cancellation, retry, rapid repeated taps, returning to the clock while approval is pending, and the thank-you screen after approval. Also check White, Midnight, and Grass themes, larger Dynamic Type, VoiceOver, and iPad sheet layouts.

The app displays a retryable unavailable state if Apple's catalog has no available products. The local StoreKit configuration does not create products in App Store Connect or configure production payments.
