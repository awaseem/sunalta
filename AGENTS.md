# Agent guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift and SwiftUI. Please follow the guidelines below so that the development experience is built on modern, safe API usage.

## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.

## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency. Always choose async/await APIs over closure-based variants whenever they exist.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.

## Swift instructions

- `@Observable` classes must be marked `@MainActor` unless the project has Main Actor default actor isolation. Flag any `@Observable` class missing this annotation.
- All shared data should use `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing).
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless they are unavoidable, or if they exist in legacy/integration contexts when changing architecture would be complicated.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.
- Never use legacy `Formatter` subclasses such as `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter`. Always use the modern `FormatStyle` API instead. For example, to format a date, use `myDate.formatted(date: .abbreviated, time: .shortened)`. To parse a date from a string, use `Date(inputString, strategy: .iso8601)`. For numbers, use `myNumber.formatted(.number)` or custom format styles.

## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap’s location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don’t apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- Use the newest ScrollView APIs for item scrolling and positioning (e.g. `ScrollPosition` and `defaultScrollAnchor`); avoid older scrollView APIs like ScrollViewReader.
- Extract complex presentation logic when it benefits from independent testing; do not introduce abstractions just to test simple views. Follow the project-specific architecture below.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.

## SwiftData instructions

If SwiftData is configured to use CloudKit:

- Never use `@Attribute(.unique)`.
- Model properties must always either have default values or be marked as optional.
- All relationships must be marked optional.

## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write focused tests for meaningful edge cases, bug regressions, and complex application logic.
- Add UI tests only for a concrete behavioral regression that cannot be covered by a unit or integration test.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.
- If the project uses Localizable.xcstrings, prefer to add user-facing strings using symbol keys (e.g. helloWorld) in the string catalog with `extractionState` set to "manual", accessing them via generated symbols such as  `Text(.helloWorld)`. Offer to translate new keys into all languages supported by the project.

## PR instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.

## Xcode MCP

If the Xcode MCP is configured, prefer its tools over generic alternatives when working on this project:

- `DocumentationSearch` — verify API availability and correct usage before writing code
- `BuildProject` — build the project after making changes to confirm compilation succeeds
- `GetBuildLog` — inspect build errors and warnings
- `RenderPreview` — visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues` — check for issues visible in the Xcode Issue Navigator
- `ExecuteSnippet` — test a code snippet in the context of a source file
- `XcodeRead`, `XcodeWrite`, `XcodeUpdate` — prefer these over generic file tools when working with Xcode project files

---

## Project-specific architecture: SwiftUI-Native MV + Services

These project-specific rules take precedence over general architecture suggestions above, including the suggestion to always move view logic into ViewModels. Preserve the upstream Swift and SwiftUI guidance unless it conflicts with this section.

### Layers and responsibilities

- **Views:** Own presentation and ephemeral state. Use `@Query` for reactive SwiftData reads, `@State` for view-owned state, and `@Bindable` for editable observable models. Simple CRUD may use `@Environment(\.modelContext)` directly.
- **ViewModels (optional):** Introduce `@Observable` ViewModels only for meaningful presentation logic, asynchronous UI workflows, navigation coordination, loading, or error state. Prefer `@MainActor`. Do not create a ViewModel for every screen.
- **Services / use cases:** Centralize reusable business rules, validation, and multi-step writes. Inject `ModelContext` or other required dependencies explicitly. Keep services feature-specific and avoid singletons.
- **Models / domain:** Use SwiftData `@Model` for persisted entities, properties, relationships and simple invariants. Put pure calculations in plain Swift types independent of SwiftUI and persistence.

### State and persistence

- Prefer the direct path **SwiftUI View ↔ `@Query` / SwiftData** for straightforward screens. A ViewModel is not a mandatory intermediary.
- Do not mirror a `@Query` array into a second observable array without a concrete reason; maintain one source of truth.
- Use `FetchDescriptor` for imperative queries in services; apply predicates, sort descriptors and limits when appropriate.
- Keep persistence boundaries explicit for significant operations. Handle thrown `save()` errors; do not depend on autosave for critical multi-step business actions.
- Define relationships and delete rules intentionally. Test schema changes and migrations; never silently reset a user's store to repair migrations.
- Avoid generic repository wrappers around `ModelContext` unless an actual requirement justifies them.

### Concurrency

- Keep SwiftData model instances isolated to their owning model context / actor.
- For background persistence, use independent isolated contexts or `@ModelActor` where appropriate; pass `PersistentIdentifier` or immutable `Sendable` snapshots, not live `@Model` objects, across actors.
- Do not share a `ModelContext` between concurrent actors. Respect cancellation, and do not hide isolation errors with unsafe annotations.

### Testing and dependencies

- Every new test should protect against a specific failure: a meaningful edge case, a reproduced bug, or a nontrivial business rule or calculation. Name the behavior it protects. Do not add tests automatically for every change or to increase test counts.
- Use previews and manual simulator checks for visual changes. Do not add tests that lock in padding, dimensions, colors, fonts, button labels, decorative asset proportions, or other appearance choices unless they reproduce a specific behavioral bug.
- Avoid tests that mirror the implementation, check trivial getters/setters or field mappings, retest native framework behavior, or duplicate existing coverage. Remove obsolete or redundant tests when the underlying custom logic is removed.
- Keep regression tests small and focused on the failing scenario and its observable result. Do not create custom controls, ViewModels, or helper abstractions solely to make simple UI testable.
- Unit-test pure domain rules without initializing SwiftData; make calendars, time zones and clocks injectable where behavior depends on them.
- Use in-memory `ModelContainer` instances for persistence integration tests that protect data integrity, relationship behavior, failed writes, or migrations.
- Run the tests relevant to the change and build when needed. Purely visual changes do not require new automated tests. Report what was checked and any verification limits.
- Use initializer injection for ViewModels and services; use Environment for dependencies shared through a view tree.
- Prefer concrete collaborators until a protocol has a real boundary or testing benefit; no dependency injection framework by default.

### Agent decision rule

1. Follow nearby feature conventions and preserve the existing deployment target.
2. Start with a View and Model. Add a Service for reusable business logic. Add a ViewModel only if presentation complexity warrants it.
3. Prefer feature-first folders, and create only folders and abstractions the feature needs.
4. Make the smallest targeted change; don't refactor unrelated architecture.
5. Add tests only when justified by the testing policy above. Run relevant existing checks and report anything that could not be run.

**Optimize for simple data flow, correctness, testability, and low architectural ceremony.**

<!-- Base: https://github.com/twostraws/SwiftAgents/blob/main/AGENTS.md ; project-specific architecture appended. -->
