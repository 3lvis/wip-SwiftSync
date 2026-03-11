# Bug-Solving Playbook

This document describes how to work when a real bug appears and the right fix is not yet obvious.

The goal is to make bug work:

- evidence-driven
- branch-safe
- collaborative
- test-guided
- clean at merge time

## Core stance

- Start from observed behavior, not theories.
- Do not fix from instinct.
- Find the first wrong state before changing code.
- Prefer the deepest correct fix, but earn that conclusion with evidence.
- Keep the final diff cleaner than the investigation.

## 1. Reproduce the real bug first

Before discussing causes or fixes:

- reproduce the user-visible failure
- describe the exact flow
- identify the expected result
- identify the actual result

Write the bug in terms of behavior, not implementation.

Good:

- “Saving an edit leaves the detail screen stale.”

Weak:

- “The publisher is probably broken.”

## 2. Freeze the urge to patch

When the bug is fresh, the first proposed fix is often just a guess.

Do not immediately:

- add reloads
- add sleeps or waits
- add retries
- weaken assertions
- move code until the symptom disappears

Instead ask:

- what state should have changed?
- which layer owns that state?
- how would we prove where it stopped changing?

## 3. Trace the state transition end to end

For any nontrivial bug, identify the full path the value takes.

Typical path:

- user input
- draft or transient state
- exported payload
- domain/service mutation
- backend response
- local persistence
- reactive publishers
- machine/view model state
- final UI

The objective is simple:

- find the first place where reality diverges from expectation

If the value is correct all the way down and only the UI is stale, that is a different bug from a bad payload or a failed write.

## 4. Make logs useful to the failing run

Logging only helps if the failing execution path can actually surface it.

Choose a transport that the failure can expose reliably.

Examples:

- test-readable files
- assertion-attached diagnostic output
- structured trace buffers

Be cautious with:

- stdout that never reaches the failing report
- logging through the UI tree in ways that alter accessibility or idling

Rule:

- diagnostics must be consumable by the failing test or run, not just emitted somewhere
- improving diagnostic transport is often more important than improving log wording

## 5. Use the best execution environment available

Not every failure is best investigated the same way.

Sometimes:

- CLI tests are fastest

Sometimes:

- Xcode gives better UI or simulator signal

Sometimes:

- the user can run the exact failing flow more reliably and return the relevant logs

This is normal.

Use cooperation deliberately:

- instrument narrowly
- run one focused scenario
- collect the result
- update the hypothesis

Do not treat manual collaboration as failure. Treat it as part of the debugging loop.

## 6. Try to isolate the bug into the narrowest plausible layer

After reproducing the bug, ask:

- can this be captured in a unit test?
- can it be captured in a service or machine test?
- does it only exist in a view lifecycle or integration seam?

Then try the narrowest plausible layer first.

Important:

- a passing isolation attempt is useful
- a failing isolation attempt is also useful

A non-reproducing lower-level test narrows the search space. That is progress, not wasted effort.

## 7. Separate product bugs from test-surface bugs

Not every failure in a test means the product layer is wrong.

Sometimes the product is correct, but the test surface is unstable:

- a brittle accessibility contract
- an incidental view-tree structure
- a framework-generated wrapper element
- an assertion against a surface users do not actually depend on

Treat these as different problems:

- product bug: the user-visible state is wrong
- test-surface bug: the test is reading the wrong or unstable surface

Do not change production behavior to compensate for a weak or incidental test surface unless that surface is itself part of the product contract.

## 8. Keep investigation branches separate from clean fix branches

Bug work often needs messy experiments:

- temporary logging
- probe assertions
- speculative test scaffolding
- discarded ideas

Do that on an investigation branch.

Then, once the likely cause is known:

1. return to the clean base branch
2. create a fresh branch
3. rebuild only the proven fix

This prevents the final branch from becoming a scrapbook of the whole investigation.

## 9. Treat the first working fix as provisional

A first working fix is valuable because it:

- restores correct behavior
- stabilizes the user journey
- proves the symptom can be corrected

But after it works, ask:

- should this fix live here?
- or is this layer compensating for a deeper defect?

This is the point where discipline matters most.

Do not confuse:

- “the symptom is gone”

with:

- “the right layer was fixed”

## 10. Use spy tests when the value is correct but dependents stay stale

Some bugs are not about wrong data. They are about correct data not propagating.

That is when spy tests are valuable.

A good spy test records:

- the underlying value
- the notification or observation path
- the sequence of transitions over time

This helps distinguish:

- state mutation succeeded
- observation delivery failed

from:

- state itself never changed

## 11. Prefer evidence about mechanism, not just outcome

A good bug fix explanation should answer:

- what failed?
- why did it fail?
- why does this fix address that mechanism?

Not just:

- what code changed?

For example, “the field updated” is not enough. It is stronger to know whether:

- the publisher never reloaded
- the publisher reloaded but did not notify dependents
- the view model updated but the view stayed stale
- the UI query was brittle even though the product state was correct

## 12. Reduce assertion surface when the test is noisy

When a test is failing across several surfaces at once, reduce the number of things it is trying to prove.

Do this to restore signal:

- keep the most user-meaningful assertion
- remove fragile secondary assertions
- prove the core behavior first
- re-expand the test only when the extra surface is stable and worth protecting

This is not about weakening coverage permanently. It is about regaining a clear failure signal while the bug is being localized.

## 13. Keep UI tests focused on stable user contracts

When UI tests are involved, assert the behavior the user actually depends on.

Prefer:

- open item
- perform action
- navigate away
- reopen
- confirm the result persisted

Avoid depending on fragile surfaces unless they are the product contract:

- incidental accessibility tree structure
- nested text nodes inside composite rows
- timing-sensitive transient states

A UI test should prove the user journey, not the current implementation of the view tree.

## 14. Let the final fix remove the workaround when possible

If an early workaround was needed during investigation, ask whether the deeper fix makes it unnecessary.

The ideal end state is:

- user flow passes
- lower layer is correct
- workaround is gone
- lower-layer test proves the root cause
- UI test still proves the user journey

That is much stronger than leaving the workaround in place and calling it done.

## 15. Make temporary diagnostics removable in one pass

Investigation code is often necessary:

- extra logging
- trace capture
- temporary assertions
- probe hooks

But it should be designed for removal:

- put it behind a narrow seam
- keep it local to the investigation target
- avoid spreading it through unrelated layers

If cleanup is painful, the diagnostics were too entangled with production behavior.

## 16. Merge the clean solution, not the whole investigation

Before merging:

- keep the tests that prove the cause and the behavior
- remove temporary diagnostics
- remove abandoned assertions
- remove superseded workaround code if the deeper fix replaces it
- re-run focused verification on the clean branch

The merged branch should look intentional.

Anyone reading it later should see:

- the problem
- the right fix
- the proof

They should not have to sort through every failed idea explored on the way there.

## Practical workflow

1. Reproduce the bug in the real flow.
2. Describe expected vs actual behavior.
3. Map the state path across layers.
4. Add diagnostics that the failing run can actually expose.
5. Run one focused scenario at a time.
6. Try to isolate the failure into the narrowest plausible layer.
7. Treat negative-result tests as evidence.
8. Separate product bugs from test-surface bugs.
9. Use an investigation branch for messy work.
10. Once the likely cause is known, branch cleanly from base.
11. Rebuild only the proven fix.
12. Ask whether the fix belongs deeper.
13. Reduce assertion surface if the test is noisy.
14. Add or keep the tests that prove both behavior and mechanism.
15. Remove temporary investigation residue.
16. Merge the clean, verified solution.

## What this playbook is trying to prevent

- coding from hunches
- weakening tests instead of understanding failures
- treating an unstable test surface as a product defect
- stopping at the first workaround
- merging noisy investigation history as if it were a clean fix
- confusing a UI symptom with a lower-layer root cause

## What this playbook is trying to build

- disciplined debugging
- better collaboration during bug work
- higher-quality regression tests
- cleaner branches
- deeper fixes when they are warranted
- confidence at merge time
