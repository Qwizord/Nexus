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

    // MARK: - Email Verification Code

    // Resend API key — получи бесплатно на resend.com (100 писем/день free tier)
    // Вставь свой ключ сюда:
    private let resendApiKey = "re_ВСТАВЬ_СВОЙ_КЛЮЧ"
    // Домен отправителя — пока используем тестовый onboarding@resend.dev
    // (работает без верификации домена, но только на адреса из аккаунта Resend)
    // Для отправки на любой адрес — добавь свой домен в resend.com/domains
    private let senderEmail = "Nexus <onboarding@resend.dev>"

    /// Отправляет 6-значный код подтверждения через Resend API.
    /// Fallback: если ключ не вставлен — пытается отправить через n8n.
    func sendVerificationCode(email: String, code: String) async {
        // Если Resend ключ вставлен — используем его
        if !resendApiKey.hasPrefix("re_ВСТАВЬ") {
            await sendViaResend(email: email, code: code)
            return
        }
        // Fallback: n8n (если настроен)
        if !baseURL.contains("YOUR_N8N") {
            guard let url = try? buildURL("/send-verification-code") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            let body = ["email": email, "code": code, "appName": "Nexus"]
            request.httpBody = try? JSONEncoder().encode(body)
            _ = try? await URLSession.shared.data(for: request)
        }
        // Если ничего не настроено — код доступен только в консоли (DEBUG)
        print("⚠️ Email не отправлен: вставь Resend API ключ в NetworkManager.swift")
    }

    private func sendViaResend(email: String, code: String) async {
        guard let url = URL(string: "https://api.resend.com/emails") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resendApiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let subject = "Ваш код подтверждения Nexus"
        let textBody = """
        Ваш код подтверждения: \(code)

        Код действителен 10 минут.
        Если вы не регистрировались в Nexus — просто проигнорируйте это письмо.
        """
        let htmlBody = """
        <div style="font-family:-apple-system,sans-serif;max-width:400px;margin:40px auto;padding:32px;background:#111;border-radius:16px;color:#fff">
          <h2 style="margin:0 0 8px;font-size:24px">Nexus</h2>
          <p style="color:#aaa;margin:0 0 32px;font-size:14px">Подтверждение email</p>
          <div style="background:#1e1e2e;border-radius:12px;padding:24px;text-align:center;margin-bottom:24px">
            <p style="margin:0 0 8px;color:#aaa;font-size:13px">Ваш код подтверждения</p>
            <p style="margin:0;font-size:40px;font-weight:700;letter-spacing:8px;color:#fff">\(code)</p>
          </div>
          <p style="color:#666;font-size:12px;text-align:center;margin:0">Код действителен 10 минут</p>
        </div>
        """

        let body: [String: Any] = [
            "from": senderEmail,
            "to": [email],
            "subject": subject,
            "text": textBody,
            "html": htmlBody
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    print("✅ Код отправлен на \(email) через Resend")
                } else {
                    let msg = String(data: data, encoding: .utf8) ?? "?"
                    print("❌ Resend ошибка \(http.statusCode): \(msg)")
                }
            }
        } catch {
            print("❌ Resend сетевая ошибка: \(error)")
        }
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
