# State Capsule

## Plan

- [x] Branch from `plan/demo-ui-integration-automation` into a fresh investigation branch
- [x] Add instrumentation or spy-style tests to prove whether `SyncModelPublisher<Task>` emits during the real edit-save-dismiss flow
- [x] Determine whether the gap is publisher delivery, relationship hydration timing, or SwiftUI lifecycle timing
- [x] Decide whether the right permanent fix belongs in observation, model publishing, or the view layer

## Last known state

Branch: `investigate/task-detail-publisher-refresh`

Reference minimal-fix commit on sibling branch:
- `047c289` `Fix assignee detail refresh after edit dismiss`

Known question:
- `TaskDetailMachine` should ideally refresh from `SyncModelPublisher<Task>` without an explicit `.onChange(showingEditSheet)` reload in `TaskView`

Current failing investigation test:
- `swift test --package-path SwiftSync --filter SyncModelPublisherTests`

Observed result:
- `SyncModelPublisher.row` reaches the correct final assigned task state
- observation tracking over `publisher.row` does not receive the update
- spy values remain `[(nil, nil)]`
- this points away from relationship hydration and toward observation delivery on `SyncModelPublisher`

Current fix and verification:
- `SyncModelPublisher.reload()` now uses `withMutation(keyPath: \.row) { _row = fetchedRow }`
- reason: `@Observable` only auto-notifies object-typed properties on identity change; SwiftData was returning the same model instance with mutated fields
- `swift test --package-path SwiftSync --filter SyncModelPublisherTests` now passes
- `xcodebuild test -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,id=A40EFA3C-8E6A-40B2-9FF1-C4C1944B3CC7' -only-testing:DemoUITests/DemoUITests/testAssignUnassignedTask CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` now passes without the `TaskView` sheet-dismiss workaround

## Decisions (don't revisit)

- Investigate this from the clean base branch, not on top of the minimal fix.
- The first goal is evidence: prove what `SyncModelPublisher<Task>` does in the real save path before proposing another architectural change.
- The right target is the real edit-save-dismiss seam, not generic sync or machine tests that already pass.
- The first concrete evidence is now at the `SwiftSync` layer: the model publisher mutates correctly but does not notify observation dependents.
- Root cause: `SyncModelPublisher.row = fetchedRow` does not notify observers when `fetchedRow` is the same model instance, even if that instance's fields changed in place.
- Conclusion: the publisher-layer fix removes the need for the `TaskView` workaround in the real assignee UI flow.

## Files touched

- .agents/state.md
- Demo/DemoUITests/DemoUITests.swift
- SwiftSync/Sources/SwiftSync/SyncModelPublisher.swift
- SwiftSync/Tests/SwiftSyncTests/SyncModelPublisherTests.swift
