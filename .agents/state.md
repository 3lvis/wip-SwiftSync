# State Capsule

## Open items

- [x] Audit explicit waits and helper usage in `Demo/DemoUITests/DemoUITests.swift`
- [x] Remove redundant waits and tighten timeout defaults where the UI contract is stronger
- [x] Re-run the relevant UI tests and compare behavior
- [x] Update the state capsule with verification results and any remaining wait risks

## Last known state

user reported the full UI suite passing after reintroducing only the proven waits and the people-flow scrolling fixes

## Decisions (don't revisit)

- Disable fake API delay, hide nonessential UI chrome, and prefer stable accessibility identifiers before reintroducing any waits.
- Remove explicit waits from `DemoUITests` and add back only the synchronization points proven necessary by failing tests.

## Files touched

- .agents/state.md
- Demo/DemoUITests/DemoUITests.swift
- DemoCore/Sources/DemoCore/App/DemoRuntime.swift
- DemoCore/Sources/DemoCore/Networking/DemoAPI.swift
- Demo/Demo/App/ContentView.swift
- Demo/Demo/DemoApp.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
