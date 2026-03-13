# State Capsule

## Plan

- [x] Restore the direct `SwiftSync -> View` task-detail experiment onto this fresh branch
- [x] Build the demo app on this branch
- [x] Summarize exactly what this branch contains and how it differs from the machine-based variants

## Last known state

Branch: `investigate/task-detail-direct-view`

Current branch state:
- branched from `investigate/task-people-ui-surface`
- `TaskView` now owns `SyncModelPublisher<Task>`, `SyncQueryPublisher<Item>`, and `ScreenLoadMachine` directly
- the task-detail screen no longer depends on `TaskDetailMachine` or `TaskDetailViewState`
- `xcodebuild build-for-testing -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` passed
- `xcodebuild test -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.2' -only-testing:DemoUITests/testEditTaskPeopleFlow CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` passed

## Decisions (don't revisit)

- This branch is only for restoring the direct-view experiment for review.
- Keep the experiment narrow to `TaskView`; do not redesign the rest of the app here.

## Files touched

- .agents/state.md
- Demo/Demo/Features/TaskDetail/TaskView.swift
