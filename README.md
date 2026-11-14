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

## Continuous integration

[Tests](.github/workflows/tests.yml) runs `SunaltaTests` on every pull request using
Xcode 27.1 and the iPhone 17 simulator on iOS 27.0. It uses GitHub's hosted
[`xcode-27` runner](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md),
currently a preview image. No self-hosted runner or signing secrets are required.
New commits cancel an older run for the same pull request.

The `ios-test-results` artifact contains the Xcode result bundle and build log,
retained for seven days, including when tests fail. After the workflow is on the
default branch, it can also be started manually from the Actions tab.
To require passing tests before merging, add `iOS tests` as a required status check
in the repository's branch protection rule or ruleset.
