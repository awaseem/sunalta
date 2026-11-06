<p align="center">
  <img src="./Sunalta/Assets.xcassets/AppIcon.appiconset/Any.png" width="250" alt="Sunalta app icon">
</p>

<h1 align="center">Sunalta</h1>

<p align="center">
  A simple, sculpted alarm clock for iPhone. Scan an NFC tag or QR code to stop your alarm and start your day on your feet.
</p>

## Local development

Use Xcode with the iOS 27 SDK and run the `Sunalta` scheme.

```sh
open Sunalta.xcodeproj
make lint              # Check Swift formatting
make test              # Run unit tests
make help              # List all commands
```

The website requires Node.js 22.23.4+:

```sh
make website-install   # Install dependencies
make website-dev       # Start the dev server
make website-check     # Check Astro and TypeScript
make website-build     # Build the website
```
