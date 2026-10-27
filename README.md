# Clock App

A SwiftUI clock and alarm app. Open `clock-app.xcodeproj` and run the `clock-app` scheme. The project currently targets iOS 27 and uses the Swift 6 language mode.

## Support and tips

Support is available beside Settings on the alarms page and under Settings → About → Support. Tips are optional, one-time consumable in-app purchases; they do not unlock features or create a subscription. The page uses StoreKit's localized product prices and only shows thanks after a verified transaction succeeds.

### App Store Connect setup

Create these products in the Clock App record (`dev.ambitionsoftware.clock-app`) when creating the listing. The IDs must match `TipStore.productIDs` exactly.

| Product ID | Type | Reference and display name | US base price | English description |
| --- | --- | --- | --- | --- |
| `clock_app_tip_small` | Consumable | Small Tip | $1.99 USD | A small thank you to support Clock App development. |
| `clock_app_tip_generous` | Consumable | Generous Tip | $4.99 USD | Support the continued development of Clock App. |
| `clock_app_tip_extra` | Consumable | Extra Generous Tip | $9.99 USD | Give extra support to the continued development of Clock App. |

1. In App Store Connect, open Clock App → Monetization → In-App Purchases and add the three consumables. [Apple's creation guide](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases)
2. Add the English names and descriptions above, choose availability, and set the US base prices. Review Apple's prices for other storefronts; the app displays the localized amount returned by StoreKit. [Pricing guide](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase)
3. Complete the required purchase metadata and review screenshots. Suggested review note: “Optional developer tips. Open the alarms page, then Support beside Settings, or Settings → About → Support. All clock and alarm features remain available without a tip.”
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
