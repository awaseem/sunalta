# Clock App

A SwiftUI clock and alarm app. Open `clock-app.xcodeproj` and run the `clock-app` scheme. The project currently targets iOS 27 and uses the Swift 6 language mode.

## Home Screen clock widget

The initial widget supports **Small (`systemSmall`)** only. It shows an abbreviated weekday above a large single row of hours and minutes, separated by a wider gap, with an optional AM/PM label beside the weekday in 12-hour mode. It follows the app's White, Midnight, or Grass theme and clock-format settings. The weekday and time use the same entry date, calendar, locale, and time zone. All themes use four layers captured through `ClockRenderView`, preserving the home page's camera, materials, and key lighting, including Grass's actual blade geometry. The weekday accent light shines down from the header onto the tops of the hour digits. The row is captured in its final position and scales uniformly with the widget; the extension composes bundled images rather than running a 3D renderer. Custom lighting/background adjustments and animation remain app-only. Tinted and clear Home Screen appearances desaturate the same scene layers, using Midnight's lighter material for otherwise-black White numerals.

The app and widget share one versioned presentation snapshot through the App Group `group.dev.ambitionsoftware.clock-app`. Enable that App Group for both bundle identifiers when provisioning a device build. Existing app preferences remain in place; launching the app publishes them to the shared suite. Only changed snapshots request a reload. The widget has no access to the SwiftData alarm store. Tapping it opens `clock-app://clock`, dismissing settings or the alarm editor and returning to the clock; a ringing alarm retains priority.

The provider supplies six hours of minute-aligned entries and requests a new timeline after an hour. This avoids requesting an extension reload every minute and provides a buffer when reloads are delayed. Entries advance by absolute time across midnight and daylight-saving changes, and format in the widget's local calendar, locale, and time zone. WidgetKit controls delivery and may delay or coalesce updates; this is not a seconds-accurate clock. Device testing should include background refresh restrictions, travel between time zones, and long periods without opening the app. See [Apple's timeline guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

`SmallClockWidget.swift` includes previews for all three themes. Check tinted/clear appearances and larger text sizes with the preview controls. Regression tests cover the shared snapshot and timeline boundaries. The existing alarm Live Activity and Dynamic Island remain in the same widget bundle. Larger widgets, next-alarm content, and Lock Screen widget families are deferred from issue #18.

### Regenerating widget artwork

Launch a Debug build with `--export-widget-scenes` and keep it foregrounded until `Documents/WidgetScenes/<theme>/complete.txt` exists for all three themes. Import with:

```sh
python3 Scripts/import-widget-scenes.py /path/to/app/Documents/WidgetScenes
```

Each theme exports 40 transparent layers: ten numerals in each position of the final widget row. Each layer uses the same camera and crop, including Grass's blade tips. `ClockWidgetComposition` shares the header and numeral framing between the exporter and live widget layout. The accent uses each theme's default color, brightness, spread, and reach, aimed downward from a fixed reference weekday area; the label itself remains localized SwiftUI text. This is a baked approximation of the abbreviated label's light, not a new render for each weekday or text size. Each export also includes a `preview.png` showing Mon at 09:41. The importer validates the complete set and calendar-layout marker before copying unchanged PNGs into the asset catalog. Source/image hashes are in `Design/WidgetScenes/export-manifest.json`. Re-export after changing the mesh, composition, materials, or theme lighting. The app icon export (`--export-theme-icons`) retains its original framing.

## Support and tips

Support is available through the Donations button grouped with Settings at the bottom left of the alarms page and under Settings → About → Support. Tips are optional, one-time consumable in-app purchases; they do not unlock features or create a subscription. The page uses StoreKit's localized product prices and only shows thanks after a verified transaction succeeds.

### App Store Connect setup

Create these products in the Clock App record (`dev.ambitionsoftware.clock-app`) when creating the listing. The IDs must match `TipStore.productIDs` exactly.

| Product ID | Type | Reference and display name | US base price | English description |
| --- | --- | --- | --- | --- |
| `clock_app_tip_small` | Consumable | Small Tip | $1.99 USD | A small thank you to support Clock App development. |
| `clock_app_tip_generous` | Consumable | Generous Tip | $4.99 USD | Support the continued development of Clock App. |
| `clock_app_tip_extra` | Consumable | Extra Generous Tip | $9.99 USD | Give extra support to the continued development of Clock App. |

1. In App Store Connect, open Clock App → Monetization → In-App Purchases and add the three consumables. [Apple's creation guide](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases)
2. Add the English names and descriptions above, choose availability, and set the US base prices. Review Apple's prices for other storefronts; the app displays the localized amount returned by StoreKit. [Pricing guide](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase)
3. Complete the required purchase metadata and review screenshots. Suggested review note: “Optional developer tips. Open the alarms page, then the Donations heart button at the bottom left, or Settings → About → Support. All clock and alarm features remain available without a tip.”
4. Include these initial consumables with the app version submitted for review. [Submission guide](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
5. Test the configured products in Apple's sandbox before release. In the Xcode scheme, set Run → Options → StoreKit Configuration to None when testing App Store Connect products. Allow time for new product metadata to reach the sandbox.

This is developer tipping through Apple in-app purchase under [App Review Guideline 3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase).

### Local testing

`clock-app/Resources/SupportTips.storekit` contains the three local test products and is selected in the shared scheme's Run options. Run from Xcode to use its simulated store without an App Store listing or real charges. Launching directly with `simctl` does not activate the scheme's StoreKit configuration. This file does not create products in App Store Connect or configure production payments.

`TipStoreTests` uses `SKTestSession` to exercise the purchase flow. Run it from Xcode's Test Navigator or run:

```sh
xcodebuild test -project clock-app.xcodeproj -scheme clock-app \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  -only-testing:ClockAppTests/TipStoreTests
```

For manual checks, use Xcode's StoreKit transaction manager to simulate approval of pending purchases and StoreKit errors. Check cancellation, retry, rapid repeated taps, returning to the clock while approval is pending, and the thank-you screen after approval. Also check White, Midnight, and Grass themes, larger Dynamic Type, VoiceOver, and iPad sheet layouts.

Keep real App Store Connect configuration for the listing step; the app displays a retryable unavailable state until products are available.
