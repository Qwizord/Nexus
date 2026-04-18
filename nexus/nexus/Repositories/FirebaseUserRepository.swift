import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Firebase User Repository

class FirebaseUserRepository: UserRepository {
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif

    // MARK: - Profile

    func fetchProfile(userId: String) async throws -> UserProfile {
        #if canImport(FirebaseFirestore)
        let doc = try await db.collection("users").document(userId).collection("data").document("profile").getDocument()
        guard let data = doc.data() else { throw RepositoryError.notFound }
        return try mapToUserProfile(data, userId: userId)
        #else
        throw RepositoryError.fetchFailed("Firebase not available")
        #endif
    }

    func saveProfile(_ profile: UserProfile, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let data = profileToFirestore(profile)
        try await db.collection("users").document(userId).collection("data").document("profile").setData(data, merge: true)
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    func updateAvatar(_ imageData: Data, userId: String) async throws -> String {
        #if canImport(FirebaseFirestore)
        let base64 = imageData.base64EncodedString()
        try await db.collection("users").document(userId).collection("data").document("profile").setData(["avatarBase64": base64], merge: true)
        return base64
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    // MARK: - Settings

    func saveSettings(_ settings: AppSettings, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let data = settingsToFirestore(settings)
        try await db.collection("users").document(userId).collection("data").document("settings").setData(data, merge: true)
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    func fetchSettings(userId: String) async throws -> AppSettings {
        #if canImport(FirebaseFirestore)
        let doc = try await db.collection("users").document(userId).collection("data").document("settings").getDocument()
        guard let data = doc.data() else { return AppSettings() }
        return mapToAppSettings(data)
        #else
        throw RepositoryError.fetchFailed("Firebase not available")
        #endif
    }

    // MARK: - Real-time Listener

    func listenToProfile(userId: String) -> AsyncStream<UserProfile> {
        AsyncStream { continuation in
            #if canImport(FirebaseFirestore)
            let listener = db.collection("users").document(userId).collection("data").document("profile")
                .addSnapshotListener { snapshot, error in
                    guard let data = snapshot?.data(), error == nil else { return }
                    if let profile = try? self.mapToUserProfile(data, userId: userId) {
                        continuation.yield(profile)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
            #else
            continuation.finish()
            #endif
        }
    }

    // MARK: - Mapping

    private func profileToFirestore(_ profile: UserProfile) -> [String: Any] {
        var data: [String: Any] = [
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "middleName": profile.middleName,
            "username": profile.username,
            "bio": profile.bio,
            "email": profile.email,
            "birthDate": ISO8601DateFormatter().string(from: profile.birthDate),
            "weightKg": profile.weightKg,
            "heightCm": profile.heightCm,
            "gender": profile.gender,
            "race": profile.race,
            "ethnicity": profile.ethnicity,
            "dietType": profile.dietType,
            "maritalStatus": profile.maritalStatus,
            "country": profile.country,
            "city": profile.city,
            "createdAt": ISO8601DateFormatter().string(from: profile.createdAt),
            "subscriptionActive": profile.subscriptionActive
        ]
        if let phone = profile.phone { data["phone"] = phone }
        return data
    }

    private func mapToUserProfile(_ data: [String: Any], userId: String) throws -> UserProfile {
        let profile = UserProfile(
            id: userId,
            firstName: data["firstName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            middleName: data["middleName"] as? String ?? "",
            username: data["username"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            email: data["email"] as? String ?? "",
            birthDate: parseDate(data["birthDate"] as? String),
            weightKg: data["weightKg"] as? Double ?? 70,
            heightCm: data["heightCm"] as? Double ?? 175,
            gender: data["gender"] as? String ?? "Не указан",
            race: data["race"] as? String ?? "",
            ethnicity: data["ethnicity"] as? String ?? "",
            dietType: data["dietType"] as? String ?? "",
            maritalStatus: data["maritalStatus"] as? String ?? "",
            country: data["country"] as? String ?? "",
            city: data["city"] as? String ?? ""
        )
        profile.phone = data["phone"] as? String
        profile.subscriptionActive = data["subscriptionActive"] as? Bool ?? false
        if let base64 = data["avatarBase64"] as? String {
            profile.avatarData = Data(base64Encoded: base64)
        }
        return profile
    }

    private func settingsToFirestore(_ settings: AppSettings) -> [String: Any] {
        [
            "theme": settings.theme.rawValue,
            "language": settings.language,
            "measurementSystem": settings.measurementSystem.rawValue,
            "timezone": settings.timezone,
            "notificationsEnabled": settings.notificationsEnabled,
            "healthKitConnected": settings.healthKitConnected,
            "ouraConnected": settings.ouraConnected,
            "garminConnected": settings.gaminConnected,
            "whoopConnected": settings.whoopConnected,
            "currency": settings.currency,
            "spotlightEnabled": settings.spotlightEnabled,
            "calendarEnabled": settings.calendarEnabled,
            "iCloudEnabled": settings.iCloudEnabled,
            "faceIDEnabled": settings.faceIDEnabled
        ]
    }

    private func mapToAppSettings(_ data: [String: Any]) -> AppSettings {
        var settings = AppSettings()
        if let theme = data["theme"] as? String,
           let appTheme = AppTheme(rawValue: theme) {
            settings.theme = appTheme
        }
        settings.language = data["language"] as? String ?? "ru_RU"
        if let ms = data["measurementSystem"] as? String,
           let sys = MeasurementSystem(rawValue: ms) {
            settings.measurementSystem = sys
        }
        settings.timezone = data["timezone"] as? String ?? "Europe/Moscow"
        settings.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
        settings.healthKitConnected = data["healthKitConnected"] as? Bool ?? false
        settings.ouraConnected = data["ouraConnected"] as? Bool ?? false
        settings.gaminConnected = data["garminConnected"] as? Bool ?? false
        settings.whoopConnected = data["whoopConnected"] as? Bool ?? false
        settings.currency = data["currency"] as? String ?? "RUB"
        settings.spotlightEnabled = data["spotlightEnabled"] as? Bool ?? true
        settings.calendarEnabled = data["calendarEnabled"] as? Bool ?? false
        settings.iCloudEnabled = data["iCloudEnabled"] as? Bool ?? false
        settings.faceIDEnabled = data["faceIDEnabled"] as? Bool ?? false
        return settings
    }

    private func parseDate(_ string: String?) -> Date {
        guard let string else { return Date() }
        return ISO8601DateFormatter().date(from: string) ?? Date()
    }
}
