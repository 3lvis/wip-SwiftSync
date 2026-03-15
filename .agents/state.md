# State Capsule

## Plan

- [x] Remove confirmed unused task-form helpers and unused description patch API path
- [x] Run relevant tests and Demo build after the removals

## Last known state

Unused task-form helpers and the unused description patch API path were removed. `swift test --filter DemoBackendTests` in `DemoBackend`, `swift test --filter TaskFormDescriptionNormalizationTests` in `DemoCore`, and the Demo build all passed.

## Decisions (don't revisit)

- Target contract is optional description: `nil`/`null` means cleared, and fallback copy stays presentation-only in the detail UI.
- `patchTaskDescription` is not part of the active app flow; with no callers outside one backend test, remove it instead of preserving dead API surface.

## Files touched

- .agents/state.md
- Demo/Demo/Features/TaskDetail/TaskView.swift
- Demo/Demo/Features/TaskForm/TaskFormSheet.swift
- Demo/DemoUITests/DemoUITests.swift
- DemoBackend/Sources/DemoBackend/DemoServerSimulator.swift
- DemoBackend/Sources/DemoBackend/DemoSeedData.swift
- DemoBackend/Tests/DemoBackendTests/DemoBackendTests.swift
- DemoCore/Sources/DemoCore/Features/ScreenMachines.swift
- DemoCore/Sources/DemoCore/Models/DemoModels.swift
- DemoCore/Sources/DemoCore/Networking/DemoAPI.swift
- DemoCore/Tests/DemoCoreTests/TaskFormDescriptionNormalizationTests.swift
