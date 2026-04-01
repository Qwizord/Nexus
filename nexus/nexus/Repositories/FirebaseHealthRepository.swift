import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Firebase Health Repository

class FirebaseHealthRepository: HealthRepository {
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Fetch

    func fetchEntries(userId: String, days: Int) async throws -> [HealthEntry] {
        #if canImport(FirebaseFirestore)
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let cutoffStr = dateFormatter.string(from: cutoff)

        let snapshot = try await db.collection("health").document(userId).collection("entries")
            .whereField("dateKey", isGreaterThanOrEqualTo: cutoffStr)
            .order(by: "dateKey", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { mapToHealthEntry($0.data()) }
        #else
        throw RepositoryError.fetchFailed("Firebase not available")
        #endif
    }

    // MARK: - Save

    func saveEntry(_ entry: HealthEntry, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let dateKey = dateFormatter.string(from: entry.date)
        let data = healthEntryToFirestore(entry, dateKey: dateKey)
        try await db.collection("health").document(userId).collection("entries")
            .document(dateKey).setData(data, merge: true)
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    func saveBatch(_ entries: [HealthEntry], userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let batch = db.batch()
        for entry in entries {
            let dateKey = dateFormatter.string(from: entry.date)
            let ref = db.collection("health").document(userId).collection("entries").document(dateKey)
            let data = healthEntryToFirestore(entry, dateKey: dateKey)
            batch.setData(data, forDocument: ref, merge: true)
        }
        try await batch.commit()
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    // MARK: - Delete

    func deleteEntry(id: String, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        try await db.collection("health").document(userId).collection("entries")
            .document(id).delete()
        #else
        throw RepositoryError.deleteFailed("Firebase not available")
        #endif
    }

    // MARK: - Real-time Listener

    func listenToEntries(userId: String, days: Int) -> AsyncStream<[HealthEntry]> {
        AsyncStream { continuation in
            #if canImport(FirebaseFirestore)
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let cutoffStr = self.dateFormatter.string(from: cutoff)

            let listener = self.db.collection("health").document(userId).collection("entries")
                .whereField("dateKey", isGreaterThanOrEqualTo: cutoffStr)
                .order(by: "dateKey", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let docs = snapshot?.documents, error == nil else { return }
                    let entries = docs.compactMap { self.mapToHealthEntry($0.data()) }
                    continuation.yield(entries)
                }
            continuation.onTermination = { _ in listener.remove() }
            #else
            continuation.finish()
            #endif
        }
    }

    // MARK: - Mapping

    private func healthEntryToFirestore(_ entry: HealthEntry, dateKey: String) -> [String: Any] {
        [
            "dateKey": dateKey,
            "date": ISO8601DateFormatter().string(from: entry.date),
            "steps": entry.steps,
            "caloriesBurned": entry.caloriesBurned,
            "sleepHours": entry.sleepHours,
            "heartRateAvg": entry.heartRateAvg,
            "heartRateMin": entry.heartRateMin,
            "heartRateMax": entry.heartRateMax,
            "waterMl": entry.waterMl,
            "weight": entry.weight as Any,
            "bloodPressureSystolic": entry.bloodPressureSystolic as Any,
            "bloodPressureDiastolic": entry.bloodPressureDiastolic as Any,
            "oxygenSaturation": entry.oxygenSaturation as Any,
            "source": entry.source,
            "syncedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    private func mapToHealthEntry(_ data: [String: Any]) -> HealthEntry? {
        guard let dateStr = data["date"] as? String,
              let date = ISO8601DateFormatter().date(from: dateStr)
        else { return nil }

        let entry = HealthEntry(
            date: date,
            steps: data["steps"] as? Int ?? 0,
            caloriesBurned: data["caloriesBurned"] as? Double ?? 0,
            sleepHours: data["sleepHours"] as? Double ?? 0,
            heartRateAvg: data["heartRateAvg"] as? Int ?? 0,
            heartRateMin: data["heartRateMin"] as? Int ?? 0,
            heartRateMax: data["heartRateMax"] as? Int ?? 0,
            waterMl: data["waterMl"] as? Double ?? 0,
            source: data["source"] as? String ?? "unknown"
        )
        entry.weight = data["weight"] as? Double
        entry.bloodPressureSystolic = data["bloodPressureSystolic"] as? Int
        entry.bloodPressureDiastolic = data["bloodPressureDiastolic"] as? Int
        entry.oxygenSaturation = data["oxygenSaturation"] as? Double
        return entry
    }
}
