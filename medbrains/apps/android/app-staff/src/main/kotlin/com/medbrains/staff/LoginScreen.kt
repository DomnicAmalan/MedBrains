package com.medbrains.staff

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.medbrains.kit.AuthStore
import kotlinx.coroutines.launch

/**
 * Sign-in the Material way: labelled outlined fields, the IME action advancing
 * username → password → submit, the keyboard never covering the button
 * (imePadding), an inline error that says what to do, one filled action.
 */
@Composable
fun LoginScreen(auth: AuthStore) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var signingIn by remember { mutableStateOf(false) }
    val error by auth.lastError.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val passwordFocus = remember { FocusRequester() }

    fun submit() {
        if (username.isBlank() || password.isBlank() || signingIn) return
        signingIn = true
        scope.launch {
            auth.signIn(username.trim(), password)
            signingIn = false
        }
    }

    Column(
        modifier = Modifier.fillMaxSize().safeDrawingPadding().imePadding().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("MedBrains", style = MaterialTheme.typography.displaySmall)
        Text("Sign in", style = MaterialTheme.typography.titleMedium)
        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            label = { Text("Username or email") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next),
            keyboardActions = KeyboardActions(onNext = { passwordFocus.requestFocus() }),
            modifier = Modifier.fillMaxWidth().testTag("username"),
        )
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, imeAction = ImeAction.Go),
            keyboardActions = KeyboardActions(onGo = { submit() }),
            isError = error != null,
            supportingText = error?.let { { Text(it) } },
            modifier = Modifier.fillMaxWidth().focusRequester(passwordFocus).testTag("password"),
        )
        Button(
            onClick = { submit() },
            enabled = username.isNotBlank() && password.isNotBlank() && !signingIn,
            modifier = Modifier.fillMaxWidth().testTag("signIn"),
        ) {
            Text(if (signingIn) "Signing in…" else "Sign in")
        }
    }
}
