# State Capsule

## Plan

- [x] Reconfirm branch state, current task-detail implementation, and the last proven experiments
- [x] Convert `TaskDetailMachine` into an explicit event/snapshot machine backed directly by store reads and save notifications
- [x] Update `TaskView` to read the event/snapshot machine state
- [x] Verify the people-flow regression below the UI layer
- [x] Build the demo app on this branch
- [ ] Record what this branch proves compared with the direct-`SwiftSync` and value-state experiments

## Last known state

Branch: `investigate/task-detail-event-snapshot-machine`

Verification:
- `swift test --package-path DemoCore --filter TaskFormPeopleMutationTests` passed
- `xcodebuild build-for-testing -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` passed

Known comparison points:
- direct `SwiftSync -> View` task detail path passed `DemoUITests.testEditTaskPeopleFlow`
- `TaskDetailMachine` with raw mirrored task state was the stale seam
- this branch now uses a store-backed event/snapshot `TaskDetailMachine`

## Decisions (don't revisit)

- This branch is for an event/snapshot machine experiment, not for a permanent fix.
- The event/snapshot experiment should rebuild task detail from the store on explicit events instead of forwarding `SyncModelPublisher` state live.
- Keep the current bug-solving work on dedicated experiment branches; do not dirty the base branch.
- The event/snapshot cut keeps the current `TaskView` contract (`detail`, `items`, `editableTask`) so the comparison stays about machine behavior, not view API churn.

## Files touched

- .agents/state.md
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
