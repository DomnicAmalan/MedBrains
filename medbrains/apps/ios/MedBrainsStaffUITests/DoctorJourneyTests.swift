import XCTest

/// The doctor journeys the Detox suite carried (opd-queue.e2e.ts,
/// doctor-consultation.e2e.ts), natively.
///
/// - Given a doctor signs in, the queue is offered and opens with "Call next";
///   "Mark complete" is never offered on a patient who has not been called.
/// - When "Call next" is pressed, the screen confirms it — a call that says
///   nothing is a call the doctor presses twice.
/// - Given a called token, recall and no-show are offered.
/// - The consultation is reached from the queue; saving an empty note is
///   refused on the field with the button still pressable; a note with a
///   chief complaint is recorded against the encounter.
final class DoctorJourneyTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-baseURL", ProcessInfo.processInfo.environment["MEDBRAINS_BASE_URL"] ?? "http://127.0.0.1:3000"]
        app.launch()
        signInAsDoctor()
    }

    private func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }

    private func signInAsDoctor() { Session.signIn(app, as: "native_doctor", password: "NativeDoctor#2026", home: "module-home-doctor") }

    private func shoot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func openQueue() {
        el("module-action-queue").tap()
        XCTAssertTrue(el("screen-doctor-queue").waitForExistence(timeout: 10))
        XCTAssertTrue(el("queue-call-next").waitForExistence(timeout: 10), "Call next exists on the doctor's own queue")
    }

    func testQueueOffersCallNextAndNeverAnImpossibleTransition() {
        shoot("doctor-01-home")
        openQueue()
        shoot("doctor-02-queue")
        XCTAssertFalse(el("queue-mark-complete").exists, "no transition the queue is not in")
        el("queue-call-next").tap()
        XCTAssertTrue(el("queue-call-next-toast").waitForExistence(timeout: 10), "the call confirms itself")
        shoot("doctor-03-called-next")
    }

    func testConsultationIsReachedFromTheQueueAndRefusesAnEmptyNote() {
        // A fresh visit for this doctor, so the note is genuinely unwritten.
        guard let visit = Seed.waitingVisit(for: "native_doctor") else { return XCTFail("could not seed a waiting visit") }
        openQueue()
        let row = el("queue-row-\(visit.patientId)")
        XCTAssertTrue(row.waitForExistence(timeout: 10), "the seeded token is on today's queue")
        row.tap()
        XCTAssertTrue(el("screen-queue-detail").waitForExistence(timeout: 10))
        if el("queue-call-patient").exists {
            el("queue-call-patient").tap()
            // The transition disables every control until the server answers.
            XCTAssertTrue(el("queue-recall-patient").waitForExistence(timeout: 10), "a called token offers recall")
        }
        if el("queue-recall-patient").exists {
            XCTAssertTrue(el("queue-no-show").exists, "recall and no-show travel together")
        }
        shoot("doctor-04-detail")
        el("queue-open-consultation").tap()
        XCTAssertTrue(el("screen-consultation").waitForExistence(timeout: 10))
        XCTAssertTrue(el("field-chief_complaint").waitForExistence(timeout: 10))
        XCTAssertTrue(el("consultation-unsaved").exists, "nothing is written yet")
        el("consultation-save").tap()
        XCTAssertTrue(app.staticTexts["Record why the patient is here"].waitForExistence(timeout: 5), "refused on the field")
        shoot("doctor-05-validation")
        let chief = el("field-chief_complaint")
        chief.tap()
        chief.typeText("Fever and cough, three days")
        el("consultation-save").tap()
        XCTAssertTrue(el("consultation-saved").waitForExistence(timeout: 15), "recorded against the encounter")
        shoot("doctor-06-saved")
    }
}
