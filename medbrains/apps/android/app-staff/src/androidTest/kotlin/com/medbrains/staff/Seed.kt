package com.medbrains.staff

import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Preconditions seeded through the real API, as the Detox suite did: a
 * waiting token on the doctor's queue, fresh per run so the empty-note
 * refusal is real rather than an accident of an earlier save.
 */
object Seed {
    private const val BACKEND = "http://10.0.2.2:3000"

    data class WaitingVisit(val patientId: String, val encounterId: String)

    private fun call(method: String, path: String, body: JSONObject? = null, token: String? = null): String {
        val c = URL(BACKEND + path).openConnection() as HttpURLConnection
        c.requestMethod = method
        c.setRequestProperty("Content-Type", "application/json")
        c.setRequestProperty("X-MedBrains-Client", "mobile-staff")
        token?.let { c.setRequestProperty("Authorization", "Bearer $it") }
        if (body != null) { c.doOutput = true; c.outputStream.use { it.write(body.toString().toByteArray()) } }
        return (if (c.responseCode < 400) c.inputStream else c.errorStream).bufferedReader().readText()
    }

    fun waitingVisit(doctorUsername: String): WaitingVisit? {
        val token = JSONObject(call("POST", "/api/auth/login", JSONObject().put("username", "admin").put("password", "admin123"))).optString("token").ifEmpty { return null }
        val users = JSONArray(call("GET", "/api/setup/users", token = token))
        val doctor = (0 until users.length()).map { users.getJSONObject(it) }.firstOrNull { it.optString("username") == doctorUsername } ?: return null
        val departmentId = doctor.optJSONArray("department_ids")?.optString(0)?.ifEmpty { null } ?: return null
        val suffix = (System.currentTimeMillis() / 1000 % 100_000).toString()
        val patient = JSONObject(call("POST", "/api/patients", JSONObject()
            .put("first_name", "Seeded").put("last_name", "Consult$suffix").put("gender", "female").put("phone", "98765$suffix")
            .put("date_of_birth", "1990-01-01").put("is_dob_estimated", false).put("registration_type", "new")
            .put("registration_source", "walk_in").put("is_medico_legal", false).put("is_vip", false), token))
        val patientId = patient.optString("id").ifEmpty { return null }
        val visit = JSONObject(call("POST", "/api/opd/encounters", JSONObject().put("patient_id", patientId).put("department_id", departmentId).put("doctor_id", doctor.getString("id")), token))
        val encounterId = visit.optJSONObject("encounter")?.optString("id")?.ifEmpty { null } ?: return null
        return WaitingVisit(patientId, encounterId)
    }
}
