package com.medbrains.kit

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/** Keys the shell keeps in the Keystore-backed store. Mirrors mobile-shell's SECRET_KEYS. */
enum class SecretKey(val id: String) {
    JWT("medbrains.jwt"),
    REFRESH_TOKEN("medbrains.refresh_token"),
    NODE_SECRET("medbrains.node_secret"),
    CAMP_KEY("medbrains.camp_key"),
}

/**
 * Secrets encrypted with an Android Keystore master key (AES-256-GCM), never
 * plain SharedPreferences. The React Native shell kept the JWT in the
 * Keystore; a token that lives for weeks on hardware that gets lost or lent
 * must not be easier to reach natively.
 */
class SecretStore(context: Context, name: String = "medbrains.secrets") {
    private val prefs = EncryptedSharedPreferences.create(
        context,
        name,
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    fun read(key: SecretKey): String? = prefs.getString(key.id, null)

    fun write(key: SecretKey, value: String) {
        prefs.edit().putString(key.id, value).apply()
    }

    fun delete(key: SecretKey) {
        prefs.edit().remove(key.id).apply()
    }
}
