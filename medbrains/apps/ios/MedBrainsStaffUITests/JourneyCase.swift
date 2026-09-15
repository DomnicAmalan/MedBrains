import XCTest

/// What every journey suite shares: the app under test pointed at the run's
/// backend, the admin API, screenshots as evidence, and — on the first
/// failure — a screenshot and the accessibility hierarchy attached, so a
/// "not found" names what the screen held instead. Suites override `setUp`
/// and call `super`.
class JourneyCase: XCTestCase {
    var app: XCUIApplication!
    var api: Api!

    override func setUp() {
        continueAfterFailure = false
        api = Api.admin()
        app = XCUIApplication()
        app.launchArguments = ["-baseURL", Api.backend.absoluteString]
    }

    func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }

    func shoot(_ name: String) {
        let s = XCTAttachment(screenshot: app.screenshot())
        s.name = name
        s.lifetime = .keepAlways
        add(s)
    }

    /// Any static text whose label contains `text`, waited for.
    func sees(_ text: String, timeout: TimeInterval = 5) -> Bool {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: timeout)
    }

    private var dumped = false

    override func record(_ issue: XCTIssue) {
        if !dumped, let app, issue.type == .assertionFailure || issue.type == .thrownError || issue.type == .uncaughtException {
            dumped = true
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "at-failure"
            shot.lifetime = .keepAlways
            add(shot)
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "hierarchy-at-failure"
            tree.lifetime = .keepAlways
            add(tree)
        }
        super.record(issue)
    }
}
