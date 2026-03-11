# State Capsule

## Plan

- [x] Stabilize the canonical UI journeys added in `DemoUITests`
- [x] Debug the `testAssignUnassignedTask` failure through logs before changing behavior
- [x] Keep only the minimal app and test changes that fix the real regression surface
- [x] Add focused regression coverage for the assignee path and document the debugging lessons
- [x] Re-run focused verification and prepare the branch for commit and merge

## Last known state

Focused verification is green:
- `swift test --package-path DemoCore --filter AssigneeMutationRegressionTests`
- `xcodebuild build-for-testing -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''`
- `DemoUITests.testAssignUnassignedTask` passes in Xcode with the stable reopen-detail assertion strategy

## Decisions (don't revisit)

- Do not fix UI-test failures from hunches first; instrument the path and find the first wrong state before changing behavior.
- For this regression, stdout and accessibility-surface tracing were poor diagnostics; file-backed trace attached to test failures was the useful transport.
- The durable user journey is: assign in task detail, confirm detail updates, navigate back, reopen the same task, confirm the new assignee persists.
- Do not assert the project-row assignee subtitle for this flow; SwiftUI `NavigationLink` row accessibility is not a stable UI-test contract.

## Files touched

- .agents/state.md
- Demo/Demo/App/ContentView.swift
- Demo/Demo/Features/Projects/ProjectView.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
- Demo/DemoUITests/DemoUITests.swift
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
- DemoCore/Tests/DemoCoreTests/AssigneeMutationRegressionTests.swift
- docs/project/ui-test-debugging-lessons.md
