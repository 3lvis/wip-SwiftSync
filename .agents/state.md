# State Capsule

## Plan

- [x] Convert `descriptionText` to optional and update tests to the nil/null contract first
- [x] Update backend, model, export, and form logic to preserve nil through save and sync
- [x] Update UI rendering and UI tests for optional description semantics
- [x] Verify with targeted DemoBackend, DemoCore, UI, and Demo build checks

## Last known state

`descriptionText` is now optional end-to-end. Targeted DemoBackend null-create/null-clear tests, targeted DemoCore clear-to-nil test, `testUpdateTaskTitleKeepsProjectAndDetailInSync`, `testCreateTaskInsideProject`, and the Demo build all passed.

## Decisions (don't revisit)

- Target contract is optional description: `nil`/`null` means cleared, and fallback copy stays presentation-only in the detail UI.

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
