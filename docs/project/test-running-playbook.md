# Test-Running Playbook

This document defines the default way to run tests in this repo.

The goal is:

- get the fastest reliable signal for the layer being changed
- avoid full Xcode rebuilds between targeted UI test runs
- keep test execution predictable across agents and local development

## Rules

- Run commands sequentially.
- Use the narrowest test surface that can prove the change.
- For library and backend work, start with `swift test`.
- For `Demo/Demo/**` changes, build the demo app before finishing.
- For UI-test debugging, build once, then rerun one UI test at a time without rebuilding.

## Default commands by change type

### Swift package and backend changes

Use:

```bash
swift test
```

This is the default for changes in:

- `SwiftSync/**`
- `DemoBackend/**`
- `DemoCore/**` when an Xcode-only surface is not involved

### Demo app UI or behavior changes

Always finish with:

```bash
xcodebuild build \
  -workspace SwiftSync.xcworkspace \
  -scheme Demo \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=''
```

This is required for changes in:

- `Demo/Demo/**`
- `Demo/DemoUITests/**`

## UI test debugging loop

Do not run full `xcodebuild test` repeatedly when fixing one UI test.

Use this loop:

1. Build the UI tests once.
2. Run one failing UI test with `test-without-building`.
3. Read the failure.
4. Fix the product code or the test.
5. Re-run the same UI test.
6. Move to the next failing UI test only after the current one passes.

For this repo, run focused UI tests through:

```bash
./scripts/run_ui_test.sh DemoUITests/DemoUITests/testProjectAndTaskDetailShowSeededContent
```

That script is the default local loop because it pins the simulator, reuses derived data, disables parallel testing, and performs simulator preflight before each targeted run.

### Step 1: Build once for testing

Run:

```bash
xcodebuild build-for-testing \
  -workspace SwiftSync.xcworkspace \
  -scheme Demo \
  -destination 'id=<installed-simulator-udid>' \
  -parallel-testing-enabled NO \
  -derivedDataPath .build/xcode-ui-tests \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=''
```

### Step 2: Run one UI test without rebuilding

Run:

```bash
xcodebuild test-without-building \
  -workspace SwiftSync.xcworkspace \
  -scheme Demo \
  -destination 'id=<installed-simulator-udid>' \
  -parallel-testing-enabled NO \
  -derivedDataPath .build/xcode-ui-tests \
  -only-testing:DemoUITests/DemoUITests/testProjectAndTaskDetailShowSeededContent \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=''
```

Replace the final test identifier with the exact failing test you are working on.

### Step 3: Continue one by one

After the first test is fixed, run the next failing test with the same `test-without-building` command shape.

Do not return to `build-for-testing` unless:

- source changes invalidate the current build products
- Xcode reports the test bundle is missing or stale
- the simulator destination changes

If the test code changed, force a rebuild before the next targeted run.

## When a single test needs app data isolation

UI tests in this repo already isolate runs with launch environment values.

Keep using the test’s existing app bootstrap path.

Do not add a new Xcode test plan just to run one UI test at a time.

## Simulator preflight

Before `test-without-building`, boot the exact simulator and wait for it to finish booting.

Use:

```bash
xcrun simctl boot <installed-simulator-udid> || true
xcrun simctl bootstatus <installed-simulator-udid> -b
```

Do not rely on device names alone. Use an installed simulator UDID so reruns stay on the same device.

## Parallel testing

For focused UI test debugging in this repo, disable parallel testing.

Use:

```bash
-parallel-testing-enabled NO
```

This avoids Xcode cloning simulators for a single targeted UI test, which made runner-launch failures harder to reason about locally.

## Derived data reuse

Use one explicit derived-data path for the focused UI-test loop:

```bash
-derivedDataPath .build/xcode-ui-tests
```

Keep `build-for-testing` and `test-without-building` on the same path. This is what makes repeated targeted runs reuse the built test bundle instead of rebuilding it.

## Wait policy

Use the smallest wait that proves the contract.

- Start with `0.5` or `1` second.
- Increase only when the failing surface is genuinely asynchronous.
- Do not add broad sleeps to hide selector or accessibility bugs.

Prefer:

- `waitForExistence(timeout:)`
- `waitForNonExistence(timeout:)`

Avoid:

- arbitrary long waits
- retry loops that hide deterministic failures

## Assertion policy for UI tests

Assert the most stable user-meaningful surface.

- Prefer accessibility identifiers over positional queries.
- Do not assume XCTest will always expose a view as the same element type.
- If an identified element is sometimes surfaced as `Other` and sometimes as `StaticText`, query by identifier across `.any` instead of binding the test to one XCUI type.

## Standard execution order

When fixing a UI bug or broken UI test:

1. Pick one installed simulator UDID and keep using it for the whole session.
2. Boot that simulator and wait for boot completion.
3. Run `build-for-testing` once with `-parallel-testing-enabled NO` and `-derivedDataPath .build/xcode-ui-tests`.
4. Run one failing UI test with `test-without-building` on the same simulator UDID and derived-data path.
5. Fix the bug.
6. Re-run that same UI test with `test-without-building`.
7. Run the next failing UI test with `test-without-building` and no rebuild if the built products are still valid.
8. If the runner fails to launch, retry the same targeted run once after rebooting the simulator.
9. After the focused fixes are done, run the required demo build:

```bash
xcodebuild build \
  -workspace SwiftSync.xcworkspace \
  -scheme Demo \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=''
```

This is the default playbook. Follow it unless a task explicitly requires a different test surface.
