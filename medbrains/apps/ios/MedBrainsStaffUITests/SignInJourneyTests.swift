import XCTest

/// Phase 1 acceptance: a nurse signs in and lands on exactly the modules the
/// nurse role holds. Runs against the live dev backend (`-baseURL`), like the
/// Detox `registration-journey` it replaces. Screenshots are attached at
/// every step so a reviewer sees the screens, not just the assertions.
final class SignInJourneyTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-baseURL", ProcessInfo.processInfo.environment["MEDBRAINS_BASE_URL"] ?? "http://127.0.0.1:3000"]
    }

    private func shoot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testNurseSignsInAndSeesOnlyNurseModules() {
        app.launch()
        Session.ensureSignedOut(app)
        shoot("01-login")

        let username = app.textFields["Username or email"]
        XCTAssertTrue(username.waitForExistence(timeout: 10), "login form")
        username.tap()
        username.typeText("native_nurse")
        let password = app.secureTextFields["Password"]
        password.tap()
        password.typeText("NativeNurse#2026")
        app.buttons["signIn"].tap()

        let nurseTab = app.tabBars.buttons["Nurse"]
        XCTAssertTrue(nurseTab.waitForExistence(timeout: 15), "the nurse lands on the Nurse module")
        shoot("02-module-home")

        // The gate: a nurse holds nurse.dashboard.view and lab.orders.list,
        // never opd.visit.update, so Lab is offered and Doctor is not.
        XCTAssertFalse(app.tabBars.buttons["Doctor"].exists, "Doctor is gated on opd.visit.update")
        XCTAssertTrue(app.tabBars.buttons["Lab"].exists, "Lab is gated on lab.orders.list, which a nurse holds")
        // Registry order decides the landing: the nurse opens on Nurse, not on the last module.
        XCTAssertTrue(nurseTab.isSelected, "lands on the first permitted module")

        app.navigationBars.buttons["Account"].tap()
        XCTAssertTrue(app.buttons["Sign out"].waitForExistence(timeout: 5))
        shoot("03-account-menu")
        app.buttons["Sign out"].tap()
        XCTAssertTrue(app.textFields["Username or email"].waitForExistence(timeout: 10), "signed out")
    }

    func testWrongPasswordIsRefusedWithAMessage() {
        app.launch()
        Session.ensureSignedOut(app)
        let username = app.textFields["Username or email"]
        XCTAssertTrue(username.waitForExistence(timeout: 10))
        username.tap()
        username.typeText("native_nurse")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("wrong")
        app.buttons["signIn"].tap()
        XCTAssertTrue(app.staticTexts["Wrong username or password."].waitForExistence(timeout: 10))
        shoot("04-wrong-password")
    }
}
