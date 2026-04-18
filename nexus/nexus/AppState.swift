import SwiftUI
import Combine
import CoreMotion

// MARK: - App State

enum AppScreen {
    case auth
    case onboarding
    case main
}

enum AppColors {
    static let background = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let lightBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
}

extension AppTheme {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

struct EdgeSheen: ViewModifier {
    let cornerRadius: CGFloat
    @ObservedObject private var motion = MotionManager.shared

    func body(content: Content) -> some View {
        let dx = CGFloat(motion.roll) / 1.2
        let dy = CGFloat(motion.pitch) / 1.2
        let start = UnitPoint(
            x: max(0, min(1, 0.5 - dx)),
            y: max(0, min(1, 0.5 - dy))
        )
        let end = UnitPoint(
            x: max(0, min(1, 0.5 + dx)),
            y: max(0, min(1, 0.5 + dy))
        )
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.18),
                            Color.clear
                        ],
                        startPoint: start,
                        endPoint: end
                    ),
                    lineWidth: 1
                )
                .blendMode(.screen)
                .blur(radius: 0.6)
        )
    }
}

extension View {
    func edgeSheen(cornerRadius: CGFloat) -> some View {
        modifier(EdgeSheen(cornerRadius: cornerRadius))
    }
}

final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    private let manager = CMMotionManager()
    @Published var roll: Double = 0
    @Published var pitch: Double = 0

    private init() {
        start()
    }

    private func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 8.0   // 8fps достаточно для плавного sheen-эффекта
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion, let self else { return }
            let newRoll  = motion.attitude.roll
            let newPitch = motion.attitude.pitch
            // Обновляем только при значимом изменении — избегаем лишних перерисовок
            if abs(newRoll - self.roll) > 0.008 || abs(newPitch - self.pitch) > 0.008 {
                self.roll  = newRoll
                self.pitch = newPitch
            }
        }
    }
}

enum AuthProvider: String, Codable {
    case apple
    case google
    case phone
    case email
}

struct AuthUser: Codable {
    var provider: AuthProvider
    var email: String?
    var phone: String?
    var fullName: String?
    var password: String?
    var appleUserId: String?
}

struct StoredUserProfile: Codable {
    var firstName: String
    var lastName: String
    var middleName: String = ""
    var username: String = ""
    var bio: String = ""
    var email: String
    var phone: String?
    var avatarData: Data?
    var birthDate: Date
    var weightKg: Double
    var heightCm: Double
    var gender: String
    var race: String = ""
    var ethnicity: String = ""
    var dietType: String = ""
    var maritalStatus: String = ""
    var country: String = ""
    var city: String = ""
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .auth
    @Published var userProfile: UserProfile?
    @Published var authUser: AuthUser?
    @Published var settings: AppSettings = AppSettings()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    static let shared = AppState()

    // Флаг: пользователь только что зарегистрировался в этой сессии.
    // Если true — catch в handleAuthChange показывает онбординг (не разлогинивает).
    var isFreshRegistration = false

    private let authManager = AuthenticationManager.shared
    private let firebase = FirebaseService.shared
    private let settingsKey = "appSettings"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        if let stored = loadSettings() {
            settings = stored
            // Применяем сохранённый язык сразу при старте
            LocalizationManager.shared.setLanguage(stored.language)
        }

        // Слушаем Firebase Auth state
        authManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.handleAuthChange(isAuthenticated: isAuthenticated)
            }
            .store(in: &cancellables)

        // Сохраняем settings локально при изменении
        $settings
            .dropFirst()
            .sink { [weak self] newSettings in
                self?.saveSettings(newSettings)
                // Обновляем LocalizationManager при смене языка
                LocalizationManager.shared.setLanguage(newSettings.language)
            }
            .store(in: &cancellables)

        // Синхронизируем settings с Firestore при изменении
        $settings
            .dropFirst()
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] newSettings in
                guard let self, let userId = self.authManager.currentUserId else { return }
                Task {
                    try? await self.firebase.userRepo.saveSettings(newSettings, userId: userId)
                }
            }
            .store(in: &cancellables)

        checkAuthState()
    }

    // MARK: - Auth State

    func checkAuthState() {
        if authManager.isAuthenticated {
            let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingDone")
            if onboardingDone {
                currentScreen = .main
                loadProfileFromFirebase()
            }
            // Если onboardingDone == false: НЕ переходим на onboarding сразу.
            // handleAuthChange (через Combine-подписку) сначала проверит Firestore
            // и только если профиля нет — покажет onboarding.
            // Так устраняется мигание формы при входе в существующий аккаунт.
        } else {
            // Fallback: проверяем legacy UserDefaults auth
            let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingDone")
            if isLoggedIn && onboardingDone {
                currentScreen = .main
                userProfile = loadUserProfile()
            } else if isLoggedIn {
                currentScreen = .onboarding
            } else {
                currentScreen = .auth
            }
        }
    }

    // Флаг для предотвращения двойного Firestore-запроса
    // (checkAuthState + handleAuthChange могут сработать одновременно при старте)
    private var isResolvingProfile = false

    private func handleAuthChange(isAuthenticated: Bool) {
        if isAuthenticated {
            let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingDone")
            if onboardingDone {
                withAnimation(.spring(response: 0.5)) { currentScreen = .main }
                loadProfileFromFirebase()
            } else {
                // Уже выполняем проверку — не запускаем повторно
                guard !isResolvingProfile else { return }
                isResolvingProfile = true

                Task {
                    defer { isResolvingProfile = false }

                    // currentUserId может кратковременно быть nil пока Firebase
                    // восстанавливает сессию — просто ждём, не показываем onboarding
                    guard let userId = authManager.currentUserId else { return }

                    do {
                        let profile = try await firebase.userRepo.fetchProfile(userId: userId)
                        userProfile = profile
                        UserDefaults.standard.set(true, forKey: "onboardingDone")
                        if let s = try? await firebase.userRepo.fetchSettings(userId: userId) {
                            var merged = s
                            merged.theme = settings.theme
                            merged.language = settings.language
                            settings = merged
                            saveSettings(merged)
                        }
                        withAnimation(.spring(response: 0.5)) { currentScreen = .main }
                    } catch {
                        if self.isFreshRegistration {
                            // Новый пользователь — профиля ещё нет, это нормально.
                            // Показываем онбординг чтобы заполнить профиль.
                            self.isFreshRegistration = false
                            withAnimation(.spring(response: 0.5)) { currentScreen = .onboarding }
                        } else {
                            // Перезапуск с незавершённой регистрацией —
                            // разлогиниваем и возвращаем на экран входа.
                            self.authManager.signOut()
                            withAnimation(.spring(response: 0.5)) { currentScreen = .auth }
                        }
                    }
                }
            }
        } else {
            isResolvingProfile = false
            withAnimation(.spring(response: 0.5)) {
                currentScreen = .auth
            }
            userProfile = nil
        }
    }

    // MARK: - Legacy Sign In (для обратной совместимости с AuthView)

    func signIn(with user: AuthUser) {
        authUser = user
        isFreshRegistration = true   // пользователь только что зарегистрировался/вошёл
        UserDefaults.standard.set(true, forKey: "isLoggedIn")

        let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingDone")
        if onboardingDone {
            // Уже был в приложении — сразу на .main
            isFreshRegistration = false
            withAnimation(.spring(response: 0.5)) { currentScreen = .main }
            loadProfileFromFirebase()
        }
        // Иначе — ждём handleAuthChange, который проверит Firestore и решит
        // показывать ли onboarding или сразу main (для существующих аккаунтов)
    }

    func registerEmail(email: String, password: String) {
        Task {
            do {
                try await authManager.signUpWithEmail(email: email, password: password)
            } catch {
                // Fallback legacy
                let user = AuthUser(provider: .email, email: email, phone: nil, fullName: nil, password: password, appleUserId: nil)
                signIn(with: user)
            }
        }
    }

    func signInEmail(email: String, password: String) -> Bool {
        Task {
            do {
                try await authManager.signInWithEmail(email: email, password: password)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
        return true
    }

    // MARK: - Onboarding

    func completeOnboarding(firstName: String, lastName: String, birthDate: Date, weightKg: Double, heightCm: Double, gender: String) {
        let userId = authManager.currentUserId ?? UUID().uuidString
        let email = authManager.firebaseUser?.email ?? authUser?.email ?? ""
        let profile = UserProfile(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            birthDate: birthDate,
            weightKg: weightKg,
            heightCm: heightCm,
            gender: gender
        )
        profile.phone = authUser?.phone
        self.userProfile = profile
        saveUserProfile(profile)
        UserDefaults.standard.set(true, forKey: "onboardingDone")

        // Сохраняем в Firestore
        Task {
            do {
                print("🔥 Saving profile to Firestore, userId: \(userId)")
                try await firebase.userRepo.saveProfile(profile, userId: userId)
                print("✅ Profile saved successfully")
                try await firebase.userRepo.saveSettings(settings, userId: userId)
                print("✅ Settings saved successfully")
            } catch {
                print("❌ Firestore save error: \(error)")
            }
        }

        withAnimation(.spring(response: 0.5)) {
            currentScreen = .main
        }
    }

    // MARK: - Sign Out

    func signOut() {
        authManager.signOut()
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "onboardingDone")
        userProfile = nil
        withAnimation(.spring(response: 0.5)) {
            currentScreen = .auth
        }
    }

    // MARK: - Refresh

    func refreshProfile() async {
        guard let userId = authManager.currentUserId else { return }
        do {
            let profile = try await firebase.userRepo.fetchProfile(userId: userId)
            self.userProfile = profile
            var remoteSettings = try await firebase.userRepo.fetchSettings(userId: userId)
            remoteSettings.theme = self.settings.theme
            remoteSettings.language = self.settings.language
            self.settings = remoteSettings
            saveSettings(remoteSettings)
        } catch {
            // Fallback to local data
        }
    }

    // MARK: - Profile Update

    func updateProfile(_ profile: UserProfile) {
        self.userProfile = profile
        saveUserProfile(profile)
        guard let userId = authManager.currentUserId else { return }
        Task {
            try? await firebase.userRepo.saveProfile(profile, userId: userId)
        }
    }

    // MARK: - Avatar

    func updateAvatar(_ data: Data?) {
        guard let profile = userProfile else { return }
        let compressed = data.flatMap { compressAvatar($0) } ?? data
        profile.avatarData = compressed
        saveUserProfile(profile)

        if let compressed, let userId = authManager.currentUserId {
            Task {
                _ = try? await firebase.userRepo.updateAvatar(compressed, userId: userId)
            }
        }
    }

    private func compressAvatar(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        let maxSize: CGFloat = 400
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.7)
    }

    // MARK: - Firebase Profile Loading

    private func loadProfileFromFirebase() {
        guard let userId = authManager.currentUserId else { return }
        Task {
            do {
                let profile = try await firebase.userRepo.fetchProfile(userId: userId)
                self.userProfile = profile
                let remoteSettings = try await firebase.userRepo.fetchSettings(userId: userId)
                self.settings = remoteSettings
                saveSettings(remoteSettings)
            } catch {
                // Fallback to local
                self.userProfile = loadUserProfile()
            }
        }
    }

    // MARK: - Local Persistence (legacy, for offline fallback)

    private func saveUserProfile(_ profile: UserProfile) {
        let stored = StoredUserProfile(
            firstName: profile.firstName,
            lastName: profile.lastName,
            middleName: profile.middleName,
            username: profile.username,
            bio: profile.bio,
            email: profile.email,
            phone: profile.phone,
            avatarData: profile.avatarData,
            birthDate: profile.birthDate,
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            gender: profile.gender,
            race: profile.race,
            ethnicity: profile.ethnicity,
            dietType: profile.dietType,
            maritalStatus: profile.maritalStatus,
            country: profile.country,
            city: profile.city
        )
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }

    private func loadUserProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let stored = try? JSONDecoder().decode(StoredUserProfile.self, from: data)
        else { return nil }
        let profile = UserProfile(
            firstName: stored.firstName,
            lastName: stored.lastName,
            middleName: stored.middleName,
            username: stored.username,
            bio: stored.bio,
            email: stored.email,
            birthDate: stored.birthDate,
            weightKg: stored.weightKg,
            heightCm: stored.heightCm,
            gender: stored.gender,
            race: stored.race,
            ethnicity: stored.ethnicity,
            dietType: stored.dietType,
            maritalStatus: stored.maritalStatus,
            country: stored.country,
            city: stored.city
        )
        profile.phone = stored.phone
        profile.avatarData = stored.avatarData
        return profile
    }

    private func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private func loadSettings() -> AppSettings? {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }
}
