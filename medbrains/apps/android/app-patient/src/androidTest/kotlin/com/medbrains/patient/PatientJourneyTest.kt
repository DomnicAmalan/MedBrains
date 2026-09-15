package com.medbrains.patient

import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The patient's way in and the hospital's record of them. See
 * PatientJourneyTests.swift for the scenarios; the code is seeded with
 * `scripts/seed_portal_otp.sh 9876500777 424242` before the run.
 */
@RunWith(AndroidJUnit4::class)
class PatientJourneyTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()
    private val phone = "9876500777"

    private fun has(tag: String) = compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().isNotEmpty()

    private fun signOutIfSignedIn() {
        compose.waitUntil(10_000) { has("phone") || has("patient-home") }
        if (has("phone")) return
        compose.onNodeWithContentDescription("Account").performClick()
        compose.onNodeWithText("Sign out").performClick()
        compose.waitUntil(10_000) { has("phone") }
    }

    @Test
    fun askingForACodeLeadsToTheCodeStep() {
        signOutIfSignedIn()
        compose.onNodeWithTag("phone").performTextInput(phone)
        compose.onNodeWithTag("sendCode").performClick()
        compose.waitUntil(10_000) { has("code") }
    }

    @Test
    fun aSeededCodeSignsInToTheHospitalRecord() {
        signOutIfSignedIn()
        compose.onNodeWithTag("phone").performTextInput(phone)
        compose.onNodeWithTag("haveCode").performClick()
        compose.waitUntil(5_000) { has("code") }
        compose.onNodeWithTag("code").performTextInput("424242")
        compose.onNodeWithTag("verify").performClick()
        compose.waitUntil(15_000) { has("tab-hospital") }
        for (m in listOf("appointments", "lab-reports", "prescriptions", "bills", "consent", "family-share")) check(has("module-$m")) { "$m is offered" }
        check(!has("tab-health-item")) { "the companion stays hidden until the hospital licenses it" }
        compose.onNodeWithTag("module-bills").performClick()
        compose.waitUntil(10_000) { has("screen-bills") }
        compose.waitUntil(10_000) { has("bills-list") || has("bills-empty") }
        check(has("bills-list") != has("bills-empty")) { "a list or nothing billed — never neither" }
    }
}
