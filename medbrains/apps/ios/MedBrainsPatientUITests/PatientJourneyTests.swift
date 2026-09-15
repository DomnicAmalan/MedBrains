import XCTest

/// The patient's way in and the hospital's record of them.
///
/// - Given a phone number, When "Send me a code" is pressed, Then the code
///   step appears — and the screen says nothing about whether the number is
///   registered (the server answers the same either way).
/// - Given a code seeded for the number (`scripts/seed_portal_otp.sh
///   9876500777 424242`, because the server hashes codes and hands the clear
///   text only to the SMS outbox), When entered via "I already have a code",
///   Then the Hospital tab opens with every record module, the Health tab is
///   absent while the hospital has not licensed the companion, and Bills
///   shows exactly one of a list or the empty state.
final class PatientJourneyTests: XCTestCase {
    private var app: XCUIApplication!
    private let phone = "9876500777"

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-baseURL", ProcessInfo.processInfo.environment["MEDBRAINS_BASE_URL"] ?? "http://127.0.0.1:3000", "-hospitalCode", "DEFAULT"]
        app.launch()
    }

    private func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }

    /// The Keychain keeps the session between launches; hydration takes a moment either way.
    private func signOutIfSignedIn() {
        let account = app.navigationBars.buttons["Account"].firstMatch
        let deadline = Date().addingTimeInterval(10)
        while !el("phone").exists, !account.exists, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.25)) }
        if el("phone").exists { return }
        account.tap()
        app.buttons["Sign out"].tap()
        XCTAssertTrue(el("phone").waitForExistence(timeout: 10))
    }

    private func shoot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAskingForACodeLeadsToTheCodeStep() {
        signOutIfSignedIn()
        shoot("patient-01-login")
        el("phone").tap()
        el("phone").typeText(phone)
        el("sendCode").tap()
        XCTAssertTrue(el("code").waitForExistence(timeout: 10), "the code step follows, registered or not")
        shoot("patient-02-code-step")
    }

    func testASeededCodeSignsInToTheHospitalRecord() {
        signOutIfSignedIn()
        el("phone").tap()
        el("phone").typeText(phone)
        el("haveCode").tap()
        XCTAssertTrue(el("code").waitForExistence(timeout: 5))
        el("code").tap()
        el("code").typeText("424242")
        el("verify").tap()
        XCTAssertTrue(el("tab-hospital").waitForExistence(timeout: 15), "the hospital record opens")
        shoot("patient-03-hospital")
        for module in ["appointments", "lab-reports", "prescriptions", "bills", "consent", "family-share"] {
            XCTAssertTrue(el("module-\(module)").exists, "\(module) is offered")
        }
        XCTAssertFalse(app.tabBars.buttons["Health"].exists, "the companion stays hidden until the hospital licenses it")
        el("module-bills").tap()
        XCTAssertTrue(el("screen-bills").waitForExistence(timeout: 10))
        let list = el("bills-list"), empty = el("bills-empty")
        let deadline = Date().addingTimeInterval(10)
        while !list.exists, !empty.exists, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.25)) }
        XCTAssertTrue(list.exists != empty.exists, "a list or nothing billed — never neither")
        shoot("patient-04-bills")
    }
}
