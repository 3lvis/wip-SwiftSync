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

    @State private var machine: TaskFormSheetMachine
    @State private var itemEditMode: EditMode = .inactive
    @State private var activePeoplePicker: PeoplePickerRoute?
    @State private var reviewerToAdd: String?
    @State private var watcherToAdd: String?

    init(mode: TaskFormMode, syncContainer: SyncContainer, syncEngine: DemoSyncEngine) {
        self.mode = mode
        self.syncContainer = syncContainer
        self.syncEngine = syncEngine

        let ctx = ModelContext(syncContainer.modelContainer)
        ctx.autosaveEnabled = false
        self.editContext = ctx
        _machine = State(
            initialValue: TaskFormSheetMachine(syncContainer: syncContainer, syncEngine: syncEngine, editContext: ctx)
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
            if let fetched {
                Self.hydratePeopleRelationships(on: fetched, from: task, in: ctx)
            }
            // Fallback should never be reached in practice — the row is always in the store.
            // If it somehow is, we fall back to the passed object (which lives in mainContext,
            // so edits won't reach the store either, preserving the no-save guarantee).
            _draft = State(initialValue: fetched ?? task)
        }
    }

    var body: some View {
        NavigationStack {
            List { content }
            .listStyle(.plain)
            .accessibilityIdentifier("task-form")
            .environment(\.editMode, $itemEditMode)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .sheet(item: $activePeoplePicker) { route in
            NavigationStack {
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
        authorSection
        reviewersSection
        watchersSection
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
        case .author:
            return .single(draft.authorID.isEmpty ? nil : draft.authorID)
        case .reviewers, .watchers:
            return .single(nil)
        }
    }

    fileprivate func applySelection(_ selection: PeoplePickerSelection, for route: PeoplePickerRoute) {
        switch route {
        case .author:
            if case .single(let selectedID) = selection {
                draft.authorID = selectedID ?? ""
            }
        case .reviewers, .watchers:
            break
        }
    }

    func users(matching selectedIDs: Set<String>) -> [User] {
        machine.users.filter { selectedIDs.contains($0.id) }
    }

    func displayName(for userID: String?) -> String? {
        guard let userID else { return nil }
        return machine.users.first(where: { $0.id == userID })?.displayName
    }

    static func hydratePeopleRelationships(on draft: Task, from source: Task, in context: ModelContext) {
        let users = (try? context.fetch(FetchDescriptor<User>())) ?? []
        let usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        draft.reviewers = source.reviewers.compactMap { usersByID[$0.id] }
        draft.watchers = source.watchers.compactMap { usersByID[$0.id] }
        draft.author = usersByID[source.authorID]
        draft.assignee = source.assigneeID.flatMap { usersByID[$0] }
    }

    fileprivate func summaryText(for route: PeoplePickerRoute) -> String {
        switch route {
        case .author:
            return displayName(for: draft.authorID.isEmpty ? nil : draft.authorID) ?? "Choose author"
        case .reviewers:
            return peopleSummary(for: draft.reviewers)
        case .watchers:
            return peopleSummary(for: draft.watchers)
        }
    }

    fileprivate var availableReviewers: [User] {
        let selectedIDs = Set(draft.reviewers.map(\.id))
        return machine.users.filter { !selectedIDs.contains($0.id) }
    }

    fileprivate var availableWatchers: [User] {
        let selectedIDs = Set(draft.watchers.map(\.id))
        return machine.users.filter { !selectedIDs.contains($0.id) }
    }

    fileprivate func addReviewer(_ userID: String?) {
        defer { reviewerToAdd = nil }
        guard let userID,
              let user = machine.users.first(where: { $0.id == userID }),
              !draft.reviewers.contains(where: { $0.id == userID }) else { return }
        draft.reviewers.append(user)
    }

    fileprivate func addWatcher(_ userID: String?) {
        defer { watcherToAdd = nil }
        guard let userID,
              let user = machine.users.first(where: { $0.id == userID }),
              !draft.watchers.contains(where: { $0.id == userID }) else { return }
        draft.watchers.append(user)
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
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $draft.title)
                    .frame(minHeight: 72)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("task-form.title")

                VStack(alignment: .leading, spacing: 8) {
                    stateControl
                    assigneeControl
                }
            }
            .padding(.vertical, 8)
        }
    }

    var descriptionSection: some View {
        Section("Description") {
            TextField("Why this task matters", text: $draft.descriptionText)
                .accessibilityIdentifier("task-form.description")
        }
    }

    var itemsSection: some View {
        let items = machine.sortedItems(in: draft)

        return Section {
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
        } header: {
            HStack {
                Text("Items")
                Spacer()
                Button {
                    addEmptyItem()
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("task-form.items.add")
            }
        }
    }

    func addEmptyItem() {
        let item = Item(
            taskID: draft.id,
            title: "",
            position: draft.items.count,
            createdAt: Date(),
            updatedAt: Date(),
            task: draft
        )
        draft.items.append(item)
        machine.normalizeItemPositions(in: draft)
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

    @ViewBuilder
    var assigneeControl: some View {
        switch machine.userOptionsState {
        case .loading:
            LabeledContent("Assignee") {
                ProgressView("Loading people...")
            }
        case .available:
            Picker("Assignee", selection: $draft.assigneeID) {
                Text("Unassigned")
                    .tag(Optional<String>.none)
                    .accessibilityIdentifier("task-form.assignee.option.unassigned")

                ForEach(machine.users, id: \.id) { user in
                    Text(user.displayName)
                        .tag(Optional(user.id))
                        .accessibilityIdentifier("task-form.assignee.option.\(user.id)")
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("task-form.summary.assignee")
        case .unavailable:
            LabeledContent("Assignee") {
                Text("Unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    var authorSection: some View {
        if case .create = mode {
            Section("Author") {
                switch machine.userOptionsState {
                case .loading:
                    ProgressView("Loading people...")
                case .available:
                    Button {
                        activePeoplePicker = .author
                    } label: {
                        HStack(spacing: 12) {
                            Text("Author")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(summaryText(for: .author))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("task-form.summary.author")
                case .unavailable:
                    Text("People unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    var reviewersSection: some View {
        Section {
            peopleRows(for: .reviewers, users: draft.reviewers)
        } header: {
            peopleSectionHeader(title: "Reviewers", selection: $reviewerToAdd, users: availableReviewers, accessibilityPrefix: "reviewers")
        }
        .onChange(of: reviewerToAdd) { _, newValue in
            addReviewer(newValue)
        }
    }

    @ViewBuilder
    var watchersSection: some View {
        Section {
            peopleRows(for: .watchers, users: draft.watchers)
        } header: {
            peopleSectionHeader(title: "Watchers", selection: $watcherToAdd, users: availableWatchers, accessibilityPrefix: "watchers")
        }
        .onChange(of: watcherToAdd) { _, newValue in
            addWatcher(newValue)
        }
    }

    @ViewBuilder
    fileprivate func peopleRows(for route: PeoplePickerRoute, users: [User]) -> some View {
        switch machine.userOptionsState {
        case .loading:
            ProgressView("Loading people...")
        case .available:
            let sortedUsers = users.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            if sortedUsers.isEmpty {
                Text("None")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedUsers, id: \.id) { user in
                    HStack(spacing: 12) {
                        Text(user.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button(role: .destructive) {
                            remove(user, from: route)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove \(user.displayName)")
                        .accessibilityIdentifier("task-form.\(route.rawValue).delete.\(user.id)")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("task-form.\(route.rawValue).row.\(user.id)")
                }
            }
        case .unavailable:
            Text("People unavailable")
                .foregroundStyle(.secondary)
        }
    }

    fileprivate func remove(_ user: User, from route: PeoplePickerRoute) {
        switch route {
        case .reviewers:
            draft.reviewers.removeAll { $0.id == user.id }
        case .watchers:
            draft.watchers.removeAll { $0.id == user.id }
        case .author:
            break
        }
    }

    @ViewBuilder
    fileprivate func peopleSectionHeader(
        title: String,
        selection: Binding<String?>,
        users: [User],
        accessibilityPrefix: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            if users.isEmpty {
                HStack(spacing: 4) {
                    Text("All added")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .accessibilityIdentifier("task-form.\(accessibilityPrefix).all-added")
            } else {
                Picker(
                    selection: Binding(
                        get: { selection.wrappedValue ?? "" },
                        set: { newValue in
                            selection.wrappedValue = newValue.isEmpty ? nil : newValue
                        }
                    )
                ) {
                    Text("Add \(title.dropLast())")
                        .tag("")
                        .accessibilityIdentifier("task-form.\(accessibilityPrefix).placeholder")

                    ForEach(users, id: \.id) { user in
                        Text(user.displayName)
                            .tag(user.id)
                            .accessibilityIdentifier("task-form.\(accessibilityPrefix).option.\(user.id)")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityIdentifier("task-form.\(accessibilityPrefix).add")
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
    case author
    case reviewers
    case watchers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .author:
            return "Author"
        case .reviewers:
            return "Reviewers"
        case .watchers:
            return "Watchers"
        }
    }

    var supportsEmptySelection: Bool {
        switch self {
        case .author:
            return false
        case .reviewers, .watchers:
            return false
        }
    }

    var emptySelectionTitle: String {
        switch self {
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
}

fileprivate struct TaskFormPeoplePicker: View {
    let route: PeoplePickerRoute
    let users: [User]
    let initialSelection: PeoplePickerSelection
    let onDone: (PeoplePickerSelection) -> Void

    @State private var searchText = ""
    @State private var singleSelection: String?

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
        .toolbar { toolbarContent }
        .accessibilityIdentifier("task-form.picker.\(route.rawValue)")
        .modifier(PeoplePickerSearchModifier(isEnabled: true, text: $searchText))
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
        return .single(singleSelection)
    }

    var clearSection: some View {
        Section {
            Button {
                singleSelection = nil
            } label: {
                Text(route.emptySelectionTitle)
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
                                Image(systemName: "checkmark")
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
        return singleSelection == nil
    }

    func isSelected(_ user: User) -> Bool {
        return singleSelection == user.id
    }

    func toggle(_ user: User) {
        singleSelection = user.id
    }
}

private struct PeoplePickerSearchModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search people"
            )
        } else {
            content
        }
    }
}
