import SwiftData
import SwiftSync
import XCTest
@testable import DemoCore

final class AssigneeMutationRegressionTests: XCTestCase {
    @MainActor
    func testUpdateTaskAssignsPreviouslyUnassignedTask() async throws {
        let seed = DemoSeedData.generate()
        let syncContainer = try makeSyncContainer()
        let apiClient = FakeDemoAPIClient(seedData: seed)
        let engine = DemoSyncEngine(syncContainer: syncContainer, apiClient: apiClient)

        let projectID = DemoSeedData.SeedIDs.Projects.notificationsReliability
        let taskID = DemoSeedData.SeedIDs.Tasks.incidentPlaybook
        let assigneeID = DemoSeedData.SeedIDs.Users.miaPatel

        try await engine.syncProjectTasks(projectID: projectID)
        try await engine.syncTaskDetail(taskID: taskID)

        let originalTask = try XCTUnwrap(fetchTask(id: taskID, in: syncContainer.mainContext))
        XCTAssertNil(originalTask.assigneeID)
        XCTAssertNil(originalTask.assignee)

        let editContext = ModelContext(syncContainer.modelContainer)
        let draft = try XCTUnwrap(fetchTask(id: taskID, in: editContext))
        draft.assigneeID = assigneeID

        let payload = try DemoSyncPayload(dictionary: draft.exportObject(for: syncContainer))
        try await engine.updateTask(taskID: taskID, projectID: projectID, body: payload)

        let updatedTask = try XCTUnwrap(fetchTask(id: taskID, in: syncContainer.mainContext))
        XCTAssertEqual(updatedTask.assigneeID, assigneeID)
        XCTAssertEqual(updatedTask.assignee?.id, assigneeID)
        XCTAssertEqual(updatedTask.assignee?.displayName, "Mia Patel")
    }

    @MainActor
    func testTaskDetailMachineRefreshesAfterAssigningPreviouslyUnassignedTask() async throws {
        let seed = DemoSeedData.generate()
        let syncContainer = try makeSyncContainer()
        let apiClient = FakeDemoAPIClient(seedData: seed)
        let engine = DemoSyncEngine(syncContainer: syncContainer, apiClient: apiClient)

        let projectID = DemoSeedData.SeedIDs.Projects.notificationsReliability
        let taskID = DemoSeedData.SeedIDs.Tasks.incidentPlaybook
        let assigneeID = DemoSeedData.SeedIDs.Users.miaPatel

        try await engine.syncProjectTasks(projectID: projectID)
        try await engine.syncTaskDetail(taskID: taskID)

        let machine = TaskDetailMachine(taskID: taskID, syncContainer: syncContainer, syncEngine: engine)
        machine.send(.onAppear)
        try await waitUntil {
            machine.task?.id == taskID && machine.task?.assigneeID == nil
        }

        let editContext = ModelContext(syncContainer.modelContainer)
        let draft = try XCTUnwrap(fetchTask(id: taskID, in: editContext))
        draft.assigneeID = assigneeID

        let payload = try DemoSyncPayload(dictionary: draft.exportObject(for: syncContainer))
        try await engine.updateTask(taskID: taskID, projectID: projectID, body: payload)

        try await waitUntil {
            machine.task?.assigneeID == assigneeID && machine.task?.assignee?.id == assigneeID
        }
    }

    @MainActor
    func testTaskFormMachineSaveAssignsPreviouslyUnassignedTask() async throws {
        let seed = DemoSeedData.generate()
        let syncContainer = try makeSyncContainer()
        let apiClient = FakeDemoAPIClient(seedData: seed)
        let engine = DemoSyncEngine(syncContainer: syncContainer, apiClient: apiClient)

        let projectID = DemoSeedData.SeedIDs.Projects.notificationsReliability
        let taskID = DemoSeedData.SeedIDs.Tasks.incidentPlaybook
        let assigneeID = DemoSeedData.SeedIDs.Users.miaPatel

        try await engine.syncProjectTasks(projectID: projectID)
        try await engine.syncTaskDetail(taskID: taskID)
        try await engine.syncTaskFormMetadata()

        let originalTask = try XCTUnwrap(fetchTask(id: taskID, in: syncContainer.mainContext))

        let editContext = ModelContext(syncContainer.modelContainer)
        editContext.autosaveEnabled = false
        let machine = TaskFormMachine(syncContainer: syncContainer, syncEngine: engine, editContext: editContext)
        machine.send(.metadata(.onAppear))
        try await waitUntil {
            machine.userOptionsState == .available && machine.taskStateOptionsState == .available
        }

        let draft = try XCTUnwrap(fetchTask(id: taskID, in: editContext))
        draft.assigneeID = assigneeID

        let saved = expectation(description: "save callback")
        machine.send(.save(mode: .edit(task: originalTask), draft: draft, onSuccess: {
            saved.fulfill()
        }))
        await fulfillment(of: [saved], timeout: 10)

        let updatedTask = try XCTUnwrap(fetchTask(id: taskID, in: syncContainer.mainContext))
        XCTAssertEqual(updatedTask.assigneeID, assigneeID)
        XCTAssertEqual(updatedTask.assignee?.id, assigneeID)
    }

    @MainActor
    func testProjectDetailMachineResolvesAssigneeNameAfterAssigningPreviouslyUnassignedTask() async throws {
        let seed = DemoSeedData.generate()
        let syncContainer = try makeSyncContainer()
        let apiClient = FakeDemoAPIClient(seedData: seed)
        let engine = DemoSyncEngine(syncContainer: syncContainer, apiClient: apiClient)

        let projectID = DemoSeedData.SeedIDs.Projects.notificationsReliability
        let taskID = DemoSeedData.SeedIDs.Tasks.incidentPlaybook
        let assigneeID = DemoSeedData.SeedIDs.Users.miaPatel

        try await engine.syncProjectTasks(projectID: projectID)
        let machine = ProjectDetailMachine(projectID: projectID, syncContainer: syncContainer, syncEngine: engine)
        machine.send(.onAppear)
        try await waitUntil {
            machine.tasks.contains(where: { $0.id == taskID && $0.assigneeID == nil })
        }

        let editContext = ModelContext(syncContainer.modelContainer)
        let draft = try XCTUnwrap(fetchTask(id: taskID, in: editContext))
        draft.assigneeID = assigneeID

        let payload = try DemoSyncPayload(dictionary: draft.exportObject(for: syncContainer))
        try await engine.updateTask(taskID: taskID, projectID: projectID, body: payload)

        try await waitUntil {
            machine.tasks.contains(where: { $0.id == taskID && $0.assigneeID == assigneeID })
        }
        XCTAssertEqual(machine.userDisplayName(for: assigneeID), "Mia Patel")
    }

    @MainActor
    private func makeSyncContainer() throws -> SyncContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try SyncContainer(
            for: Project.self,
            User.self,
            Task.self,
            Item.self,
            TaskStateOption.self,
            configurations: configuration
        )
    }

    @MainActor
    private func fetchTask(id: String, in context: ModelContext) throws -> Task? {
        try context.fetch(FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })).first
    }

    @MainActor
    private func waitUntil(
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        pollNanoseconds: UInt64 = 20_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: .nanoseconds(Int64(timeoutNanoseconds)))
        while ContinuousClock.now < deadline {
            if condition() {
                return
            }
            try await _Concurrency.Task.sleep(nanoseconds: pollNanoseconds)
        }
        XCTFail("Condition not satisfied before timeout")
    }
}
