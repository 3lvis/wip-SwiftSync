# State Capsule

## Plan

- [x] Create branch-local state and rewrite the task editor planning doc around a compact editor with dedicated people pickers
- [x] Redesign `Demo/Demo/Features/TaskForm/TaskFormSheet.swift` into a shorter editor with summary rows and staged people picker flows
- [x] Update `Demo/DemoUITests/DemoUITests.swift` to drive the new picker UI while preserving post-save and reopen assertions
- [x] Run relevant verification and record the latest build/test state
- [x] Make seeded task authors explicit so detail chips do not usually duplicate assignees
- [x] Update any UI expectations that depended on fallback seed authors
- [x] Rebuild the demo app and record the latest state
- [x] Remove `role` from demo backend seed data, backend payload/schema, and app `User` model
- [x] Remove or update tests and helper code that still expect user roles
- [x] Run relevant verification and record the latest state
- [x] Rename screen machine types so they match the current view names
- [x] Run relevant verification and record the latest state
- [x] Rework task form reviewer and watcher add flows into single-add SwiftUI pickers with per-row removal
- [x] Update demo UI tests to match the add-one reviewer and watcher picker flow
- [x] Rebuild the demo app and record the latest state
- [x] Rewrite stale task people UI-test coverage to match add-one menu pickers and persisted detail assertions
- [x] Rebuild the demo app and record the latest state
- [~] Fix task detail UI tests to query chip identifiers without assuming `StaticText`
- [~] Run focused UI verification with `build-for-testing` and `test-without-building`
- [x] Add a project playbook for running tests with the fastest repeatable local loop
- [x] Capture UI-test loop hardening work in a planning doc before implementing it
- [x] Implement the first proven UI-test loop hardening steps: explicit simulator target, shared derived data, and scripted execution
- [x] Rebuild the demo app and record the latest state

## Last known state

Focused UI loop is stabilized enough to expose real test failures: `testProjectAndTaskDetailShowSeededContent` passed through the scripted loop, `testUpdateTaskTitleKeepsProjectAndDetailInSync` failed on a real text-replacement bug and then passed after the helper fix, and `xcodebuild build -workspace SwiftSync.xcworkspace -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` now passes

## Decisions (don't revisit)

- Replace inline people lists with dedicated picker flows that stage changes locally and commit on explicit confirmation to avoid accidental mutations on cancel
- Keep task editing improvements scoped to `Demo/Demo/**` and `Demo/DemoUITests/**`; no library changes are planned
- Remove the completed planning file instead of leaving stale unchecked items in `docs/planning`
- The demo seed fallback currently makes `authorID` match `assigneeID` when author is omitted, so differing roles require explicit seed authors
- User `role` is demo metadata only; it is not part of the current task UI contract
- Reviewer and watcher adding now uses one-at-a-time menu-style `Picker` selection from the remaining available users; removal stays on the form rows
- Task detail person chips should be asserted by accessibility identifier across any element type because XCTest surfaces them inconsistently
- UI test destination names must match installed simulators on the current machine; `iPhone 16` is not available here
- Focused UI runs should disable parallel testing locally to avoid Xcode clone devices obscuring runner-launch failures

## Files touched

- .agents/state.md
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
- DemoBackend/Sources/DemoBackend/DemoSeedData.swift
- DemoBackend/Sources/DemoBackend/DemoServerSimulator.swift
- DemoCore/Sources/DemoCore/Models/DemoModels.swift
- Demo/DemoUITests/DemoUITests.swift
- docs/planning/task-form-people-scaling.md
- docs/project/test-running-playbook.md
- docs/planning/ui-test-loop-hardening.md
- scripts/run_ui_test.sh
