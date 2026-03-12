# State Capsule

## Plan

- [x] Move the new `testEditTaskPeopleFlow` bug investigation off the base branch onto a dedicated branch
- [x] Prove the failing seam with focused tests below the UI layer — save path is correct and `SyncModelPublisher` to-many observation is correct
- [x] Revert the provisional `DemoCore` workaround so the investigation stays honest
- [~] Investigate the real failing seam from the UI test with targeted logging
- [ ] Reproduce `testEditTaskPeopleFlow` with test-readable diagnostics
- [ ] Identify the first wrong state in the real UI flow
- [ ] Implement the minimal fix in the proven layer
- [ ] Re-run focused tests, the relevant demo app build, and the UI journey contract

## Last known state

Branch: `investigate/task-people-ui-surface`

Focused tests:
- `swift test --package-path DemoCore --filter TaskFormPeopleMutationTests`
- `swift test --package-path SwiftSync --filter SyncModelPublisherTests`
- result: passing

Known source bug:
- `DemoUITests.testEditTaskPeopleFlow`
- failure surface: `XCTAssertFalse(app.staticTexts["Noah Kim"].exists)`

## Decisions (don't revisit)

- This bug must be investigated on a dedicated branch, not on `plan/demo-ui-integration-automation`.
- The first question is whether the save path is wrong or whether the real UI flow is stale or asserting the wrong surface.
- The save path is already proven correct by `TaskFormPeopleMutationTests/testEditTaskPeopleFlowReplacesReviewersAndWatchers`.
- `SyncModelPublisher` already proves the same-identity to-many transition correctly, so the next step is UI-test-driven logging, not a deeper library fix.
- Do not keep the provisional `TaskDetailMachine.withMutation` workaround; it is reverted.

## Files touched

- .agents/state.md
- AGENTS.md
- Demo/DemoUITests/DemoUITests.swift
- DemoCore/Tests/DemoCoreTests/TaskFormPeopleMutationTests.swift
- SwiftSync/Tests/SwiftSyncTests/SyncModelPublisherTests.swift
- docs/project/bug-solving-playbook.md
