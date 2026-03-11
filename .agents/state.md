# State Capsule

## Plan

- [x] Add the four real journey tests for title edit, create, item edits, and people edits
- [x] Add only the accessibility hooks needed to drive those journeys reliably
- [x] Run the focused UI tests and required Demo app build, then update `.agents/state.md`
- [x] Update the `DemoUITests.swift` roadmap to remove low-value coverage and document the agreed harness work for empty/failure cases
- [x] Add the next eight canonical-seed UI journeys for delete, cancel, normalization, relationship clearing, and empty-detail coverage
- [x] Add only the additional UI hooks/helpers needed to drive those journeys reliably
- [~] Run the focused UI tests and required Demo app build for this batch, then update `.agents/state.md` — app/test builds succeeded; user-run UI execution exposed failures in unassigned-assignee and reviewer/watcher clearing journeys

## Last known state

Focused UI tests passed:
- `xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,id=E8A7A5EE-68F6-4C30-952A-B75DF308E8D3' test -only-testing:DemoUITests/DemoUITests/testCreateTaskInsideProject`
- `xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,id=E8A7A5EE-68F6-4C30-952A-B75DF308E8D3' test -only-testing:DemoUITests/DemoUITests/testUpdateTaskTitleKeepsProjectAndDetailInSync`
- `xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,id=E8A7A5EE-68F6-4C30-952A-B75DF308E8D3' test -only-testing:DemoUITests/DemoUITests/testEditTaskItemsFlow`
- `xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,id=E8A7A5EE-68F6-4C30-952A-B75DF308E8D3' test -only-testing:DemoUITests/DemoUITests/testEditTaskPeopleFlow`
- `xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -destination 'platform=iOS Simulator,id=E8A7A5EE-68F6-4C30-952A-B75DF308E8D3' build`

Verification status:
- `xcodebuild build -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` succeeded
- `xcodebuild build-for-testing -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` succeeded
- Focused `xcodebuild test` compilation succeeded
- User-run UI execution exposed two failing journeys:
  - `testAssignUnassignedTask` still observed `"Unassigned"` after save
  - `testClearTaskReviewersOrWatchers` assumed watcher text existed before scrolling it into view
- Follow-up fix applied:
  - task detail now resolves author/assignee display names from loaded users when the relationship object is stale
  - reviewer/watcher empty states now expose explicit accessibility identifiers
  - the failing UI tests now scroll for offscreen watcher content instead of assuming it is already instantiated
- Revalidation after the fix:
  - `xcodebuild build -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` succeeded
  - `xcodebuild build-for-testing -project Demo/Demo.xcodeproj -scheme Demo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=''` succeeded

## Decisions (don't revisit)

- Start with a docs-only planning pass before any implementation work because this task is explicitly to define the rollout
- Split the automation roadmap into a baseline pass first and edge cases second to match the requested delivery shape
- Use a deterministic UI-test-only runtime configuration so launch assertions do not depend on persisted local cache or ambient backend mutations
- Keep the UI test target focused on maintained end-to-end coverage, not generated launch screenshots or placeholder performance tests
- The planning doc should be anchored to the seeded canonical demo data and actual screen states, not generic CRUD wording
- Making the Demo app intentionally easy to automate is in scope, including runtime and backend reshaping for deterministic UI states
- Build harness pieces only when a concrete UI flow needs them; avoid speculative test infrastructure
- The next planning layer should be user journeys, not screen permutations
- UI tests should map to user goals, not checkpoints like "screen opened successfully"
- `DemoUITests.swift` should be the active planning source for UI automation journeys
- Targeted per-journey UI test runs are more actionable than one large run while the suite is still being stabilized
- Remove placeholder journeys that only repeat existing CRUD coverage without adding a distinct regression target
- Empty/failure UI journeys are in scope when backed by explicit UI-test runtime hooks such as alternate seeds or injected failure behavior
- The next executable batch should stay on the canonical UI-test seed and avoid new runtime plumbing
- For this batch, prefer adding test helpers over app-side hooks unless a flow is impossible to drive from existing accessibility surfaces

## Files touched

- .agents/state.md
- docs/planning/demo-ui-integration-automation.md
- DemoCore/Sources/DemoCore/App/DemoRuntime.swift
- Demo/Demo/Features/Projects/ProjectsViewController.swift
- Demo/DemoUITests/DemoUITests.swift
- Demo/DemoUITests/DemoUITestsLaunchTests.swift
- docs/planning/demo-ui-integration-automation.md
- Demo/Demo/Features/Projects/ProjectView.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
- Demo/DemoUITests/DemoUITests.swift
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
