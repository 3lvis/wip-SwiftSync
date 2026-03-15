# State Capsule

## Plan

- [x] Extend `testCreateTaskInsideProject` to persist reviewers and watchers
- [x] Convert task author selection to a menu picker matching assignee
- [x] Remove the UI reorder test and test-only reorder hook from `TaskFormSheet`
- [x] Run the required demo app build verification
- [x] Remove UI-test roadmap stubs and document the capped Demo UI suite
- [x] Update state with final verification results

## Last known state

Demo UI suite capped and cleaned up; create-with-relationships coverage remains; Demo app build succeeded

## Decisions (don't revisit)

- Keep create-cancel and edit-cancel as separate tests because they guard distinct persistence failures.
- Use the top-sorted task invariant for post-create verification instead of searching for the created title from an arbitrary scroll position.

## Files touched

- .agents/state.md
- Demo/DemoUITests/DemoUITests.swift
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
- docs/project/test-running-playbook.md
