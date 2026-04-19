import Foundation
import SwiftUI
import Combine
import AuthenticationServices
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

// MARK: - Authentication Manager

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var firebaseUser: FirebaseUserInfo?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateHandle: Any?

    private init() {
        setupAuthStateListener()
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        #if canImport(FirebaseAuth)
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user {
                    self?.firebaseUser = FirebaseUserInfo(
                        uid: user.uid,
                        email: user.email,
                        displayName: user.displayName,
                        photoURL: user.photoURL?.absoluteString
                    )
                    self?.isAuthenticated = true
                } else {
                    self?.firebaseUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
        #endif
    }

    // MARK: - Email / Password

    func signUpWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if canImport(FirebaseAuth)
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.firebaseUser = FirebaseUserInfo(
                uid: result.user.uid,
                email: result.user.email,
                displayName: nil,
                photoURL: nil
            )
            self.isAuthenticated = true

            // Создаём профиль в Firestore
            let profile = UserProfile(
                id: result.user.uid,
                firstName: "",
                lastName: "",
                email: email
            )
            try await FirebaseService.shared.userRepo.saveProfile(profile, userId: result.user.uid)
        } catch {
            self.errorMessage = mapFirebaseError(error)
            throw error
        }
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if canImport(FirebaseAuth)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.firebaseUser = FirebaseUserInfo(
                uid: result.user.uid,
                email: result.user.email,
                displayName: result.user.displayName,
                photoURL: result.user.photoURL?.absoluteString
            )
            self.isAuthenticated = true
        } catch {
            self.errorMessage = mapFirebaseError(error)
            throw error
        }
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws {
        #if canImport(GoogleSignIn) && canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationError
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.tokenMissing
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            self.firebaseUser = FirebaseUserInfo(
                uid: authResult.user.uid,
                email: authResult.user.email,
                displayName: authResult.user.displayName,
                photoURL: authResult.user.photoURL?.absoluteString
            )
            self.isAuthenticated = true

            // Сохраняем профиль если он новый
            await saveProfileIfNew(authResult.user)
        } catch {
            self.errorMessage = mapFirebaseError(error)
            throw error
        }
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Apple Sign In

    func signInWithApple(authorization: ASAuthorization, nonce: String) async throws {
        #if canImport(FirebaseAuth)
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.tokenMissing
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        do {
            let result = try await Auth.auth().signIn(with: credential)

            var displayName: String?
            if let fullName = appleIDCredential.fullName {
                let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
                if !parts.isEmpty { displayName = parts.joined(separator: " ") }
            }

            self.firebaseUser = FirebaseUserInfo(
                uid: result.user.uid,
                email: result.user.email ?? appleIDCredential.email,
                displayName: displayName ?? result.user.displayName,
                photoURL: result.user.photoURL?.absoluteString
            )
            self.isAuthenticated = true

            await saveProfileIfNew(result.user, displayName: displayName)
        } catch {
            self.errorMessage = mapFirebaseError(error)
            throw error
        }
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Sign Out

    func signOut() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
        firebaseUser = nil
        isAuthenticated = false
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        #if canImport(FirebaseAuth)
        try await Auth.auth().sendPasswordReset(withEmail: email)
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Change Email

    func changeEmail(newEmail: String, currentPassword: String) async throws {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw AuthError.unknownError
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Change Password

    func changePassword(currentPassword: String, newPassword: String) async throws {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw AuthError.unknownError
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: newPassword)
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Linked Providers

    var linkedProviders: [String] {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
        #else
        return []
        #endif
    }

    var hasEmailProvider: Bool { linkedProviders.contains("password") }
    var hasAppleProvider: Bool { linkedProviders.contains("apple.com") }
    var hasGoogleProvider: Bool { linkedProviders.contains("google.com") }
    var hasPhoneProvider: Bool { linkedProviders.contains("phone") }

    var linkedPhoneNumber: String? {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.providerData
            .first(where: { $0.providerID == "phone" })?.phoneNumber
        #else
        return nil
        #endif
    }

    var linkedEmailAddress: String? {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.email
        #else
        return nil
        #endif
    }

    // MARK: - Unlink Provider

    /// Отвязывает провайдер от текущего аккаунта. Firebase запрещает оставить
    /// пользователя без единого способа входа — проверяем заранее.
    func unlink(providerID: String) async throws {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw AuthError.unknownError
        }
        guard linkedProviders.count > 1 else {
            throw AuthError.cannotUnlinkLastProvider
        }
        _ = try await user.unlink(fromProvider: providerID)
        // Обновляем опубликованный firebaseUser, чтобы UI перерисовался
        if let updated = Auth.auth().currentUser {
            self.firebaseUser = FirebaseUserInfo(
                uid: updated.uid,
                email: updated.email,
                displayName: updated.displayName,
                photoURL: updated.photoURL?.absoluteString
            )
        }
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    // MARK: - Link Providers (attach to existing account)

    #if canImport(FirebaseAuth)
    /// Линкует Google-аккаунт к текущему пользователю.
    func linkGoogle() async throws {
        #if canImport(GoogleSignIn) && canImport(FirebaseCore)
        guard let user = Auth.auth().currentUser else { throw AuthError.unknownError }
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationError
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.tokenMissing
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        _ = try await user.link(with: credential)
        #else
        throw AuthError.firebaseNotAvailable
        #endif
    }

    /// Линкует Apple-аккаунт к текущему пользователю.
    func linkApple(authorization: ASAuthorization, nonce: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.unknownError }
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.tokenMissing
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        _ = try await user.link(with: credential)
    }
    #endif

    // MARK: - Phone Auth

    #if canImport(FirebaseAuth)
    /// Шаг 1: отправить SMS-код на номер телефона
    func sendPhoneVerification(phone: String) async throws -> String {
        let verificationId = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phone, uiDelegate: nil)
        return verificationId
    }

    /// Шаг 2: привязать телефон к текущему аккаунту по коду из SMS
    func linkPhone(verificationId: String, code: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: code
        )
        // Если телефон уже привязан — обновляем (unlink + link)
        if hasPhoneProvider {
            _ = try await user.unlink(fromProvider: "phone")
        }
        _ = try await user.link(with: credential)
    }
    #endif

    // MARK: - Helpers

    var currentUserId: String? {
        firebaseUser?.uid
    }

    #if canImport(FirebaseAuth)
    private func saveProfileIfNew(_ user: User, displayName: String? = nil) async {
        let userId = user.uid
        do {
            _ = try await FirebaseService.shared.userRepo.fetchProfile(userId: userId)
        } catch {
            let name = displayName ?? user.displayName ?? ""
            let parts = name.split(separator: " ")
            let profile = UserProfile(
                id: userId,
                firstName: parts.first.map(String.init) ?? "",
                lastName: parts.dropFirst().joined(separator: " "),
                email: user.email ?? ""
            )
            try? await FirebaseService.shared.userRepo.saveProfile(profile, userId: userId)
        }
    }
    #endif

    private func mapFirebaseError(_ error: Error) -> String {
        #if canImport(FirebaseAuth)
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Неверный пароль."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Неверный формат email."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Этот email уже используется."
        case AuthErrorCode.weakPassword.rawValue:
            return "Пароль слишком простой (минимум 6 символов)."
        case AuthErrorCode.userNotFound.rawValue:
            return "Пользователь не найден."
        case AuthErrorCode.networkError.rawValue:
            return "Ошибка сети. Проверьте подключение."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Слишком много попыток. Подождите."
        default:
            return "Ошибка авторизации: \(error.localizedDescription)"
        }
        #else
        return error.localizedDescription
        #endif
    }

    // MARK: - Nonce generation for Apple Sign In

    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
}

// MARK: - Firebase User Info

struct FirebaseUserInfo: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case firebaseNotAvailable
    case configurationError
    case noRootViewController
    case tokenMissing
    case unknownError
    case cannotUnlinkLastProvider

    var errorDescription: String? {
        switch self {
        case .firebaseNotAvailable: return "Firebase недоступен."
        case .configurationError: return "Ошибка конфигурации."
        case .noRootViewController: return "Не удалось открыть окно авторизации."
        case .tokenMissing: return "Не удалось получить токен."
        case .unknownError: return "Неизвестная ошибка авторизации."
        case .cannotUnlinkLastProvider: return "Нельзя отключить последний способ входа — иначе ты потеряешь доступ к аккаунту."
        }
    }
}
