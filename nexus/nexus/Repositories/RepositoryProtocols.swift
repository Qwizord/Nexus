import Foundation

// MARK: - Repository Protocols
// Слой абстракции между ViewModels и источниками данных (Firestore, HealthKit, n8n)

// MARK: - User Repository

protocol UserRepository {
    func fetchProfile(userId: String) async throws -> UserProfile
    func saveProfile(_ profile: UserProfile, userId: String) async throws
    func updateAvatar(_ imageData: Data, userId: String) async throws -> String
    func saveSettings(_ settings: AppSettings, userId: String) async throws
    func fetchSettings(userId: String) async throws -> AppSettings
    func listenToProfile(userId: String) -> AsyncStream<UserProfile>
}

// MARK: - Health Repository

protocol HealthRepository {
    func fetchEntries(userId: String, days: Int) async throws -> [HealthEntry]
    func saveEntry(_ entry: HealthEntry, userId: String) async throws
    func saveBatch(_ entries: [HealthEntry], userId: String) async throws
    func listenToEntries(userId: String, days: Int) -> AsyncStream<[HealthEntry]>
    func deleteEntry(id: String, userId: String) async throws
}

// MARK: - Finance Repository

protocol FinanceRepository {
    func fetchTransactions(userId: String, month: String?) async throws -> [Transaction]
    func saveTransaction(_ transaction: Transaction, userId: String) async throws
    func deleteTransaction(id: String, userId: String) async throws
    func fetchBalance(userId: String) async throws -> Double
}

// MARK: - Learning Repository

protocol LearningRepository {
    func fetchCourses(userId: String) async throws -> [Course]
    func saveCourse(_ course: Course, userId: String) async throws
    func updateProgress(courseId: String, completedLessons: Int, userId: String) async throws
    func deleteCourse(id: String, userId: String) async throws
}

// MARK: - Chat Repository

protocol ChatRepository {
    func fetchSessions(userId: String) async throws -> [ChatSession]
    func fetchMessages(sessionId: String, userId: String, limit: Int) async throws -> [ChatMessageItem]
    func saveMessage(_ message: ChatMessageItem, sessionId: String, userId: String) async throws
    func createSession(_ session: ChatSession, userId: String) async throws
    func deleteSession(id: String, userId: String) async throws
    func clearAllSessions(userId: String) async throws
    func listenToMessages(sessionId: String, userId: String) -> AsyncStream<[ChatMessageItem]>
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case unauthorized
    case networkUnavailable
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .notFound: return "Данные не найдены."
        case .saveFailed(let detail): return "Ошибка сохранения: \(detail)"
        case .fetchFailed(let detail): return "Ошибка загрузки: \(detail)"
        case .deleteFailed(let detail): return "Ошибка удаления: \(detail)"
        case .unauthorized: return "Нет доступа. Войдите в аккаунт."
        case .networkUnavailable: return "Нет подключения к интернету."
        case .quotaExceeded: return "Превышен лимит запросов."
        }
    }
}
