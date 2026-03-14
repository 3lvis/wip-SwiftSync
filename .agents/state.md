# State Capsule

## Plan

- [x] Create branch-local state and rewrite the task editor planning doc around a compact editor with dedicated people pickers
- [x] Redesign `Demo/Demo/Features/TaskForm/TaskFormSheet.swift` into a shorter editor with summary rows and staged people picker flows
- [x] Update `Demo/DemoUITests/DemoUITests.swift` to drive the new picker UI while preserving post-save and reopen assertions
- [x] Run relevant verification and record the latest build/test state
- [x] Make seeded task authors explicit so detail chips do not usually duplicate assignees
- [x] Update any UI expectations that depended on fallback seed authors
- [x] Rebuild the demo app and record the latest state

## Last known state

`xcodebuild build -workspace SwiftSync.xcworkspace -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` passed after shortening seeded task descriptions

## Decisions (don't revisit)

- Replace inline people lists with dedicated picker flows that stage changes locally and commit on explicit confirmation to avoid accidental mutations on cancel
- Keep task editing improvements scoped to `Demo/Demo/**` and `Demo/DemoUITests/**`; no library changes are planned
- Remove the completed planning file instead of leaving stale unchecked items in `docs/planning`
- The demo seed fallback currently makes `authorID` match `assigneeID` when author is omitted, so differing roles require explicit seed authors

## Files touched

- .agents/state.md
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
- DemoBackend/Sources/DemoBackend/DemoSeedData.swift
- Demo/DemoUITests/DemoUITests.swift
- docs/planning/task-form-people-scaling.md
