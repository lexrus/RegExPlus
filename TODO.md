# RegEx+ SwiftUI Code Issues & Improvements TODO

## Medium Priority Issues 📋

### 1. **Inefficient State Management in SearchView**
- **File**: `Views/SearchView.swift` (lines 14, 48, 52)
- **Issue**: Unnecessary `.id(text)` modifier causing view recreations and improper focus handling
- **Fix**: Remove `.id(text)` and use proper focus state management
- **Status**: ❌ Not Fixed

### 2. **Redundant Environment Passing**
- **File**: `HomeView.swift` (lines 17, 21)
- **Issue**: Redundant `.environment(\.managedObjectContext, managedObjectContext)` calls
- **Fix**: Environment is inherited, remove redundant calls
- **Status**: ❌ Not Fixed

### 3. **Inefficient List Filtering**
- **File**: `Library/LibraryView.swift` (lines 45, 58-65)
- **Issue**: Filtering performed on every body evaluation
- **Fix**: Use computed property or move filtering logic to ViewModel
- **Status**: ❌ Not Fixed

### 4. **Platform-Specific UI Issues**
- **File**: `Library/LibraryView.swift` (lines 92-104)
- **Issue**: Hardcoded platform-specific styling that could be improved
- **Fix**: Use environment values or more SwiftUI-native approaches
- **Status**: ❌ Not Fixed

### 5. **Accessibility Issues**
- **File**: `Editor/EditorView.swift` (lines 56-66)
- **Issue**: Custom button lacks proper accessibility labels
- **Fix**: Add `.accessibilityLabel()` and `.accessibilityHint()`
- **Status**: ❌ Not Fixed

### 6. **Inefficient UITextView Integration**
- **File**: `Views/RegExTextView/RegExTextView.swift` (lines 60-62, 88-90)
- **Issue**: Multiple DispatchQueue.main.async calls causing performance issues
- **Fix**: Batch updates and reduce async calls
- **Status**: ❌ Not Fixed

### 7. **View Composition Issues**
- **File**: `Editor/EditorView.swift`
- **Issue**: Large monolithic view body (277 lines)
- **Fix**: Break down into smaller, focused view components
- **Status**: ❌ Not Fixed

## Low Priority Issues 📝

### 8. **Duplicate UITextViewWrapper**
- **Files**: `Views/RegExTextView/RegExTextView.swift` and `Views/RegExTextView/MatchesTextView.swift`
- **Issue**: Similar UITextViewWrapper implementations causing code duplication
- **Fix**: Create a common base wrapper with customization options
- **Status**: ❌ Not Fixed

### 9. **Missing @MainActor Annotations**
- **File**: `Editor/EditorViewModel.swift` (line 13)
- **Issue**: ObservableObject dealing with UI updates lacks @MainActor
- **Fix**: Add `@MainActor` to ensure main thread execution
- **Status**: ❌ Not Fixed

### 10. **Hardcoded Magic Numbers**
- **File**: `Editor/EditorView.swift` (line 246)
- **Issue**: Magic numbers like `EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 5)`
- **Fix**: Define constants or use semantic spacing
- **Status**: ❌ Not Fixed

### 11. **Force Unwrapping in LibraryView+Data**
- **File**: `Library/LibraryView+Data.swift` (line 15)
- **Issue**: Force unwrapping with `indexSet.first!`
- **Fix**: Use safe unwrapping with guard statement
- **Status**: ❌ Not Fixed

### 12. **Inconsistent Color Usage**
- **File**: `Views/RegExSyntaxView.swift` (lines 161, 172, 179, 186, 193)
- **Issue**: Hardcoded UIColors instead of semantic colors
- **Fix**: Use system semantic colors for dark mode compatibility
- **Status**: ❌ Not Fixed

### 13. **Missing Error Handling in CheatSheetView**
- **File**: `CheatSheet/CheatSheetView.swift` (lines 49-56)
- **Issue**: Error is only printed to console, no user feedback
- **Fix**: Add proper error state handling and user notification
- **Status**: ❌ Not Fixed

### 14. **Unused Properties and Methods**
- **File**: `Views/RegExTextView/MatchesTextView.swift` (lines 212-222)
- **Issue**: `SampleFooterView` is defined but never used
- **Fix**: Remove unused code or implement if intended
- **Status**: ❌ Not Fixed

### 15. **State Management Anti-patterns**
- **File**: `Library/LibraryView.swift` (line 23)
- **Issue**: Mutable `@State var editMode` should be `@State private var`
- **Fix**: Make state private where appropriate
- **Status**: ❌ Not Fixed

### 16. **Preview Data Management**
- **Files**: Multiple preview providers
- **Issue**: Preview data creation could cause memory issues in debug builds
- **Fix**: Use static computed properties for preview data
- **Status**: ❌ Not Fixed

## Action Plan Summary

### Near-term Improvements (Medium Priority) 🔧
1. **Optimize list filtering performance** - Better user experience
2. **Improve platform-specific UI handling** - Better Mac Catalyst support
3. **Add accessibility support** - Improved app accessibility
4. **Optimize UITextView integration** - Performance improvements
5. **Break down large view bodies** - Better code maintainability

### Long-term Enhancements (Low Priority) ✨
6. **Consolidate duplicate code** - Code quality improvement
7. **Add proper error handling** - Better user experience
8. **Improve preview data management** - Development experience
9. **Enhance code organization** - Maintainability

---

**Total Issues Found**: 16  
**Status**: ❌ 16 Not Fixed | ✅ 4 Fixed (Removed) | 🔄 0 In Progress

*Generated by Claude Code analysis on 2025-08-09*