import XCTest

/// The nurse journeys the Detox suite carried (nurse-calls.e2e.ts,
/// bcma.e2e.ts), re-implemented natively. Every matcher is an id: the copy on
/// these screens is clinical wording that gets revised, and a suite anchored
/// to sentences fails on the revision rather than on the behaviour.
///
/// Scenarios:
/// - Given a nurse signs in, When the Nurse tab opens, Then the module home offers
///   "Open calls" and "My shift", and never a "Give now" button.
/// - Given the call board opens, Then exactly one of the list or the empty state
///   is shown — never neither, because an outage rendered as emptiness tells a
///   nurse the ward is quiet.
/// - Given a nurse reaches an admission's MAR, When a dose is taken to the bedside,
///   Then the administer screen shows the scanner and "Give now" is not offered
///   until the server has verified both scans.
final class NurseJourneyTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-baseURL", ProcessInfo.processInfo.environment["MEDBRAINS_BASE_URL"] ?? "http://127.0.0.1:3000"]
        app.launch()
        signInAsNurse()
    }

    /// Any element by accessibility identifier, whatever SwiftUI mapped it to.
    private func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }

    private func signInAsNurse() { Session.signIn(app, as: "native_nurse", password: "NativeNurse#2026", home: "module-home-nurse") }

    private func shoot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testWardCallBoardSaysWhichOfTheTwoThingsIsTrue() {
        shoot("nurse-01-home")
        XCTAssertTrue(el("module-action-calls").exists, "the board is offered from the nurse module")
        el("module-action-calls").tap()
        XCTAssertTrue(el("screen-nurse-calls").waitForExistence(timeout: 10))
        let list = el("nurse-calls-list")
        let empty = el("nurse-calls-empty")
        let deadline = Date().addingTimeInterval(10)
        while !list.exists, !empty.exists, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.25)) }
        shoot("nurse-02-calls")
        XCTAssertTrue(list.exists != empty.exists, "rows, or an answered ward — never neither, never both")
    }

    func testADoseCannotBeGivenWithoutAScan() {
        XCTAssertFalse(el("bcma-give-now").exists, "administration is never offered from the module home")
        el("module-action-mar").tap()
        XCTAssertTrue(el("screen-admissions").waitForExistence(timeout: 10))
        let list = el("admissions-list")
        let empty = el("admissions-empty")
        let deadline = Date().addingTimeInterval(10)
        while !list.exists, !empty.exists, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.25)) }
        shoot("nurse-03-admissions")
        XCTAssertTrue(list.exists != empty.exists)
        guard list.exists else { return }

        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'admission-'")).firstMatch.tap()
        XCTAssertTrue(el("screen-patient-workspace").waitForExistence(timeout: 10))
        shoot("nurse-04-workspace")
        el("workspace-mar").tap()
        XCTAssertTrue(el("screen-mar").waitForExistence(timeout: 10))
        shoot("nurse-05-mar")
        guard el("mar-take-to-bedside").waitForExistence(timeout: 5) else { return }
        el("mar-take-to-bedside").firstMatch.tap()
        XCTAssertTrue(el("screen-administer-dose").waitForExistence(timeout: 10))
        XCTAssertTrue(el("barcode-scanner").exists, "the wristband scan comes first")
        XCTAssertFalse(el("bcma-give-now").exists, "no give without a verified scan")
        shoot("nurse-06-administer")
    }
}
