# State Capsule

## Plan

- [x] Review the active planning doc and capture the branch-scoped assumption for this task
- [x] Refine the selected planning doc into a short implementation-ready sequence
- [x] Confirm the planning doc keeps only active open items in the required format
- [x] Rework `TaskDetailMachine` into the standard publisher-owning screen-machine shape and reconnect `TaskView`
- [x] Run focused DemoCore tests for task detail refresh behavior and a demo app build for the UI layer change
- [ ] Update `docs/project/reactive-reads.md` to document the shipped task-detail observation pattern

## Last known state

focused DemoCore task-detail refresh test passed; Demo app build passed; manual `DemoUITests.testEditTaskPeopleFlow` verification passed

## Decisions (don't revisit)

- Treat `docs/planning/task-detail-machine-follow-up.md` as the active planning doc for this branch because it contains the clearest active follow-up steps and aligns with the recent repository history
- Keep the established demo screen pattern: the view owns one screen machine, and the machine owns publishers plus load orchestration while exposing live model-backed state
- `TaskDetailMachine` should remain a thin facade over live publishers instead of retaining a separate task-detail snapshot, because the retained snapshot seam was the stale-refresh risk

## Files touched

- .agents/state.md
- docs/planning/task-detail-machine-follow-up.md
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
- DemoCore/Tests/DemoCoreTests/TaskFormPeopleMutationTests.swift
- Demo/Demo/Features/TaskDetail/TaskView.swift
