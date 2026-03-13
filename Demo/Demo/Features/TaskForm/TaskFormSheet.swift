import SwiftData
import DemoCore
import SwiftSync
import SwiftUI

struct TaskFormSheet: View {
    let mode: TaskFormMode
    let syncContainer: SyncContainer
    let syncEngine: DemoSyncEngine

    @Environment(\.dismiss) private var dismiss

    // Throwaway context — autosave disabled. Never saved to the store.
    // On cancel it is simply released; on save we export the values and call the API.
    let editContext: ModelContext

    // The draft lives in editContext. For create it is a freshly-inserted Task.
    // For edit it is the same row fetched into this isolated context.
    // Relationship arrays (reviewers, watchers) are real [User] objects from editContext,
    // so the pickers can assign them directly without cross-context crashes.
    @State private var draft: Task

    @State private var machine: TaskFormMachine
    @State private var newItemTitle = ""
    @State private var itemEditMode: EditMode = .inactive
    @State private var activePeoplePicker: PeoplePickerRoute?

    init(mode: TaskFormMode, syncContainer: SyncContainer, syncEngine: DemoSyncEngine) {
        self.mode = mode
        self.syncContainer = syncContainer
        self.syncEngine = syncEngine

        let ctx = ModelContext(syncContainer.modelContainer)
        ctx.autosaveEnabled = false
        self.editContext = ctx
        _machine = State(
            initialValue: TaskFormMachine(syncContainer: syncContainer, syncEngine: syncEngine, editContext: ctx)
        )

        switch mode {
        case .create(let projectID):
            let task = Task(projectID: projectID)
            ctx.insert(task)
            _draft = State(initialValue: task)

        case .edit(let task):
            let taskID = task.id
            let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == taskID })
            let fetched = (try? ctx.fetch(descriptor))?.first
            // Fallback should never be reached in practice — the row is always in the store.
            // If it somehow is, we fall back to the passed object (which lives in mainContext,
            // so edits won't reach the store either, preserving the no-save guarantee).
            _draft = State(initialValue: fetched ?? task)
        }
    }

    var body: some View {
        NavigationStack {
            Form { content }
            .accessibilityIdentifier("task-form")
            .environment(\.editMode, $itemEditMode)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $activePeoplePicker) { route in
                peoplePickerDestination(for: route)
            }
        }
        .task(loadMetadata)
        .task(id: defaultsTaskID, applyDefaults)
        .animation(.snappy(duration: 0.2), value: itemIDs)
        .taskFormPresentations(
            saveFailureIsPresented: saveFailureIsPresented,
            saveFailureMessage: saveFailureMessage
        )
        .presentationDetents([.large])
    }
}

extension TaskFormSheet {
    @ViewBuilder
    var content: some View {
        loadErrorSection
        overviewSection
        descriptionSection
        peopleSection
        itemsSection
    }

    private var defaultsTaskID: String {
        "\(machine.taskStateOptions.map(\.id).joined(separator: ","))|\(machine.users.map(\.id).joined(separator: ","))"
    }

    private var itemIDs: [String] {
        machine.sortedItems(in: draft).map(\.id)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .accessibilityIdentifier("task-form.cancel")
                .disabled(machine.saveState == .submitting)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: save) {
                saveButtonLabel
            }
            .accessibilityIdentifier("task-form.save")
            .disabled(isSaveDisabled)
        }
    }

    var navigationTitle: String {
        switch mode {
        case .create: "New Task"
        case .edit: "Edit Task"
        }
    }

    var confirmLabel: String {
        switch mode {
        case .create: "Create"
        case .edit: "Save"
        }
    }

    var isSaveDisabled: Bool {
        guard machine.saveState != .submitting,
              !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return true }
        if case .create = mode {
            return draft.state.isEmpty || draft.authorID.isEmpty
        }
        return false
    }

    @ViewBuilder
    var saveButtonLabel: some View {
        HStack(spacing: 6) {
            if machine.saveState == .submitting {
                ProgressView().controlSize(.small)
            }
            Text(confirmLabel)
        }
    }

    var saveFailureIsPresented: Binding<Bool> {
        Binding(
            get: {
                if case .failed = machine.saveState { return true }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    machine.send(.dismissSaveError)
                }
            }
        )
    }

    var saveFailureMessage: String {
        if case .failed(let error) = machine.saveState {
            return error.message
        }
        return "Unknown error"
    }

    func save() {
        machine.send(.save(mode: mode, draft: draft, onSuccess: {
            dismiss()
        }))
    }

    func loadMetadata() {
        machine.send(.metadata(.onAppear))
    }

    func applyDefaults() {
        machine.applyDefaultsIfNeeded(to: draft)
    }

    func itemTitleBinding(for item: Item) -> Binding<String> {
        Binding(
            get: { item.title },
            set: { newValue in
                _ = machine.mutateItems(.updateTitle(item: item, title: newValue), in: draft)
            }
        )
    }

    @ViewBuilder
    fileprivate func peoplePickerDestination(for route: PeoplePickerRoute) -> some View {
        TaskFormPeoplePicker(
            route: route,
            users: machine.users,
            initialSelection: selection(for: route),
            onDone: { selectedIDs in
                applySelection(selectedIDs, for: route)
                activePeoplePicker = nil
            }
        )
    }

    fileprivate func selection(for route: PeoplePickerRoute) -> PeoplePickerSelection {
        switch route {
        case .assignee:
            return .single(draft.assigneeID)
        case .author:
            return .single(draft.authorID.isEmpty ? nil : draft.authorID)
        case .reviewers:
            return .multiple(Set(draft.reviewers.map(\.id)))
        case .watchers:
            return .multiple(Set(draft.watchers.map(\.id)))
        }
    }

    fileprivate func applySelection(_ selection: PeoplePickerSelection, for route: PeoplePickerRoute) {
        switch route {
        case .assignee:
            if case .single(let selectedID) = selection {
                draft.assigneeID = selectedID
            }
        case .author:
            if case .single(let selectedID) = selection {
                draft.authorID = selectedID ?? ""
            }
        case .reviewers:
            if case .multiple(let selectedIDs) = selection {
                draft.reviewers = users(matching: selectedIDs)
            }
        case .watchers:
            if case .multiple(let selectedIDs) = selection {
                draft.watchers = users(matching: selectedIDs)
            }
        }
    }

    func users(matching selectedIDs: Set<String>) -> [User] {
        machine.users.filter { selectedIDs.contains($0.id) }
    }

    func displayName(for userID: String?) -> String? {
        guard let userID else { return nil }
        return machine.users.first(where: { $0.id == userID })?.displayName
    }

    fileprivate func summaryText(for route: PeoplePickerRoute) -> String {
        switch route {
        case .assignee:
            return displayName(for: draft.assigneeID) ?? "Unassigned"
        case .author:
            return displayName(for: draft.authorID.isEmpty ? nil : draft.authorID) ?? "Choose author"
        case .reviewers:
            return peopleSummary(for: draft.reviewers)
        case .watchers:
            return peopleSummary(for: draft.watchers)
        }
    }

    func peopleSummary(for users: [User]) -> String {
        let names = users
            .map(\.displayName)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        switch names.count {
        case 0:
            return "None"
        case 1:
            return names[0]
        case 2:
            return names.joined(separator: ", ")
        default:
            return "\(names.count) selected"
        }
    }
}

private extension View {
    func taskFormPresentations(
        saveFailureIsPresented: Binding<Bool>,
        saveFailureMessage: String
    ) -> some View {
        self.alert("Save Failed", isPresented: saveFailureIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveFailureMessage)
        }
    }
}

extension TaskFormSheet {
    var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 18) {
                TextEditor(text: $draft.title)
                    .frame(minHeight: 72)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("task-form.title")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick settings")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    stateControl
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Overview")
        }
    }

    var descriptionSection: some View {
        Section("Description") {
            TextEditor(text: $draft.descriptionText)
                .frame(minHeight: 120)
                .accessibilityIdentifier("task-form.description")
        }
    }

    var itemsSection: some View {
        let items = machine.sortedItems(in: draft)

        return Section("Items") {
            HStack(spacing: 8) {
                TextField("Add item...", text: $newItemTitle)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("task-form.items.new-title")

                Button("Add") {
                    if machine.mutateItems(.add(title: newItemTitle), in: draft) {
                        newItemTitle = ""
                    }
                }
                .accessibilityIdentifier("task-form.items.add")
                .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if items.count > 1 {
                Button(itemEditMode == .active ? "Done Reordering" : "Reorder Items") {
                    withAnimation(.snappy(duration: 0.2)) {
                        itemEditMode = itemEditMode == .active ? .inactive : .active
                    }
                }
                .accessibilityIdentifier("task-form.items.reorder-toggle")
            }

            if items.isEmpty {
                Text("No items")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        TextField("Item title", text: itemTitleBinding(for: item))
                            .accessibilityIdentifier("task-form.items.\(index).title")

                        Spacer(minLength: 4)

                        Button(role: .destructive) {
                            _ = machine.mutateItems(.delete(item), in: draft)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityIdentifier("task-form.items.\(index).delete")
                        .buttonStyle(.borderless)
                    }
                }
                .onMove { source, destination in
                    _ = machine.mutateItems(.move(from: source, to: destination), in: draft)
                }
            }
        }
    }

    @ViewBuilder
    var stateControl: some View {
        switch machine.taskStateOptionsState {
        case .loading:
            LabeledContent("State") {
                ProgressView("Loading states...")
            }
        case .available:
            Picker("State", selection: $draft.state) {
                ForEach(machine.taskStateOptions, id: \.id) { option in
                    Text(option.label)
                        .tag(option.id)
                        .accessibilityIdentifier("task-form.state.\(option.id)")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: draft.state) { _, newValue in
                if let option = machine.taskStateOptions.first(where: { $0.id == newValue }) {
                    draft.stateLabel = option.label
                }
            }
        case .unavailable:
            LabeledContent("State") {
                Text("Unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    var peopleSection: some View {
        Section("People") {
            switch machine.userOptionsState {
            case .loading:
                LabeledContent("People") {
                    ProgressView("Loading people...")
                }
            case .available:
                Button {
                    activePeoplePicker = .assignee
                } label: {
                    taskFormSummaryRow(
                        title: "Assignee",
                        value: summaryText(for: .assignee),
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("task-form.summary.assignee")

                if case .create = mode {
                    Button {
                        activePeoplePicker = .author
                    } label: {
                        taskFormSummaryRow(
                            title: "Author",
                            value: summaryText(for: .author),
                            systemImage: "pencil.line"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("task-form.summary.author")
                }

                Button {
                    activePeoplePicker = .reviewers
                } label: {
                    taskFormSummaryRow(
                        title: "Reviewers",
                        value: summaryText(for: .reviewers),
                        systemImage: "person.2"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("task-form.summary.reviewers")

                Button {
                    activePeoplePicker = .watchers
                } label: {
                    taskFormSummaryRow(
                        title: "Watchers",
                        value: summaryText(for: .watchers),
                        systemImage: "eye"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("task-form.summary.watchers")
            case .unavailable:
                Text("People unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    var loadErrorSection: some View {
        if let metadataError = machine.metadataErrorPresentation {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(metadataError.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

fileprivate enum PeoplePickerRoute: String, Identifiable {
    case assignee
    case author
    case reviewers
    case watchers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assignee:
            return "Assignee"
        case .author:
            return "Author"
        case .reviewers:
            return "Reviewers"
        case .watchers:
            return "Watchers"
        }
    }

    var searchPrompt: String {
        switch self {
        case .assignee:
            return "Search assignees"
        case .author:
            return "Search authors"
        case .reviewers:
            return "Search reviewers"
        case .watchers:
            return "Search watchers"
        }
    }

    var allowsMultipleSelection: Bool {
        switch self {
        case .reviewers, .watchers:
            return true
        case .assignee, .author:
            return false
        }
    }

    var supportsEmptySelection: Bool {
        switch self {
        case .assignee, .reviewers, .watchers:
            return true
        case .author:
            return false
        }
    }

    var emptySelectionTitle: String {
        switch self {
        case .assignee:
            return "Unassigned"
        case .author:
            return ""
        case .reviewers:
            return "No reviewers"
        case .watchers:
            return "No watchers"
        }
    }
}

fileprivate enum PeoplePickerSelection: Equatable {
    case single(String?)
    case multiple(Set<String>)
}

fileprivate struct TaskFormPeoplePicker: View {
    let route: PeoplePickerRoute
    let users: [User]
    let initialSelection: PeoplePickerSelection
    let onDone: (PeoplePickerSelection) -> Void

    @State private var searchText = ""
    @State private var singleSelection: String?
    @State private var multiSelection: Set<String>

    init(
        route: PeoplePickerRoute,
        users: [User],
        initialSelection: PeoplePickerSelection,
        onDone: @escaping (PeoplePickerSelection) -> Void
    ) {
        self.route = route
        self.users = users
        self.initialSelection = initialSelection
        self.onDone = onDone

        switch initialSelection {
        case .single(let selectedID):
            _singleSelection = State(initialValue: selectedID)
            _multiSelection = State(initialValue: [])
        case .multiple(let selectedIDs):
            _singleSelection = State(initialValue: nil)
            _multiSelection = State(initialValue: selectedIDs)
        }
    }

    var body: some View {
        List {
            if route.supportsEmptySelection {
                clearSection
            }
            resultsSection
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: route.searchPrompt
        )
        .toolbar { toolbarContent }
        .accessibilityIdentifier("task-form.picker.\(route.rawValue)")
    }

    var filteredUsers: [User] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return users }
        return users.filter { $0.displayName.localizedCaseInsensitiveContains(trimmed) }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                onDone(currentSelection)
            }
            .accessibilityIdentifier("task-form.picker.\(route.rawValue).done")
        }
    }

    var currentSelection: PeoplePickerSelection {
        if route.allowsMultipleSelection {
            return .multiple(multiSelection)
        }
        return .single(singleSelection)
    }

    var clearSection: some View {
        Section {
            Button {
                if route.allowsMultipleSelection {
                    multiSelection.removeAll()
                } else {
                    singleSelection = nil
                }
            } label: {
                Text(route.allowsMultipleSelection ? "Deselect all" : route.emptySelectionTitle)
                    .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("task-form.picker.\(route.rawValue).clear")
        }
    }

    var resultsSection: some View {
        Section(filteredUsers.isEmpty ? "No Results" : "People") {
            if filteredUsers.isEmpty {
                Text("No matches")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredUsers, id: \.id) { user in
                    Button {
                        toggle(user)
                    } label: {
                        HStack {
                            Text(user.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if isSelected(user) {
                                Image(systemName: route.allowsMultipleSelection ? "checkmark.circle.fill" : "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .accessibilityIdentifier("task-form.picker.\(route.rawValue).row.\(user.id)")
                }
            }
        }
    }

    var isEmptySelectionActive: Bool {
        if route.allowsMultipleSelection {
            return multiSelection.isEmpty
        }
        return singleSelection == nil
    }

    func isSelected(_ user: User) -> Bool {
        if route.allowsMultipleSelection {
            return multiSelection.contains(user.id)
        }
        return singleSelection == user.id
    }

    func toggle(_ user: User) {
        if route.allowsMultipleSelection {
            if multiSelection.contains(user.id) {
                multiSelection.remove(user.id)
            } else {
                multiSelection.insert(user.id)
            }
        } else {
            singleSelection = user.id
        }
    }
}

@ViewBuilder
fileprivate func taskFormSummaryRow(title: String, value: String, systemImage: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: 24)

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
}
