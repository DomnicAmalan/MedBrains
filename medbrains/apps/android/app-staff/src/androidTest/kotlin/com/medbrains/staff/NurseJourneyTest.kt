package com.medbrains.staff

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The nurse journeys the Detox suite carried (nurse-calls, bcma), natively.
 * Every matcher is a tag; the copy is clinical wording that gets revised.
 *
 * - Given a nurse signs in, the module home offers "Open calls" and "My shift",
 *   and never a "Give now" button.
 * - Given the call board opens, exactly one of the list or the empty state is
 *   shown — never neither, because an outage rendered as emptiness tells a
 *   nurse the ward is quiet.
 * - Given a dose is taken to the bedside, the scanner comes first and
 *   "Give now" is not offered until the server has verified both scans.
 */
@RunWith(AndroidJUnit4::class)
class NurseJourneyTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    private fun has(tag: String) = with(Session) { compose.has(tag) }

    private fun signInAsNurse() = with(Session) { compose.signInAs("native_nurse", "NativeNurse#2026", "module-home-nurse") }

    private fun waitOneOf(a: String, b: String) {
        compose.waitUntil(10_000) { has(a) || has(b) }
        check(has(a) != has(b)) { "expected exactly one of $a / $b" }
    }

    @Test
    fun wardCallBoardSaysWhichOfTheTwoThingsIsTrue() {
        signInAsNurse()
        compose.onNodeWithTag("module-action-calls").assertIsDisplayed().performClick()
        compose.waitUntil(10_000) { has("screen-nurse-calls") }
        waitOneOf("nurse-calls-list", "nurse-calls-empty")
    }

    @Test
    fun aDoseCannotBeGivenWithoutAScan() {
        signInAsNurse()
        check(!has("bcma-give-now")) { "administration is never offered from the module home" }
        compose.onNodeWithTag("module-action-mar").performClick()
        compose.waitUntil(10_000) { has("screen-admissions") }
        waitOneOf("admissions-list", "admissions-empty")
        if (!has("admissions-list")) return
        compose.onAllNodes(androidx.compose.ui.test.SemanticsMatcher("admission row") { node ->
            node.config.getOrNull(androidx.compose.ui.semantics.SemanticsProperties.TestTag)?.startsWith("admission-") == true
        })[0].performClick()
        compose.waitUntil(10_000) { has("screen-patient-workspace") }
        compose.onNodeWithTag("workspace-mar").performClick()
        compose.waitUntil(10_000) { has("screen-mar") }
        compose.waitUntil(10_000) { has("mar-take-to-bedside") || has("mar-empty") }
        if (!has("mar-take-to-bedside")) return
        compose.onAllNodes(hasTestTag("mar-take-to-bedside"))[0].performClick()
        compose.waitUntil(10_000) { has("screen-administer-dose") }
        check(has("barcode-scanner")) { "the wristband scan comes first" }
        check(!has("bcma-give-now")) { "no give without a verified scan" }
    }
}
