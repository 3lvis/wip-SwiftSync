# State Capsule

## Plan

- [x] Create branch-scoped state capsule and record the 1.0 docs plan
- [x] Add repo licensing and upgrade README install/quickstart/adoption messaging
- [x] Turn docs landing page into a real entrypoint and verify the updated docs read coherently
- [x] Strengthen top-level positioning so SwiftSync's category and ideal audience are obvious without competitor comparisons

## Last known state

MIT `LICENSE` added. README now has install requirements, package URL, quick start, clearer category positioning, and license guidance. `docs/README.md` is now a real index, and the main public docs now open usage-first. `git diff --check` is clean.

## Decisions (don't revisit)

- This pass is docs/package-surface only: no library behavior changes.
- Use the GitHub remote `git@github.com:3lvis/SwiftSync.git` as the canonical package URL in install docs.

## Files touched

- .agents/state.md
