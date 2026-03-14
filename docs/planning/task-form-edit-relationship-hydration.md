# Task Form Edit Relationship Hydration

The task edit sheet opens the task in an isolated `ModelContext`. Existing reviewer and watcher rows were missing from the edit draft even though the task detail screen showed them correctly. The immediate app-level fix explicitly hydrated those relationships into the isolated draft before editing.

## Open items

- [ ] Reproduce the missing reviewer and watcher rows in a focused lower-layer test without the UI.
- [ ] Identify whether isolated-context relationship hydration should happen in SwiftData usage, in DemoCore machinery, or in SwiftSync library behavior.
- [ ] Define the expected contract for relationship availability when a model is fetched into an isolated edit context.
- [ ] Add the narrowest regression coverage that proves existing to-many relationships are editable immediately after opening a task form.
- [ ] Decide whether the app-level hydration workaround should remain or be replaced by a deeper fix once the owning layer is proven.
