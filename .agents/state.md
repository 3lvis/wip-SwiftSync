# State Capsule

## Open items

- [x] Investigate why `testClearTaskReviewersOrWatchers` assumes `Liam Brown` is visible before editing
- [x] Adjust the UI test to assert the correct preconditions for reviewer and watcher clearing
- [x] Re-run the targeted UI test verification
- [x] Update the state capsule with the verification result

## Last known state

user reran `testClearTaskReviewersOrWatchers`; test passed after waiting for sheet dismissal and verifying only after reopening

## Decisions (don't revisit)

- Prioritize destructive task deletion and relationship clearing because they exercise sync-specific behavior better than cancel flows.
- Do not add project deletion coverage because the demo does not currently expose project deletion.

## Files touched

- .agents/state.md
- Demo/DemoUITests/DemoUITests.swift
