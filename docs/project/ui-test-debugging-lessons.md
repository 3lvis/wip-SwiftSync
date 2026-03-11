# UI Test Debugging Lessons

## Scope

These notes came out of debugging `DemoUITests.testAssignUnassignedTask` in March 2026.

## What Actually Happened

- The user flow was real: assign an unassigned task to `Mia Patel`.
- The mutation path was correct:
  - the form updated `draft.assigneeID`
  - the exported payload contained the right `assignee_id`
  - the fake API returned the right `assignee_id`
  - local sync updated the stored `Task`
  - `ProjectDetailMachine` later observed the updated `assigneeID`
- The unstable part was not the sync path. It was the UI-test surface on the project row.

## Lessons

- Do not fix from ideas first.
  - My main failure in this pass was making behavior changes before the evidence was complete.
  - The right order is:
    1. reproduce
    2. instrument
    3. identify the first wrong state
    4. then change behavior
  - If the first wrong state is still unknown, it is too early to fix.

- Prove the data path before changing UI code.
  - For this bug, the winning sequence was: form state -> exported payload -> API response -> local store -> screen machine observation.
  - Until that path is mapped, UI changes are guesswork.

- Diagnostics must be visible in the place you are debugging from.
  - Several logging attempts were poor:
    - plain app-process stdout was not visible in the XCTest transcript in a useful way
    - a trace surfaced through live UI accessibility caused its own test instability
  - The useful version was file-backed tracing that the UI test could read and inject into assertion failures.
  - That changed the workflow from "guess what happened in the app" to "read the exact state progression in the failing test output."

- Improve the diagnostic transport, not just the log content.
  - Better log messages are not enough if the failing runner cannot see them.
  - For UI-test debugging, prefer one of:
    - assertion-attached trace output
    - a dedicated test-readable artifact
    - a narrow test-only diagnostic seam
  - Avoid diagnostics that mutate the accessibility tree unless the accessibility tree itself is what you are testing.

- Separate product bugs from accessibility-contract bugs.
  - The task-detail screen was a valid product surface.
  - The project row subtitle inside a `NavigationLink` was not a stable XCTest surface.
  - Those are different problems and should not be conflated.

- Do not over-trust SwiftUI row accessibility in `NavigationLink` cells.
  - Child `Text` identifiers can disappear.
  - Combined row accessibility can flatten descendants.
  - Synthesized button `value` can stay stale even when the backing model changed.

- Prefer reopening a detail screen over asserting a list-row subtitle.
  - For persistence flows, the stronger and more stable test is:
    1. change the value
    2. verify detail updates
    3. navigate back
    4. reopen the same record
    5. verify detail still shows the new value
  - This proves saved state across navigation without depending on fragile row accessibility.

- Keep navigation helpers simple.
  - Opening a task by visible title text was more reliable than trying to generalize around row button identifiers.
  - Use custom identifiers only where they add unique value, not by default.

- Temporary diagnostics should be removable in one pass.
  - Investigation logging was useful, but it should stay behind a narrow seam and be easy to delete once the root cause is known.

- When a test fails repeatedly, reduce the assertion surface.
  - The original test was checking both detail state and project-row subtitle state.
  - The stable version checks only:
    - detail changes from `Unassigned` to `Mia Patel`
    - navigating back does not lose the task
    - reopening the task still shows `Mia Patel`

## Final Test Principle

For UI tests, assert the most user-meaningful stable surface, not the most local surface.

In this case, the stable surface was task detail before and after reopening, not the project-list subtitle.
