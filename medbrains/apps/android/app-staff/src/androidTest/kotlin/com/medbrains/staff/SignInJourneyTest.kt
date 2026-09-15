package com.medbrains.staff

import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Phase 1 acceptance: a nurse signs in and lands on exactly the modules the
 * nurse role holds. Runs against the live dev backend at the emulator's host
 * loopback (10.0.2.2:3000), like the Detox `registration-journey` it replaces.
 */
@RunWith(AndroidJUnit4::class)
class SignInJourneyTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @Test
    fun nurseSignsInAndSeesOnlyNurseModules() {
        with(Session) { compose.ensureSignedOut() }
        compose.onNodeWithTag("username").performTextInput("native_nurse")
        compose.onNodeWithTag("password").performTextInput("NativeNurse#2026")
        compose.onNodeWithTag("signIn").performClick()

        compose.waitUntil(timeoutMillis = 15_000) {
            compose.onAllNodes(androidx.compose.ui.test.hasTestTag("module-nurse")).fetchSemanticsNodes().isNotEmpty()
        }
        // The gate: a nurse holds nurse.dashboard.view and lab.orders.list,
        // never opd.visit.update, so Lab is offered and Doctor is not.
        compose.onNodeWithTag("module-doctor").assertDoesNotExist()
        compose.onNodeWithTag("module-lab").assertExists()
        // Registry order decides the landing: the nurse opens on Nurse, not on the last module.
        compose.onNodeWithTag("module-nurse").assertIsSelected()

        compose.onNodeWithContentDescription("Account").performClick()
        compose.onNodeWithText("Sign out").performClick()
        compose.waitUntil(timeoutMillis = 10_000) {
            compose.onAllNodes(androidx.compose.ui.test.hasTestTag("signIn")).fetchSemanticsNodes().isNotEmpty()
        }
    }

    @Test
    fun wrongPasswordIsRefusedWithAMessage() {
        with(Session) { compose.ensureSignedOut() }
        compose.onNodeWithTag("username").performTextInput("native_nurse")
        compose.onNodeWithTag("password").performTextInput("wrong")
        compose.onNodeWithTag("signIn").performClick()
        compose.waitUntil(timeoutMillis = 10_000) {
            compose.onAllNodes(androidx.compose.ui.test.hasText("Wrong username or password.")).fetchSemanticsNodes().isNotEmpty()
        }
    }
}
