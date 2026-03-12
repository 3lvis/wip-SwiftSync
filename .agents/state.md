# State Capsule

## Plan

- [x] Reconfirm the starting point of `investigate/task-detail-hybrid-machine`
- [x] Convert `TaskDetailMachine` into a hybrid machine: live `SwiftSync` publishers remain the source of truth, but the machine exposes only derived screen state
- [x] Update `TaskView` to consume the hybrid machine state
- [x] Verify the branch with the relevant demo build
- [ ] Record what this branch proves compared with the direct-`SwiftSync` and event/snapshot experiments

## Last known state

Branch: `investigate/task-detail-hybrid-machine`

Starting point:
- current `TaskDetailMachine` mirrors raw `Task` and `[Item]`
- this is the stale seam we want to replace on this branch

Reference comparison points:
- direct `SwiftSync -> View` task detail passed the people-flow UI regression
- event/snapshot machine branch passed focused verification and manual UI validation
- `swift test --package-path DemoCore` passed
- `xcodebuild build-for-testing -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` passed

## Decisions (don't revisit)

- The hybrid branch keeps `SyncModelPublisher` / `SyncQueryPublisher` live in the machine.
- The hybrid branch should remove raw mirrored model state from `TaskDetailMachine`.
- Keep the machine responsible for load/error/edit behavior while publishing only screen-facing derived state.

## Files touched

- .agents/state.md
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
