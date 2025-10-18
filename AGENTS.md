# Repository Guidelines

## Project Structure & Module Organization
- `HealthBuddy` holds the SwiftUI app. `HealthBuddyApp.swift` wires the scene phase and dependency injection. `ContentView.swift` is the launch surface and should stay focused on the core navigation flows (profiles, history, trends).
- Store reusable view components under feature-specific subgroups (e.g., `FamilyProfiles`, `HealthEvents`, `Analytics`). Assets such as profile photos belong in `Assets.xcassets`; maintain descriptive names like `member-jordan`.
- `HealthBuddyTests` mirrors production folders for logic and view-model tests. `HealthBuddyUITests` captures end-to-end caregiver journeys (new event, history review, trends).

## Build, Test, and Development Commands
- `xed .` opens the project in Xcode; prefer running simulators from within Xcode when debugging UI state.
- `xcodebuild -scheme HealthBuddy -destination 'platform=iOS Simulator,name=iPhone 15' build` ensures the app compiles for CI.
- `xcodebuild -scheme HealthBuddy -destination 'platform=iOS Simulator,name=iPhone 15' test` executes unit and UI suites; keep simulator caches warmed to avoid launch timeouts.

## Coding Style & Naming Conventions
- Use Swift API Design Guidelines (4-space indentation, `camelCase` members, `PascalCase` types). Pair views and view models (`FamilyProfileView` / `FamilyProfileViewModel`) to clarify ownership.
- Keep data models value-typed; adopt `ObservableObject` only when shared state demands it.
- Follow Apple HIG: rely on system font (San Francisco) with hierarchical sizes, blue accent for interactive controls, and consistent padding that matches existing screens.

## Testing Guidelines
- Favour XCTest with clear method names (`testLogEvent_savesTemperatureReading`). Validate persistence, sorting order, and presentation of caregiver messages.
- UI tests should cover the happy path: creating an event, editing history, inspecting trends. Reset simulator state in `setUp`/`tearDown` to maintain deterministic runs.
- Treat failing tests as merge blockers; add regression tests for any bug that touches event logging or privacy behaviour.

## UX & Accessibility Principles
- Prioritise compassion and clarity: neutral tonal language, straightforward labels, and accessible colour contrast that still honours the light-grey card aesthetic.
- Keep layouts content-first. Cards should surface the key summary (`Headache, 37.5 °C, paracetamol`) with secondary metadata lighter in weight.

## Commit & Pull Request Guidelines
- Use Conventional Commit prefixes (`feat:`, `fix:`, `refactor:`, `chore:`) with imperative summaries, e.g., `feat: record medication dosage notes`.
- Before raising a PR, confirm `xcodebuild ... test` passes. Provide a short description, link any issue, and attach simulator screenshots or recordings when UI changes the caregiver flow.
- Call out new analytics or data migrations explicitly so reviewers can double-check schema and privacy implications.
