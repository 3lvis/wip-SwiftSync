# Task Detail Machine Follow-up

## Context

This branch grew out of a UI regression in `DemoUITests.testEditTaskPeopleFlow`.

The user-visible failure was that task people edits persisted correctly, but the task-detail screen could remain stale after the edit flow. In the failing journey, a removed reviewer could still appear after save and dismiss.

The investigation established several things before changing the task-detail screen shape:

- the form save path was correct
- the backend-facing payload was correct
- the persisted local state after save was correct
- `SyncModelPublisher` had one real refresh bug, and that library bug was fixed with focused regression coverage

After that library fix, the remaining stale behavior still reproduced in the task-detail flow. That narrowed the problem to the task-detail presentation path rather than the save path itself.

## What was tried

### 1. Library-level refresh fix

`SyncModelPublisher` was fixed so relevant save notifications correctly trigger reloads. Focused tests were added to prove the observation path at the library layer.

This fixed one real bug, but it did not fully explain the remaining stale task-detail behavior.

### 2. Narrow save-path proof

Focused `DemoCore` tests proved that editing reviewers and watchers produced the expected stored task state after save.

This removed the save/export path from suspicion.

### 3. Direct `SwiftSync -> View` task detail

`TaskView` was rewritten to own `SyncModelPublisher<Task>`, `SyncQueryPublisher<Item>`, and `ScreenLoadMachine` directly, without routing detail rendering through `TaskDetailMachine`.

This version removed the stale people bug in the UI flow.

Why this mattered:

- it proved the app did not need Combine to reproduce the issue
- it proved the bug was not specific to one publisher wrapper API
- it showed that removing the `TaskDetailMachine` boundary removed the stale behavior

### 4. Alternate machine shapes

Several replacement machine experiments were tried after the direct-view result:

- event/snapshot machine
- hybrid machine
- Combine comparison

The important conclusion was not that one of these experiments was the final solution. The important conclusion was that the old machine shape was the suspicious seam, and both Observation-based and Combine-based machine-style experiments could exhibit the same stale behavior pattern.

## Why `TaskDetailMachine` was removed

`TaskDetailMachine` was removed temporarily to answer one question cleanly:

- is the bug in the underlying synced state, or is it introduced by the machine boundary?

The direct-view experiment answered that question. The synced state path was good enough for the UI test to pass once the machine boundary was removed.

That means the next step is not to keep the screen machine removed forever by assumption. The next step is to rebuild `TaskDetailMachine` in a way that preserves the benefits of a screen machine without reintroducing the stale observation behavior.

## Constraints for the next machine

The next `TaskDetailMachine` should:

- not rely on a retained-object observation pattern that can go stale across same-identity updates
- not assume Combine will avoid the bug, because the investigation already showed the same class of problem there too
- keep load/error/edit orchestration responsibilities clear
- avoid unnecessary view-state boilerplate unless it protects a real contract
- preserve the task-detail UI regression as the end-to-end proof

## Open items

- [ ] Define the intended long-term contract for `TaskDetailMachine`: orchestration only, derived screen state, or direct publisher ownership behind a thin facade
- [ ] Pick one replacement observation strategy that does not depend on the stale machine pattern proven by the old implementation
- [ ] Rebuild `TaskDetailMachine` from the clean direct-view baseline instead of trimming one of the exploratory machine branches
- [ ] Add focused tests that prove the new machine refreshes correctly after same-identity people edits
- [ ] Re-run `DemoUITests.testEditTaskPeopleFlow` against the rebuilt machine and keep it as the user-facing regression proof
- [ ] Update `docs/project/reactive-reads.md` once the final machine shape is chosen so the guidance matches the shipped pattern
