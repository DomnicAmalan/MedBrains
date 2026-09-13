package com.medbrains.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialExpressiveTheme
import androidx.compose.material3.MotionScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

/**
 * Material 3 Expressive over the Carbon tokens. The colour roles are the
 * brand's; the shapes, motion and components are Material's. Screens name a
 * role from [androidx.compose.material3.MaterialTheme.colorScheme], never a hex.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun MedBrainsTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val scheme = if (darkTheme) {
        darkColorScheme(
            primary = Carbon.blue[3],
            onPrimary = Carbon.ink[9],
            secondary = Carbon.cinnabar[3],
            tertiary = Carbon.mint[3],
            error = Carbon.rose[3],
            background = Carbon.inkDark[9],
            surface = Carbon.inkDark[8],
        )
    } else {
        lightColorScheme(
            primary = Carbon.blue[5],
            onPrimary = Carbon.ink[0],
            secondary = Carbon.cinnabar[5],
            tertiary = Carbon.mint[4],
            error = Carbon.rose[5],
            background = Carbon.ink[0],
            surface = Carbon.ink[0],
            surfaceVariant = Carbon.ink[1],
            outline = Carbon.ink[3],
        )
    }
    MaterialExpressiveTheme(
        colorScheme = scheme,
        motionScheme = MotionScheme.expressive(),
        content = content,
    )
}

/** Carbon-for-mobile: 48dp is Material's floor and the phone target. */
const val TAP_TARGET_DP = 48
