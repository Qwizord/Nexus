import Foundation
import Combine

// MARK: - Network Manager

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    // n8n на Beget — замени на реальный URL
    private let baseURL = "https://YOUR_N8N_DOMAIN/webhook"

    private init() {}

    // MARK: - Chat

    func sendMessage(
        content: String,
        isAgentMode: Bool,
        userId: String,
        context: ChatContext
    ) async throws -> AIResponse {
        let endpoint = isAgentMode ? "/ai-agents" : "/ai-chat"
        let url = try buildURL(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ChatRequest(
            message: content,
            userId: userId,
            isAgentMode: isAgentMode,
            context: context
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }

        guard http.statusCode == 200 else {
            if http.statusCode == 429 {
                throw NetworkError.rateLimited
            }
            throw NetworkError.serverError
        }

        return try JSONDecoder().decode(AIResponse.self, from: data)
    }

    // MARK: - Agent Detection (via n8n → Claude)

    func detectAgent(text: String) async throws -> String {
        let url = try buildURL("/ai-detect-agent")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: String] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NetworkError.serverError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let agent = json["agent"] as? String else {
            throw NetworkError.decodingError
        }

        return agent
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile) async throws {
        let url = try buildURL("/user/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "id": profile.id,
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "email": profile.email,
            "weightKg": profile.weightKg,
            "heightCm": profile.heightCm,
            "birthDate": ISO8601DateFormatter().string(from: profile.birthDate)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Health sync

    func syncHealthData(_ entries: [HealthEntry], userId: String) async throws {
        let url = try buildURL("/health/sync")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = entries.map { e in
            [
                "date": ISO8601DateFormatter().string(from: e.date),
                "steps": e.steps,
                "calories": e.caloriesBurned,
                "sleep": e.sleepHours,
                "heartRate": e.heartRateAvg
            ] as [String: Any]
        }

        let body: [String: Any] = ["userId": userId, "data": payload]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Health Analysis (n8n → Claude)

    func analyzeHealth(userId: String, days: Int) async throws -> AIResponse {
        let url = try buildURL("/health-analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = ["userId": userId, "lastDays": days]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NetworkError.serverError
        }
        return try JSONDecoder().decode(AIResponse.self, from: data)
    }

    // MARK: - Finance Analysis

    func analyzeFinance(userId: String, month: String) async throws -> AIResponse {
        let url = try buildURL("/finance-analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = ["userId": userId, "month": month]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NetworkError.serverError
        }
        return try JSONDecoder().decode(AIResponse.self, from: data)
    }

    // MARK: - Helpers

    private func buildURL(_ endpoint: String) throws -> URL {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        return url
    }
}

// MARK: - Request / Response Models

struct ChatRequest: Codable {
    let message: String
    let userId: String
    let isAgentMode: Bool
    let context: ChatContext
}

struct ChatContext: Codable {
    var steps: Int?
    var sleep: Double?
    var calories: Double?
    var balance: Double?
    var recentTransactions: [String]?
    var weight: Double?
    var bloodPressure: String?
    var oxygenSaturation: Double?

    static var empty: ChatContext { ChatContext() }
}

struct AIResponse: Codable {
    let reply: String
    let detectedAgent: String?
    let suggestions: [String]?
}

// MARK: - Errors

enum NetworkError: LocalizedError {
    case serverError
    case noInternet
    case timeout
    case unknown
    case invalidURL
    case decodingError
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .serverError: return "Ошибка сервера. Попробуй позже."
        case .noInternet: return "Нет интернета."
        case .timeout: return "Сервер не отвечает."
        case .unknown: return "Неизвестная ошибка."
        case .invalidURL: return "Неверный адрес сервера."
        case .decodingError: return "Ошибка обработки ответа."
        case .rateLimited: return "Слишком много запросов. Подожди."
        }
    }
}
