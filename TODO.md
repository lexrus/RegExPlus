# RegEx+ SwiftUI Code Issues & Improvements TODO

## High Priority Issues ⚠️

### 1. **Deprecated NavigationViewStyle (Multiple Files)**
- **Files**: `HomeView.swift` (lines 22, 31, 39), `EditorView.swift` (line 71), `LibraryItemView.swift` (line 76), `CheatSheetView.swift` (line 85)
- **Issue**: Using deprecated `NavigationView` and `NavigationViewStyle` which are deprecated in iOS 16+
- **Fix**: Replace with `NavigationStack` for iOS 16+ and maintain backward compatibility
- **Status**: ❌ Not Fixed

### 2. **Deprecated navigationBarItems (Multiple Files)**
- **Files**: `EditorView.swift` (line 73), `CheatSheetView.swift` (line 37)
- **Issue**: `navigationBarItems` is deprecated in iOS 14+
- **Fix**: Replace with `.toolbar` and `ToolbarItem`
- **Status**: ❌ Not Fixed

### 3. **Manual ObservableObject Creation in EditorView**
- **File**: `Editor/EditorView.swift` (lines 17, 22)
- **Issue**: Creating `EditorViewModel` manually in init instead of using `@StateObject`
- **Fix**: Use `@StateObject` for proper lifecycle management
- **Status**: ❌ Not Fixed

### 4. **Memory Leaks in EditorViewModel**
- **File**: `Editor/EditorViewModel.swift` (lines 20-21)
- **Issue**: `AnyCancellable` properties not properly stored in a Set
- **Fix**: Use `Set<AnyCancellable>` for proper memory management
- **Status**: ❌ Not Fixed

## Medium Priority Issues 📋

### 5. **Inefficient State Management in SearchView**
- **File**: `Views/SearchView.swift` (lines 14, 48, 52)
- **Issue**: Unnecessary `.id(text)` modifier causing view recreations and improper focus handling
- **Fix**: Remove `.id(text)` and use proper focus state management
- **Status**: ❌ Not Fixed

### 6. **Redundant Environment Passing**
- **File**: `HomeView.swift` (lines 17, 21)
- **Issue**: Redundant `.environment(\.managedObjectContext, managedObjectContext)` calls
- **Fix**: Environment is inherited, remove redundant calls
- **Status**: ❌ Not Fixed

### 7. **Inefficient List Filtering**
- **File**: `Library/LibraryView.swift` (lines 45, 58-65)
- **Issue**: Filtering performed on every body evaluation
- **Fix**: Use computed property or move filtering logic to ViewModel
- **Status**: ❌ Not Fixed

### 8. **Platform-Specific UI Issues**
- **File**: `Library/LibraryView.swift` (lines 92-104)
- **Issue**: Hardcoded platform-specific styling that could be improved
- **Fix**: Use environment values or more SwiftUI-native approaches
- **Status**: ❌ Not Fixed

### 9. **Accessibility Issues**
- **File**: `Editor/EditorView.swift` (lines 56-66)
- **Issue**: Custom button lacks proper accessibility labels
- **Fix**: Add `.accessibilityLabel()` and `.accessibilityHint()`
- **Status**: ❌ Not Fixed

### 10. **Inefficient UITextView Integration**
- **File**: `Views/RegExTextView/RegExTextView.swift` (lines 60-62, 88-90)
- **Issue**: Multiple DispatchQueue.main.async calls causing performance issues
- **Fix**: Batch updates and reduce async calls
- **Status**: ❌ Not Fixed

### 11. **View Composition Issues**
- **File**: `Editor/EditorView.swift`
- **Issue**: Large monolithic view body (277 lines)
- **Fix**: Break down into smaller, focused view components
- **Status**: ❌ Not Fixed

## Low Priority Issues 📝

### 12. **Duplicate UITextViewWrapper**
- **Files**: `Views/RegExTextView/RegExTextView.swift` and `Views/RegExTextView/MatchesTextView.swift`
- **Issue**: Similar UITextViewWrapper implementations causing code duplication
- **Fix**: Create a common base wrapper with customization options
- **Status**: ❌ Not Fixed

### 13. **Missing @MainActor Annotations**
- **File**: `Editor/EditorViewModel.swift` (line 13)
- **Issue**: ObservableObject dealing with UI updates lacks @MainActor
- **Fix**: Add `@MainActor` to ensure main thread execution
- **Status**: ❌ Not Fixed

### 14. **Hardcoded Magic Numbers**
- **File**: `Editor/EditorView.swift` (line 246)
- **Issue**: Magic numbers like `EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 5)`
- **Fix**: Define constants or use semantic spacing
- **Status**: ❌ Not Fixed

### 15. **Force Unwrapping in LibraryView+Data**
- **File**: `Library/LibraryView+Data.swift` (line 15)
- **Issue**: Force unwrapping with `indexSet.first!`
- **Fix**: Use safe unwrapping with guard statement
- **Status**: ❌ Not Fixed

### 16. **Inconsistent Color Usage**
- **File**: `Views/RegExSyntaxView.swift` (lines 161, 172, 179, 186, 193)
- **Issue**: Hardcoded UIColors instead of semantic colors
- **Fix**: Use system semantic colors for dark mode compatibility
- **Status**: ❌ Not Fixed

### 17. **Missing Error Handling in CheatSheetView**
- **File**: `CheatSheet/CheatSheetView.swift` (lines 49-56)
- **Issue**: Error is only printed to console, no user feedback
- **Fix**: Add proper error state handling and user notification
- **Status**: ❌ Not Fixed

### 18. **Unused Properties and Methods**
- **File**: `Views/RegExTextView/MatchesTextView.swift` (lines 212-222)
- **Issue**: `SampleFooterView` is defined but never used
- **Fix**: Remove unused code or implement if intended
- **Status**: ❌ Not Fixed

### 19. **State Management Anti-patterns**
- **File**: `Library/LibraryView.swift` (line 23)
- **Issue**: Mutable `@State var editMode` should be `@State private var`
- **Fix**: Make state private where appropriate
- **Status**: ❌ Not Fixed

### 20. **Preview Data Management**
- **Files**: Multiple preview providers
- **Issue**: Preview data creation could cause memory issues in debug builds
- **Fix**: Use static computed properties for preview data
- **Status**: ❌ Not Fixed

## Action Plan Summary

### Immediate Actions (High Priority) 🚨
1. **Replace deprecated NavigationView with NavigationStack** - Critical for iOS 16+ compatibility
2. **Replace navigationBarItems with toolbar modifiers** - Deprecated API removal
3. **Fix EditorViewModel memory management** - Prevent memory leaks
4. **Use @StateObject for EditorViewModel** - Proper SwiftUI lifecycle

### Near-term Improvements (Medium Priority) 🔧
5. **Optimize list filtering performance** - Better user experience
6. **Improve platform-specific UI handling** - Better Mac Catalyst support
7. **Add accessibility support** - Improved app accessibility
8. **Optimize UITextView integration** - Performance improvements
9. **Break down large view bodies** - Better code maintainability

### Long-term Enhancements (Low Priority) ✨
10. **Consolidate duplicate code** - Code quality improvement
11. **Add proper error handling** - Better user experience
12. **Improve preview data management** - Development experience
13. **Enhance code organization** - Maintainability

---

**Total Issues Found**: 20  
**Status**: ❌ 20 Not Fixed | ✅ 0 Fixed | 🔄 0 In Progress

*Generated by Claude Code analysis on 2025-08-09*