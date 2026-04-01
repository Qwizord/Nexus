import Foundation

// MARK: - AI Agent Detection Service
// Определяет тип агента через n8n endpoint (Claude API на сервере)

final class AIAgentDetectionService {
    static let shared = AIAgentDetectionService()

    private let networkManager = NetworkManager.shared
    private var cache: [String: AgentType] = [:]

    private init() {}

    // MARK: - Detect Agent

    /// Определяет тип агента для сообщения.
    /// Сначала проверяет локальный кэш и ключевые слова,
    /// потом отправляет на n8n для точного определения через Claude.
    func detectAgent(for text: String) async -> AgentType {
        let lower = text.lowercased()

        // Проверяем кэш
        if let cached = cache[lower] { return cached }

        // Локальная детекция по ключевым словам (быстрая)
        let localResult = detectLocally(lower)

        // Пробуем серверную детекцию через n8n
        if let serverResult = try? await detectViaServer(text) {
            cache[lower] = serverResult
            return serverResult
        }

        // Fallback на локальную
        cache[lower] = localResult
        return localResult
    }

    // MARK: - Local Detection

    private func detectLocally(_ text: String) -> AgentType {
        let healthKeywords = ["сплю", "здоров", "пульс", "шаги", "калор", "сон", "вес",
                              "давлен", "кислород", "серд", "трениров", "активн",
                              "sleep", "health", "heart", "steps", "weight"]
        let financeKeywords = ["расход", "доход", "деньги", "финанс", "бюджет", "зарплат",
                               "эконом", "инвести", "сбереж", "кредит", "долг",
                               "money", "finance", "budget", "salary"]
        let learningKeywords = ["учеб", "курс", "обучен", "план", "навык", "урок",
                                "знани", "книг", "экзамен", "лекц", "практик",
                                "learn", "course", "study", "skill"]

        let healthScore = healthKeywords.filter { text.contains($0) }.count
        let financeScore = financeKeywords.filter { text.contains($0) }.count
        let learningScore = learningKeywords.filter { text.contains($0) }.count

        let maxScore = max(healthScore, financeScore, learningScore)
        if maxScore == 0 { return .general }

        if healthScore == maxScore { return .health }
        if financeScore == maxScore { return .finance }
        return .learning
    }

    // MARK: - Server Detection (via n8n → Claude)

    private func detectViaServer(_ text: String) async throws -> AgentType? {
        let response = try await networkManager.detectAgent(text: text)
        return AgentType(rawValue: response)
    }

    // MARK: - Cache

    func clearCache() {
        cache.removeAll()
    }
}
