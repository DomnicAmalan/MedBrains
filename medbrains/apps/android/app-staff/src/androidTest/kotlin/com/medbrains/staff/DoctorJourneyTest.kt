package com.medbrains.staff

import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The doctor journeys the Detox suite carried (opd-queue, doctor-consultation), natively.
 * See DoctorJourneyTests.swift for the scenarios; the two suites assert the same things.
 */
@RunWith(AndroidJUnit4::class)
class DoctorJourneyTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    private fun has(tag: String) = with(Session) { compose.has(tag) }
    private fun signInAsDoctor() = with(Session) { compose.signInAs("native_doctor", "NativeDoctor#2026", "module-home-doctor") }

    private fun openQueue() {
        compose.onNodeWithTag("module-action-queue").performClick()
        compose.waitUntil(10_000) { has("screen-doctor-queue") }
        compose.waitUntil(10_000) { has("queue-call-next") }
    }

    @Test
    fun queueOffersCallNextAndNeverAnImpossibleTransition() {
        signInAsDoctor()
        openQueue()
        check(!has("queue-mark-complete")) { "no transition the queue is not in" }
        compose.onNodeWithTag("queue-call-next").performClick()
        compose.waitUntil(10_000) { has("queue-call-next-toast") }
    }

    @Test
    fun consultationIsReachedFromTheQueueAndRefusesAnEmptyNote() {
        // A fresh visit for this doctor, so the note is genuinely unwritten.
        val visit = checkNotNull(Seed.waitingVisit("native_doctor")) { "could not seed a waiting visit" }
        signInAsDoctor()
        openQueue()
        compose.waitUntil(10_000) { has("queue-row-${visit.patientId}") }
        compose.onNodeWithTag("queue-row-${visit.patientId}").performClick()
        compose.waitUntil(10_000) { has("screen-queue-detail") }
        if (has("queue-call-patient")) {
            compose.onNodeWithTag("queue-call-patient").performClick()
            // The transition disables every control until the server answers.
            compose.waitUntil(10_000) { has("queue-recall-patient") }
        }
        if (has("queue-recall-patient")) check(has("queue-no-show")) { "recall and no-show travel together" }
        compose.onNodeWithTag("queue-open-consultation").performClick()
        compose.waitUntil(10_000) { has("screen-consultation") }
        compose.waitUntil(10_000) { has("field-chief_complaint") }
        check(has("consultation-unsaved")) { "nothing is written yet" }
        compose.onNodeWithTag("consultation-save").performScrollTo().performClick()
        compose.waitUntil(5_000) { compose.onAllNodes(hasText("Record why the patient is here")).fetchSemanticsNodes().isNotEmpty() }
        compose.onNodeWithTag("field-chief_complaint").performScrollTo().performTextInput("Fever and cough, three days")
        compose.onNodeWithTag("consultation-save").performScrollTo().performClick()
        compose.waitUntil(15_000) { has("consultation-saved") }
    }
}
