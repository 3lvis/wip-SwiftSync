# State Capsule

## Plan
- [x] Add failing tests for the macro-only sync contract and removal of `SyncUpdatableModel` references.
- [~] Replace `SyncUpdatableModel` protocol usage with a single `SyncModelable` runtime contract.
- [ ] Make `SyncPayload` internal and route sync mapping through generated underscore runtime methods.
- [ ] Update macro generation and test model conformances to the new runtime method names/signatures.
- [ ] Update docs and planning notes to remove old public `make`/`apply` contract guidance.
- [ ] Run targeted and full `swift test` and record final state.

## Last known state
`swift test --filter ExportTests` fails as expected: `SyncModelable` has no `_syncExportObject` yet (`SyncExportTests.swift:208`).

## Decisions (don't revisit)
- Collapse sync model API shape to one protocol contract and hide payload reader internals.

## Files touched
- .agents/state.md
