import Foundation
import SwiftUI
import Combine
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Firebase Service (Singleton)
// Центральная точка доступа ко всем Firebase-зависимым компонентам

final class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    // Repositories
    let userRepo: UserRepository
    let healthRepo: HealthRepository
    let chatRepo: ChatRepository
    let financeRepo: FinanceRepository
    let learningRepo: LearningRepository

    // Current user ID from Firebase Auth
    @Published var currentUserId: String?

    private init() {
        self.userRepo = FirebaseUserRepository()
        self.healthRepo = FirebaseHealthRepository()
        self.chatRepo = FirebaseChatRepository()
        self.financeRepo = FirebaseFinanceRepository()
        self.learningRepo = FirebaseLearningRepository()

        #if canImport(FirebaseAuth)
        setupAuthListener()
        #endif
    }

    // MARK: - Auth Listener

    #if canImport(FirebaseAuth)
    private func setupAuthListener() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUserId = user?.uid
            }
        }
    }
    #endif

    // MARK: - Convenience

    var isAuthenticated: Bool {
        currentUserId != nil
    }

    func requireUserId() throws -> String {
        guard let id = currentUserId else {
            throw RepositoryError.unauthorized
        }
        return id
    }
}
