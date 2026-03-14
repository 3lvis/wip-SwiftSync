import XCTest

private enum DemoUITestPlan {
    /*
     Source of truth for Demo UI automation planning.

     Purpose of the Demo app:
     - prove SwiftSync works in real app flows, not only isolated unit tests
     - show project list -> project detail -> task detail -> create/edit/delete behavior
     - act as an integration regression surface for synced reads, writes, and relationships

     Testing rule:
     - tests should map to user goals, not to screen checkpoints
     - navigation assertions only matter when they support a larger journey
     - add scaffolding only when the next real journey needs it

     Implemented coverage:
     - bootstrap smoke: launch and confirm the canonical seeded project list loads
     - journey: browse work and inspect task details
       path:
       1. open app
       2. open "Account Security Controls"
       3. open "Add session timeout controls to account settings"
       4. verify title, assignee, author, and seeded checklist items

     Planned journeys live below as commented-out test stubs so the file itself
     stays the active UI automation roadmap.
     */
}

private enum DemoSeedUserID {
    static let noahKim = "C3E7A1B2-2001-0000-0000-000000000002"
    static let miaPatel = "C3E7A1B2-2001-0000-0000-000000000003"
    static let liamBrown = "C3E7A1B2-2001-0000-0000-000000000004"
    static let sofiaGarcia = "C3E7A1B2-2001-0000-0000-000000000005"
    static let ethanLee = "C3E7A1B2-2001-0000-0000-000000000006"
}

private enum DemoSeedProjectID {
    static let accountSecurity = "C3E7A1B2-1001-0000-0000-000000000001"
    static let notificationsReliability = "C3E7A1B2-1001-0000-0000-000000000002"
}

private enum DemoSeedTaskID {
    static let sessionTimeout = "C3E7A1B2-3001-0000-0000-000000000001"
    static let securityPolicyPatch = "C3E7A1B2-3001-0000-0000-000000000002"
    static let qaItemList = "C3E7A1B2-3001-0000-0000-000000000003"
    static let duplicatePushFix = "C3E7A1B2-3001-0000-0000-000000000006"
    static let incidentPlaybook = "C3E7A1B2-3001-0000-0000-000000000009"
}

final class DemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // User journey: browse work and inspect synced task details.
    @MainActor
    func testProjectAndTaskDetailShowSeededContent() throws {
        let app = configuredApp()
        app.launch()

        openProject(app, id: DemoSeedProjectID.accountSecurity)
        openTask(app, id: DemoSeedTaskID.sessionTimeout)

        XCTAssertTrue(app.staticTexts["task.title"].exists)
        XCTAssertEqual(app.staticTexts["task.title"].label, "Add session timeout controls to account settings")
        XCTAssertEqual(app.staticTexts["task.assignee"].label, "Ava Martinez")
        XCTAssertEqual(app.staticTexts["task.author"].label, "Liam Brown")
        XCTAssertTrue(findAfterScrolling(app.staticTexts["Gather requirements"], in: app))
        XCTAssertTrue(findAfterScrolling(app.staticTexts["Draft implementation plan"], in: app))
    }

    @MainActor
    func testUpdateTaskTitleKeepsProjectAndDetailInSync() throws {
        let app = configuredApp()
        let updatedTitle = uniqueTitle(prefix: "UI Title Update")

        app.launch()
        openTaskDetail(
            app,
            projectID: DemoSeedProjectID.accountSecurity,
            taskID: DemoSeedTaskID.sessionTimeout
        )

        openEditTaskForm(app)

        replaceText(in: app.textViews["task-form.title"], with: updatedTitle, app: app)
        app.buttons["task-form.save"].tap()

        XCTAssertTrue(app.buttons["task-form.save"].waitForNonExistence(timeout: 0.5))
        XCTAssertEqual(app.staticTexts["task.title"].label, updatedTitle)

        goBack(app)
        XCTAssertTrue(app.staticTexts[updatedTitle].exists)
    }

    @MainActor
    func testCreateTaskInsideProject() throws {
        let app = configuredApp()
        let createdTitle = uniqueTitle(prefix: "UI Created Task")

        app.launch()
        openProject(app, id: DemoSeedProjectID.accountSecurity)

        openCreateTaskForm(app)

        let saveButton = app.buttons["task-form.save"]
        XCTAssertFalse(saveButton.isEnabled)

        replaceText(in: app.textViews["task-form.title"], with: createdTitle, app: app)
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts[createdTitle].exists)
        app.staticTexts[createdTitle].tap()

        XCTAssertTrue(app.staticTexts["task.title"].exists)
        XCTAssertEqual(app.staticTexts["task.title"].label, createdTitle)
    }

    @MainActor
    func testEditTaskItemsFlow() throws {
        let app = configuredApp()
        let addedItemTitle = uniqueTitle(prefix: "UI Added Item")
        let renamedItemTitle = "Relaunch flow after timeout"
        let deletedItemTitle = "Offline to online recovery"

        app.launch()
        openTaskDetail(
            app,
            projectID: DemoSeedProjectID.accountSecurity,
            taskID: DemoSeedTaskID.qaItemList
        )

        openEditTaskForm(app)

        scrollToVisible(app.textFields["task-form.items.new-title"], in: app)
        replaceText(in: app.textFields["task-form.items.new-title"], with: addedItemTitle, app: app)
        app.buttons["task-form.items.add"].tap()

        scrollToVisible(app.textFields["task-form.items.0.title"], in: app)
        replaceText(in: app.textFields["task-form.items.0.title"], with: renamedItemTitle, app: app)
        scrollToVisible(app.buttons["task-form.items.1.delete"], in: app)
        app.buttons["task-form.items.1.delete"].tap()
        app.buttons["task-form.save"].tap()

        XCTAssertTrue(app.buttons["task-form.save"].waitForNonExistence(timeout: 0.5))
        XCTAssertTrue(findAfterScrolling(app.staticTexts[renamedItemTitle], in: app))
        XCTAssertTrue(findAfterScrolling(app.staticTexts[addedItemTitle], in: app))
        XCTAssertFalse(app.staticTexts[deletedItemTitle].exists)
    }

    @MainActor
    func testEditTaskPeopleFlow() throws {
        let app = configuredApp()

        app.launch()
        openTaskDetail(
            app,
            projectID: DemoSeedProjectID.notificationsReliability,
            taskID: DemoSeedTaskID.duplicatePushFix
        )

        openEditTaskForm(app)

        openPeoplePicker(app, route: "assignee")
        tapAfterScrolling(app.buttons["task-form.picker.assignee.row.\(DemoSeedUserID.miaPatel)"], in: app)
        app.buttons["task-form.picker.assignee.done"].tap()

        openPeoplePicker(app, route: "reviewers")
        tapAfterScrolling(app.buttons["task-form.picker.reviewers.row.\(DemoSeedUserID.noahKim)"], in: app)
        tapAfterScrolling(app.buttons["task-form.picker.reviewers.row.\(DemoSeedUserID.sofiaGarcia)"], in: app)
        app.buttons["task-form.picker.reviewers.done"].tap()

        openPeoplePicker(app, route: "watchers")
        tapAfterScrolling(app.buttons["task-form.picker.watchers.row.\(DemoSeedUserID.ethanLee)"], in: app)
        tapAfterScrolling(app.buttons["task-form.picker.watchers.row.\(DemoSeedUserID.sofiaGarcia)"], in: app)
        app.buttons["task-form.picker.watchers.done"].tap()
        app.buttons["task-form.save"].tap()

        XCTAssertTrue(app.buttons["task-form.save"].waitForNonExistence(timeout: 0.5))
        XCTAssertEqual(app.staticTexts["task.assignee"].label, "Mia Patel")

        goBack(app)
        openTask(app, id: DemoSeedTaskID.duplicatePushFix)

        XCTAssertTrue(app.staticTexts["task.title"].exists)
        XCTAssertEqual(app.staticTexts["task.assignee"].label, "Mia Patel")
        XCTAssertTrue(findAfterScrolling(app.staticTexts["task.watcher.\(DemoSeedUserID.sofiaGarcia)"], in: app))
        XCTAssertFalse(app.staticTexts["task.reviewer.\(DemoSeedUserID.noahKim)"].exists)
        XCTAssertFalse(app.staticTexts["task.watcher.\(DemoSeedUserID.ethanLee)"].exists)
    }

    @MainActor
    func testAssignUnassignedTask() throws {
        let app = configuredApp()

        app.launch()
        openTaskDetail(
            app,
            projectID: DemoSeedProjectID.notificationsReliability,
            taskID: DemoSeedTaskID.incidentPlaybook
        )

        XCTAssertTrue(app.staticTexts["task.assignee"].exists)
        XCTAssertEqual(app.staticTexts["task.assignee"].label, "Unassigned")

        openEditTaskForm(app)
        openPeoplePicker(app, route: "assignee")
        tapAfterScrolling(app.buttons["task-form.picker.assignee.row.\(DemoSeedUserID.miaPatel)"], in: app)
        app.buttons["task-form.picker.assignee.done"].tap()
        app.buttons["task-form.save"].tap()

        XCTAssertTrue(app.buttons["task-form.save"].waitForNonExistence(timeout: 0.5))
        XCTAssertEqual(app.staticTexts["task.assignee"].label, "Mia Patel")

        goBack(app)
        openTask(app, id: DemoSeedTaskID.incidentPlaybook)

        XCTAssertTrue(app.staticTexts["task.title"].exists)
        XCTAssertEqual(app.staticTexts["task.assignee"].label, "Mia Patel")
    }

    @MainActor
    func testDeleteTaskFromProject() throws {
        let app = configuredApp()

        app.launch()
        openProject(app, id: DemoSeedProjectID.accountSecurity)

        deleteTaskFromProject(app, id: DemoSeedTaskID.securityPolicyPatch)
        XCTAssertFalse(app.descendants(matching: .any)["project.task.\(DemoSeedTaskID.securityPolicyPatch)"].exists)
        XCTAssertTrue(app.staticTexts["Add session timeout controls to account settings"].exists)
        XCTAssertTrue(app.staticTexts["Write QA item list for forced re-auth scenarios"].exists)
    }

    // TODO: Edge journey: cancel create.
    // Purpose:
    // - prove leaving the create form does not persist partial draft data
    //
    // @MainActor
    // func testCancelCreateDoesNotPersistTask() throws {}

    // TODO: Edge journey: cancel edit.
    // Purpose:
    // - prove leaving the edit form does not mutate the original task
    //
    // @MainActor
    // func testCancelEditKeepsOriginalTaskValues() throws {}

    // TODO: Edge journey: normalize empty description.
    // Purpose:
    // - prove clearing description content saves as "No description yet."
    //
    // @MainActor
    // func testEditTaskNormalizesEmptyDescription() throws {}

    @MainActor
    func testClearTaskReviewersOrWatchers() throws {
        let app = configuredApp()

        app.launch()
        openTaskDetail(
            app,
            projectID: DemoSeedProjectID.notificationsReliability,
            taskID: DemoSeedTaskID.duplicatePushFix
        )

        XCTAssertTrue(app.staticTexts["task.reviewer.\(DemoSeedUserID.noahKim)"].exists)

        openEditTaskForm(app)

        openPeoplePicker(app, route: "reviewers")
        tapAfterScrolling(app.buttons["task-form.picker.reviewers.row.\(DemoSeedUserID.noahKim)"], in: app)
        app.buttons["task-form.picker.reviewers.done"].tap()

        openPeoplePicker(app, route: "watchers")
        tapAfterScrolling(app.buttons["task-form.picker.watchers.row.\(DemoSeedUserID.liamBrown)"], in: app)
        tapAfterScrolling(app.buttons["task-form.picker.watchers.row.\(DemoSeedUserID.ethanLee)"], in: app)
        app.buttons["task-form.picker.watchers.done"].tap()
        app.buttons["task-form.save"].tap()

        XCTAssertTrue(app.buttons["task-form.save"].waitForNonExistence(timeout: 0.5))

        goBack(app)
        openTask(app, id: DemoSeedTaskID.duplicatePushFix)

        XCTAssertTrue(app.staticTexts["task.title"].exists)
        XCTAssertFalse(app.staticTexts["task.reviewer.\(DemoSeedUserID.noahKim)"].exists)
        XCTAssertFalse(app.staticTexts["task.watcher.\(DemoSeedUserID.liamBrown)"].exists)
        XCTAssertFalse(app.staticTexts["task.watcher.\(DemoSeedUserID.ethanLee)"].exists)
    }

    // TODO: Edge journey: cancel delete at the confirmation alert.
    // Purpose:
    // - prove destructive intent is not applied unless confirmed
    //
    // @MainActor
    // func testCancelDeleteKeepsTask() throws {}

    // TODO: Failure journey: empty project list.
    // Purpose:
    // - prove the app communicates there is no work yet
    // Harness:
    // - launch with a UI-test-specific empty seed instead of the canonical seeded data
    //
    // @MainActor
    // func testBrowseWorkWithEmptyProjectList() throws {}

    // TODO: Failure journey: empty project tasks.
    // Purpose:
    // - prove a project with no tasks renders its scoped empty state clearly
    // Harness:
    // - add one seeded project with no tasks to the UI-test fixture
    //
    // @MainActor
    // func testBrowseProjectWithNoTasks() throws {}

    // TODO: Failure journey: task with no items.
    // Purpose:
    // - prove empty task-detail checklist state is rendered clearly
    //
    // @MainActor
    // func testOpenTaskWithNoItems() throws {}

    // TODO: Failure journey: save failure.
    // Purpose:
    // - prove failed writes leave the form open and show a clear error
    // Harness:
    // - inject a UI-test engine/API behavior that fails the next task mutation while preserving reads
    //
    // @MainActor
    // func testEditTaskSaveFailure() throws {}

    // TODO: Failure journey: delete failure.
    // Purpose:
    // - prove failed deletes keep the task visible and show a clear error
    // Harness:
    // - inject a UI-test engine/API behavior that fails task delete while preserving reads
    //
    // @MainActor
    // func testDeleteTaskFailure() throws {}

    // TODO: Failure journey: edit while offline.
    // Purpose:
    // - prove an edit attempted after switching the demo to Offline stays on the form and shows a clear error
    // Harness:
    // - either switch the in-app scenario picker to Offline after the initial load or launch directly into Offline for a dedicated failure path
    //
    // @MainActor
    // func testEditTaskWhileOfflineShowsFailure() throws {}
}

private extension DemoUITests {
    func configuredApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SWIFTSYNC_UI_TESTING"] = "1"
        app.launchEnvironment["SWIFTSYNC_UI_TEST_RUN_ID"] = UUID().uuidString
        app.launchEnvironment["SWIFTSYNC_DEMO_SCENARIO"] = "fastStable"
        return app
    }

    func uniqueTitle(prefix: String) -> String {
        "\(prefix) \(UUID().uuidString.prefix(6))"
    }

    func openProject(_ app: XCUIApplication, id: String) {
        let row = app.cells["projects.row.\(id)"]
        XCTAssertTrue(row.exists)
        row.tap()
    }

    func openTask(_ app: XCUIApplication, id: String) {
        let taskRow = app.descendants(matching: .any)["project.task.\(id)"]
        XCTAssertTrue(taskRow.waitForExistence(timeout: 1))
        taskRow.tap()
    }

    func openTaskDetail(_ app: XCUIApplication, projectID: String, taskID: String) {
        openProject(app, id: projectID)
        openTask(app, id: taskID)
        XCTAssertTrue(app.staticTexts["task.title"].exists)
    }

    func goBack(_ app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func openCreateTaskForm(_ app: XCUIApplication) {
        app.buttons["New Task"].tap()
        XCTAssertTrue(app.buttons["task-form.save"].exists)
    }

    func openEditTaskForm(_ app: XCUIApplication) {
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["task-form.save"].exists)
    }

    func openPeoplePicker(_ app: XCUIApplication, route: String) {
        tapAfterScrolling(app.buttons["task-form.summary.\(route)"], in: app)
        XCTAssertTrue(app.buttons["task-form.picker.\(route).done"].waitForExistence(timeout: 1))
    }

    func deleteTaskFromProject(_ app: XCUIApplication, id: String) {
        let taskRow = app.descendants(matching: .any)["project.task.\(id)"]
        XCTAssertTrue(taskRow.waitForExistence(timeout: 1))
        taskRow.swipeLeft()
        app.buttons["Delete"].tap()
        app.alerts["Delete Task?"].buttons["Delete"].tap()
    }

    func tapAfterScrolling(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        for _ in 0..<maxSwipes where !element.isHittable {
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
            } else if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
            } else if app.otherElements["task-form"].exists {
                app.otherElements["task-form"].swipeUp()
            } else {
                app.swipeUp()
            }
        }
        XCTAssertTrue(element.exists)
        element.tap()
    }

    func scrollToVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        for _ in 0..<maxSwipes where !element.exists {
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
            } else if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
            } else if app.otherElements["task-form"].exists {
                app.otherElements["task-form"].swipeUp()
            } else {
                app.swipeUp()
            }
        }
        XCTAssertTrue(element.exists)
    }

    func tapVisible(_ element: XCUIElement) {
        XCTAssertTrue(element.exists)
        element.tap()
    }

    func findAfterScrolling(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) -> Bool {
        for _ in 0..<maxSwipes where !element.exists {
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
            } else if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        return element.exists
    }

    func replaceText(in element: XCUIElement, with text: String, app: XCUIApplication) {
        XCTAssertTrue(element.exists)
        element.tap()

        if let currentValue = element.value as? String, !currentValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            element.typeText(deleteString)
        }

        element.typeText(text)
    }
}
