# State Capsule

## Plan

- [x] Measure the current `ProjectsListMachine` and `ProjectDetailMachine` shapes against the `TaskDetailMachine` facade pattern and identify which stored properties are only mirroring publisher state
- [x] Prototype a thinner `ProjectsListMachine` that exposes live computed reads from `rowsPublisher` and keep it only if the code gets smaller or clearer
- [x] Prototype a thinner `ProjectDetailMachine` that exposes live computed reads for `tasks` and reevaluate whether `project` becomes simpler or more awkward
- [x] Compare before-and-after code size and readability for both machines and drop any rewrite that is neutral or worse
- [x] Add or update focused tests only if a kept rewrite changes observation behavior or machine contract

## Last known state

`DemoCore` test suite passed after keeping both machine-thinning rewrites

## Decisions (don't revisit)

- Only keep machine-thinning rewrites that clearly reduce code or improve clarity; drop any rewrite that is neutral or worse
- Keep both simplifications: they remove mirrored publisher state and reduce code without making the machine contracts more awkward

## Files touched

- .agents/state.md
- docs/planning/list-and-project-machine-thinning.md
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
