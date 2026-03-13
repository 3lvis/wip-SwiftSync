# Task Form People Scaling

## Open items

- [ ] Replace inline `Assignee`, `Reviewers`, and `Watchers` lists in `Demo/Demo/Features/TaskForm/TaskFormSheet.swift` with compact summary rows in the main task form
- [ ] Add a searchable single-select people picker flow for `Assignee` that supports `Unassigned`
- [ ] Add a searchable multi-select people picker flow for `Reviewers` with selected-state checkmarks and a clear action
- [ ] Add a searchable multi-select people picker flow for `Watchers` with selected-state checkmarks and a clear action
- [ ] Show selected people as a compact summary in the main task form so the form remains short with 50+ users
- [ ] Prefer a dedicated people-picker surface over inline scrolling lists so UI tests do not traverse the full task form to edit relationships
- [ ] Add stable accessibility identifiers for the people-picker surface, search field, selected rows, and commit actions
- [ ] Update `Demo/DemoUITests/DemoUITests.swift` to exercise people edits through the picker flow instead of long inline scroll paths

## Why

The current inline people editor does not scale to larger user sets. With 50 people, the main task form becomes too long to scan, relationship editing requires repeated scrolling, and UI tests spend most of their time searching and traversing the form rather than verifying the relationship behavior itself.

The target interaction model is:

- `Assignee`: searchable single-select picker
- `Reviewers`: searchable multi-select picker
- `Watchers`: searchable multi-select picker

The main task form should show summaries such as `Assignee: Mia Patel`, `Reviewers: 3 selected`, and `Watchers: 2 selected`, while the actual person selection happens in a dedicated picker surface.
