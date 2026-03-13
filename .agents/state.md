# State Capsule

## Plan

- [x] Add task deletion UI test coverage in `Demo/DemoUITests/DemoUITests.swift`
- [x] Add reviewer/watcher clearing UI test coverage in `Demo/DemoUITests/DemoUITests.swift`
- [x] Run relevant demo UI test verification
- [x] Update last known state with verification results

## Last known state

targeted UI verification run performed by user; `testClearTaskReviewersOrWatchers` fails because `Liam Brown` is not visible before editing

## Decisions (don't revisit)

- Prioritize destructive task deletion and relationship clearing because they exercise sync-specific behavior better than cancel flows.
- Do not add project deletion coverage because the demo does not currently expose project deletion.

## Files touched

- .agents/state.md
- Demo/DemoUITests/DemoUITests.swift
