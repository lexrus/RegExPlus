# Repository Guidelines

## Project Structure & Module Organization
`RegEx+/` hosts the SwiftUI app: `HomeView.swift` drives navigation, `Views/`, `Editor/`, and `Library/` contain feature areas, and `CheatSheet/` holds localized regex tips backed by `RegEx.xcdatamodeld`. Assets and previews live in `Assets.xcassets` and `Preview Content/`. Localizations reside in per-language `.lproj` folders alongside `Localizable.xcstrings`. Use the Xcode project at `RegEx+.xcodeproj`; the `Build/` directory is derived output and should stay untracked. `fastlane/` stores App Store metadata flows, and `mise.toml` defines repeatable automation tasks.

## Build, Test, and Development Commands
- `open RegEx+.xcodeproj` — launch the workspace in Xcode for iterative SwiftUI development.
- `xcodebuild -scheme "RegEx+" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build` — verify the iOS target from the command line.
- `xcodebuild test -scheme "RegEx+" -destination 'platform=macOS'` — run XCTest targets (create or enable them before CI).
- `mise run sc2tc` — refresh Traditional Chinese cheat-sheet resources via OpenCC.
- `mise run pull-metadata` / `mise run push-metadata` — sync App Store metadata with Fastlane.

## Coding Style & Naming Conventions
Follow idiomatic Swift 5.9: four-space indentation, `UpperCamelCase` for types and `lowerCamelCase` for functions, properties, and Core Data entities. Prefer SwiftUI modifiers over imperative UIKit. Strings must be localized by adding keys to `Localizable.xcstrings` and the matching `.lproj` plist. SwiftLint runs as an Xcode build phase; ensure `swiftlint` is installed (e.g., `brew install swiftlint`) before pushing.

## Testing Guidelines
Author tests with XCTest and snapshot SwiftUI previews where appropriate. Group specs by feature (e.g., `LibraryViewTests.swift`) and name methods `test_<scenario>_<expected>()`. Run `xcodebuild test` against both Catalyst and iOS destinations when the change affects shared logic. Aim to cover regex evaluation, Core Data persistence, and localization fallbacks; flag gaps in PRs if coverage is impractical.

## Commit & Pull Request Guidelines
Git history follows conventional prefixes (`feat:`, `fix:`, `chore:`). Keep subject lines under 72 characters and describe what changed and why. For pull requests, include a concise summary, affected platforms, and simulator or macOS screenshots when UI shifts. Link related issues, note localization or metadata follow-up steps, and confirm that SwiftLint and targeted builds/tests succeed locally. Avoid committing Fastlane API keys or other secrets under `fastlane/keys/`; use mocked or encrypted references instead.
