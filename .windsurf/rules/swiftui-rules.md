---
description: SwiftUI Development Rules for Swift Student Challenge 2026 - Ritual Mind App Playground
---

# SwiftUI Development Rules - Swift Student Challenge 2026

## Architecture

- Use structs for all views, keep them small and focused
- Use `@Observable` macro for shared state (NOT the old `@ObservableObject`)
- Use `@State` for simple view-local state
- Use `@Binding` to pass mutable state to child views
- Use `@Environment` for system-level values
- Use `task {}` instead of `.onAppear` for async work

## UI Patterns

- Use SF Symbols (`systemName:`) instead of custom images where possible
- Use system colors (`primary`, `secondary`) for automatic Dark Mode support
- Use `.font(.title)`, `.font(.body)` etc. for automatic Dynamic Type support
- Create custom `ViewModifier`s for reusable styling
- Use `LazyVStack` / `LazyHStack` for large collections

## Accessibility (REQUIRED - judges check this)

- Add `accessibilityLabel()` to ALL `Image` and icon-only `Button` views
- Add `accessibilityHint()` for non-obvious interactions
- Use `accessibilityElement(children: .combine)` to group related elements
- Never convey information through color alone
- Ensure touch targets are at least 44pt

## Constraints (Swift Student Challenge - non-negotiable)

- **NO network calls** - everything must work offline
- No tracking or analytics code
- Total `.swiftpm` ZIP must be < 25 MB
- Use vector graphics and SF Symbols to save space
- Compress any audio assets
- All content must be in English
- This is an App Playground (`.swiftpm`), not an Xcode project
