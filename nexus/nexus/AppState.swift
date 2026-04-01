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
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            self?.roll = motion.attitude.roll
            self?.pitch = motion.attitude.pitch
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
    var email: String
    var phone: String?
    var avatarData: Data?
    var birthDate: Date
    var weightKg: Double
    var heightCm: Double
    var gender: String
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

    private let authManager = AuthenticationManager.shared
    private let firebase = FirebaseService.shared
    private let settingsKey = "appSettings"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        if let stored = loadSettings() {
            settings = stored
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
            .sink { [weak self] in self?.saveSettings($0) }
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
            } else {
                currentScreen = .onboarding
            }
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

    private func handleAuthChange(isAuthenticated: Bool) {
        if isAuthenticated {
            let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingDone")
            withAnimation(.spring(response: 0.5)) {
                currentScreen = onboardingDone ? .main : .onboarding
            }
            if onboardingDone {
                loadProfileFromFirebase()
            }
        } else {
            withAnimation(.spring(response: 0.5)) {
                currentScreen = .auth
            }
            userProfile = nil
        }
    }

    // MARK: - Legacy Sign In (для обратной совместимости с AuthView)

    func signIn(with user: AuthUser) {
        authUser = user
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingDone")
        withAnimation(.spring(response: 0.5)) {
            currentScreen = onboardingDone ? .main : .onboarding
        }
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
            try? await firebase.userRepo.saveProfile(profile, userId: userId)
            try? await firebase.userRepo.saveSettings(settings, userId: userId)
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

    // MARK: - Avatar

    func updateAvatar(_ data: Data?) {
        guard let profile = userProfile else { return }
        profile.avatarData = data
        saveUserProfile(profile)

        // Синхронизируем с Firestore
        if let data, let userId = authManager.currentUserId {
            Task {
                _ = try? await firebase.userRepo.updateAvatar(data, userId: userId)
            }
        }
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
            email: profile.email,
            phone: profile.phone,
            avatarData: profile.avatarData,
            birthDate: profile.birthDate,
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            gender: profile.gender
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
            email: stored.email,
            birthDate: stored.birthDate,
            weightKg: stored.weightKg,
            heightCm: stored.heightCm,
            gender: stored.gender
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
