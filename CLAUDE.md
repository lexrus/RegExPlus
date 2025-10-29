# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

- **Build project**: Use Xcode GUI or `xcodebuild -project RegEx+.xcodeproj -scheme RegEx+ build`
- **Run SwiftLint**: Automatically runs during build via build phase, or manually with `swiftlint` (requires installation via Homebrew)
- **Localization conversion**: `mise run sc2tc` (converts Simplified Chinese to Traditional Chinese using OpenCC)

## Architecture Overview

RegEx+ is a SwiftUI-based Regular Expression tool that supports both iOS and macOS via Mac Catalyst. The app uses Core Data with CloudKit for data persistence and synchronization.

### Core Architecture Components

- **SwiftUI App Structure**: Uses scene-based architecture with `AppDelegate.swift` and `SceneDelegate.swift`
- **Navigation**: Master-detail navigation with `HomeView` as root, `LibraryView` as master, and `EditorView` as detail
- **Data Layer**: Core Data + CloudKit integration via `NSPersistentCloudKitContainer` for automatic sync
- **Custom Text Editing**: Specialized `RegExTextView` with syntax highlighting and live matching

### Key Modules

1. **CoreData+CloudKit**: Data persistence and cloud sync
   - `DataManager.swift`: Singleton managing Core Data stack and CloudKit integration
   - `RegEx.swift`: Core Data model for regex entries
   - `RegExFetch.swift`: Fetch request definitions

2. **Editor**: Main regex editing interface
   - `EditorView.swift`: SwiftUI view for regex editing
   - `EditorViewModel.swift`: Business logic and state management

3. **Library**: Regex collection management
   - `LibraryView.swift`: Master list of saved regexes
   - `LibraryItemView.swift`: Individual regex list items
   - `LibraryView+Data.swift`: Data manipulation extensions

4. **Views/RegExTextView**: Custom text editing components
   - `RegExTextView.swift`: UIKit-based text editor wrapper
   - `RegExSyntaxHighlighter.swift`: Syntax highlighting engine
   - `MatchesTextView.swift`: Display matching results
   - `String+NSRange.swift`: String range utilities

5. **CheatSheet**: Reference documentation
   - Localized plist files for regex syntax reference

### Platform Support

- **Multi-platform**: iOS, iPadOS, and macOS (Mac Catalyst)
- **Navigation adaptivity**: Automatically switches between single/double column navigation based on device
- **Internationalization**: English, Simplified Chinese, Traditional Chinese
- **CloudKit**: Automatic data sync across devices

### Data Model

The app stores regex patterns with metadata in Core Data, automatically synced via CloudKit:
- Name, pattern, test string, flags
- Creation/modification dates
- CloudKit integration for cross-device sync

### Development Notes

- Uses `#if targetEnvironment(macCatalyst)` for platform-specific code
- SwiftLint integration via build phase
- Traditional Chinese localization generated from Simplified Chinese via OpenCC
- Custom UIKit text view integration within SwiftUI for advanced text editing features