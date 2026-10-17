//
//  Sauna_CompanionUITests.swift
//  Sauna CompanionUITests
//
//  A smoke test over the three tabs. It needs no Health data and grants no
//  permissions, so it runs the same on a clean simulator and on CI: what it
//  proves is that each tab builds and presents without crashing, which is
//  exactly the regression a change to any one screen tends to cause.
//

import XCTest

final class Sauna_CompanionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Generous on purpose: a shared CI runner can take well over ten seconds
    /// to bring up the app or switch a tab, and a short timeout there fails
    /// the test without anything being wrong with the app.
    static let launchTimeout: TimeInterval = 60
    static let stepTimeout: TimeInterval = 30

    /// Must match `Sauna_CompanionApp.skipHealthPromptKey`.
    static let skipHealthPromptKey = "SAUNA_UITEST_SKIP_HEALTH_PROMPT"

    /// English is forced so the assertions below can match on text without
    /// depending on the simulator's language — the app ships in four.
    ///
    /// The Health permission prompt is switched off: it is a system sheet
    /// covering the app, and a simulator that has not been asked before — a
    /// fresh CI runner, every run — would fail every assertion underneath it.
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment[Self.skipHealthPromptKey] = "1"
        app.launch()
        return app
    }

    @MainActor
    func testEachTabOpens() throws {
        let app = launchApp()

        // Statistics is the tab the app opens on.
        XCTAssertTrue(
            app.navigationBars["Statistics"].waitForExistence(timeout: Self.launchTimeout),
            "the app should open on the Statistics tab"
        )

        for tab in ["History", "Settings"] {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: Self.stepTimeout), "missing tab: \(tab)")
            button.tap()
            XCTAssertTrue(
                app.navigationBars[tab].waitForExistence(timeout: Self.stepTimeout),
                "tapping \(tab) should show the \(tab) screen"
            )
        }
    }

    @MainActor
    func testSettingsShowsItsControls() throws {
        let app = launchApp()

        let settings = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: Self.launchTimeout))
        settings.tap()

        // The three things settings is for. The weight field itself only
        // appears once the override is switched on, so only its toggle is
        // asserted here.
        XCTAssertTrue(app.staticTexts["Calorie Estimate"].waitForExistence(timeout: Self.stepTimeout))
        XCTAssertTrue(app.switches["Vibration"].exists, "missing the vibration toggle")
        XCTAssertTrue(app.switches["Override HealthKit Weight"].exists, "missing the weight override toggle")
    }

    /// Launch timing means nothing on a shared CI runner, and its repeated
    /// launches are what pushed the UI tests over their timeouts there. CI
    /// passes `CI` into the runner through `TEST_RUNNER_CI`.
    @MainActor
    func testLaunchPerformance() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil, "launch timing is not measured on CI")
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
