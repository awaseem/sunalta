# Sunalta website

A minimal Astro site in the app repository. It uses the White theme's actual sculpted numerals, arranged like the app's home screen, followed by a short introduction. No separate Git repository or deployment has been created.

This directory has no Xcode target membership and stays outside the native app, widget, and test builds. Debug and Release additionally exclude the `sites` folder reference and omit it from recursive search paths. Xcode's filename exclusions are not recursive: do not add this directory or individual website files to native targets. Keep all website code, dependencies, generated output, and export tooling here.

## Branding

Standard product copy:

- **Sunalta**
- **A simple, sculpted alarm clock.**
- Get out of bed and scan an NFC tag or QR code to stop your alarm. Start your day on your feet.
- Made in Calgary, AB by [Ali Waseem](https://x.com/softwarecuddler).

Keep the page, SEO description, and generated sharing artwork aligned with this positioning. The shared footer follows the page content in normal document flow, with the creator credit, Privacy, Support, and Source code links in one row separated by dots. On narrow screens the links sit below the credit. The page fills at least the viewport, placing the footer at the bottom on short pages. Longer pages grow naturally, so the whole page scrolls and the footer is reached after the content; it is never pinned over the page.

The minimal `/privacy/` page describes local app data, scanning permissions, Apple-handled tips, and support correspondence. `/support/` directs visitors to [@softwarecuddler on X](https://x.com/softwarecuddler). Both pages describe Sunalta as free and open source and link to [the GitHub repository](https://github.com/awaseem/sunalta). Keep the privacy copy aligned with the app's behavior when adding data collection or services.

The clock, introduction, and footer use a brief, staggered CSS entrance fade. Content starts partially visible and stays in the initial HTML; the effect requires neither JavaScript nor scrolling and changes no layout dimensions. Reduced-motion preferences skip the animation, and keyboard focus reveals links immediately.

## Run locally

Requires Node.js 22.23.4+ (or a supported newer even-numbered release).

From the repository root:

```sh
make website-install
make website-dev
```

Use `make website-check` to check Astro/TypeScript and `make website-build` to build `dist/`. Stop the development server with Ctrl-C.

The equivalent npm commands from this directory are:

```sh
cd sites/sunalta
npm ci
npm run dev
```

Open the local address printed by Astro and use Ctrl-C in the terminal to stop the server. `npm run check` checks Astro/TypeScript and `npm run build` writes a static site to `dist/`.

## Publish later

Copy `.env.example` to `.env` and set `SITE_URL` to the final public HTTPS origin. Rebuild and deploy `dist/` to any static host. No server adapter is required. Until a public origin is configured, the page and robots.txt discourage indexing and no canonical URL is emitted.

Apple's official badge links to [Sunalta on the App Store](https://apps.apple.com/us/app/sunalta/id6830356035) by default, including in local previews. `PUBLIC_APP_STORE_URL` can optionally override the destination with another `https://apps.apple.com/…` URL; an unset or blank value uses the approved listing.

The unmodified SVG in `public/download-on-the-app-store.svg` comes from [Apple's official badge asset](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg), referenced by its [marketing guidelines](https://developer.apple.com/app-store/marketing/guidelines/). It is displayed at 120 × 40 px with at least 10 px clear space. Keep the artwork's original proportions, border, wording, and colors.

The site includes static, readable HTML; descriptive titles and descriptions; canonical URLs; Open Graph and Twitter metadata; a 1200 × 630 sharing image; SoftwareApplication JSON-LD on the home page; robots.txt; and a sitemap covering Home, Privacy, and Support. Canonical, sharing-image URLs, and sitemap entries derive from `SITE_URL`. There are no invented ratings or pricing claims. Discoverability still depends on deploying to a public domain and search engines indexing it.

## Clock artwork

The clock shows the visitor's local time in 24-hour format. It changes once per minute and pauses updates when the page is hidden. The server-rendered 09:41 clock remains usable without JavaScript or when a live image fails to load. Text alternatives describe the time without making minute changes live announcements.

The numerals are **pre-rendered 3D artwork**, not an interactive WebGL scene. This keeps the app's native rendering and avoids shipping a 3D framework or the 7 MB mesh to every visitor. Astro optimizes the PNG sources to WebP at build time; the browser loads only the four layers needed for the current minute. There are no external fonts, analytics, or cookies.

To regenerate artwork on a Mac with Xcode and GPU access:

```sh
npm run assets
```

For sharing-image copy changes only, edit the wording in `scripts/RenderClockAssets.swift` and run `npm run assets -- --social-only`. This uses the existing clock poster and leaves all numeral artwork unchanged.

The exporter reads the app's `SharpNumerals.clockmesh`, `ClockStudio.exr`, and app icon. It compiles with the app's existing mesh reader and offscreen renderer and reproduces the White theme's material, two-row arrangement, 12° camera, key light, and red weekday accent. A fixed crop includes the widest bounds of all ten digits so a minute change cannot clip a numeral. The exported PNGs are checked in, so normal website builds need neither Xcode nor the app source.

If the app's geometry, material, or lighting changes, update `scripts/RenderClockAssets.swift` to match the corresponding Swift definitions and rerun the exporter. The web page reproduces the resting clock; native drag rotation, entrance animation, bird flybys, and audio are not included.
