package com.medbrains.staff

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.medbrains.kit.ApiClient
import com.medbrains.kit.AuthState
import com.medbrains.kit.AuthStore
import com.medbrains.kit.SecretStore
import com.medbrains.ui.MedBrainsTheme

/**
 * The staff app: sign in, then one destination per module the signed-in
 * role may see, in registry order. Everything the shell does (secrets,
 * bearer client, gating) lives in :kit so the patient, camp and vendor apps
 * reuse it unchanged.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val secrets = SecretStore(applicationContext)
        val client = ApiClient(baseUrl = AppConfig.baseUrl(intent), variant = "staff", secrets = secrets)
        val auth = AuthStore(applicationContext, client, secrets)
        setContent {
            MedBrainsTheme {
                Root(auth = auth, initialModule = intent?.getStringExtra("module"))
            }
        }
    }
}

/**
 * Where the hospital lives. `adb shell am start ... --es baseUrl http://10.0.2.2:3000`
 * overrides (emulator runs and UI tests); the default is the emulator's host loopback.
 */
object AppConfig {
    fun baseUrl(intent: android.content.Intent?): String =
        intent?.getStringExtra("baseUrl") ?: "http://10.0.2.2:3000"
}

@Composable
private fun Root(auth: AuthStore, initialModule: String?) {
    val state by auth.state.collectAsStateWithLifecycle()
    LaunchedEffect(Unit) { auth.hydrate() }
    when (val s = state) {
        AuthState.Hydrating -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        AuthState.SignedOut -> LoginScreen(auth)
        is AuthState.SignedIn -> ModuleHome(auth = auth, identity = s.identity, modules = StaffModules.registry, initialModule = initialModule)
    }
}
