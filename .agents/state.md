# State Capsule

## Plan

- [x] Extend `testCreateTaskInsideProject` to persist reviewers and watchers
- [x] Add a dedicated UI test for item reorder persistence across reread
- [x] Convert task author selection to a menu picker matching assignee
- [x] Run targeted UI verification for the updated create, reorder, and author-picker coverage
- [x] Run the required demo app build verification
- [x] Update state with final verification results

## Last known state

targeted UI tests passed for create-with-relationships and item reorder persistence; Demo app build succeeded

## Decisions (don't revisit)

- Keep create-cancel and edit-cancel as separate tests because they guard distinct persistence failures.
- Keep item reorder persistence as a dedicated test instead of folding it into the broader item edit flow.
- Use the top-sorted task invariant for post-create verification instead of searching for the created title from an arbitrary scroll position.

## Files touched

- .agents/state.md
- Demo/DemoUITests/DemoUITests.swift
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
