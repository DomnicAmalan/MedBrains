import Foundation

/// Preconditions seeded through the real API, as the Detox suite did: a
/// registered patient with an open OPD encounter and a waiting token on the
/// doctor's queue. Seeded rather than driven through reception so a doctor
/// journey cannot fail for reception's reasons, and fresh per run so the
/// empty-note refusal is real rather than an accident of an earlier save.
enum Seed {
    static let backend = URL(string: ProcessInfo.processInfo.environment["MEDBRAINS_BASE_URL"] ?? "http://127.0.0.1:3000")!

    struct WaitingVisit { let patientId: String; let encounterId: String }

    private static func call(_ method: String, _ path: String, body: [String: Any]? = nil, token: String? = nil) -> [String: Any] {
        var req = URLRequest(url: URL(string: path, relativeTo: backend)!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("mobile-staff", forHTTPHeaderField: "X-MedBrains-Client")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try? JSONSerialization.data(withJSONObject: body) }
        let done = DispatchSemaphore(value: 0)
        var out: [String: Any] = [:]
        URLSession.shared.dataTask(with: req) { data, _, _ in
            out = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]) ?? [:]
            done.signal()
        }.resume()
        done.wait()
        return out
    }

    /// A waiting token for `doctorUsername`, registered against them as the
    /// attending so they hold access to its consultation.
    static func waitingVisit(for doctorUsername: String) -> WaitingVisit? {
        let admin = call("POST", "/api/auth/login", body: ["username": "admin", "password": "admin123"])
        guard let token = admin["token"] as? String else { return nil }
        let users = callList("GET", "/api/setup/users", token: token)
        guard let doctor = users.first(where: { ($0["username"] as? String) == doctorUsername }),
              let doctorId = doctor["id"] as? String,
              let departmentId = (doctor["department_ids"] as? [String])?.first
        else { return nil }
        let suffix = String(Int(Date().timeIntervalSince1970) % 100_000)
        let patient = call("POST", "/api/patients", body: [
            "first_name": "Seeded", "last_name": "Consult\(suffix)", "gender": "female", "phone": "98765\(suffix)",
            "date_of_birth": "1990-01-01", "is_dob_estimated": false, "registration_type": "new",
            "registration_source": "walk_in", "is_medico_legal": false, "is_vip": false,
        ], token: token)
        guard let patientId = patient["id"] as? String else { return nil }
        let visit = call("POST", "/api/opd/encounters", body: ["patient_id": patientId, "department_id": departmentId, "doctor_id": doctorId], token: token)
        guard let encounterId = (visit["encounter"] as? [String: Any])?["id"] as? String else { return nil }
        return WaitingVisit(patientId: patientId, encounterId: encounterId)
    }

    private static func callList(_ method: String, _ path: String, token: String) -> [[String: Any]] {
        var req = URLRequest(url: URL(string: path, relativeTo: backend)!)
        req.httpMethod = method
        req.setValue("mobile-staff", forHTTPHeaderField: "X-MedBrains-Client")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let done = DispatchSemaphore(value: 0)
        var out: [[String: Any]] = []
        URLSession.shared.dataTask(with: req) { data, _, _ in
            out = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [[String: Any]]) ?? []
            done.signal()
        }.resume()
        done.wait()
        return out
    }
}
