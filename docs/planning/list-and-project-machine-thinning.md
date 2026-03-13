# List And Project Machine Thinning

## Context

`TaskDetailMachine` was simplified into a thinner facade over live publishers after the stale-refresh investigation.

Two other screen machines may be candidates for the same treatment, but only if the rewrite clearly reduces code and does not weaken the screen contract:

- `ProjectsListMachine`, where `rows` currently mirrors `rowsPublisher.rows`
- `ProjectDetailMachine`, where `tasks` is an obvious mirror and `project` is derived from a broader query

The goal is not to force every machine into the same shape. The goal is to verify whether these two can become simpler in the same direction as `TaskDetailMachine` and keep the rewrite only if it is actually worth it.

## Open items
