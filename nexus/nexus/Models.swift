import Foundation
import Combine

// MARK: - User

class UserProfile: Codable, ObservableObject {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var avatarData: Data?
    var birthDate: Date
    var weightKg: Double
    var heightCm: Double
    var gender: String
    var createdAt: Date
    var subscriptionActive: Bool

    init(id: String = UUID().uuidString,
         firstName: String = "",
         lastName: String = "",
         email: String = "",
         birthDate: Date = Date(),
         weightKg: Double = 70,
         heightCm: Double = 175,
         gender: String = "Не указан") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.birthDate = birthDate
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.gender = gender
        self.createdAt = Date()
        self.subscriptionActive = false
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }
}

// MARK: - Health

class HealthEntry: Codable {
    var id: String
    var date: Date
    var steps: Int
    var caloriesBurned: Double
    var sleepHours: Double
    var heartRateAvg: Int
    var heartRateMin: Int
    var heartRateMax: Int
    var waterMl: Double
    var weight: Double?
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var oxygenSaturation: Double?
    var source: String

    init(date: Date = Date(), steps: Int = 0, caloriesBurned: Double = 0,
         sleepHours: Double = 0, heartRateAvg: Int = 0,
         heartRateMin: Int = 0, heartRateMax: Int = 0,
         waterMl: Double = 0, source: String = "Apple Health") {
        self.id = UUID().uuidString
        self.date = date
        self.steps = steps
        self.caloriesBurned = caloriesBurned
        self.sleepHours = sleepHours
        self.heartRateAvg = heartRateAvg
        self.heartRateMin = heartRateMin
        self.heartRateMax = heartRateMax
        self.waterMl = waterMl
        self.source = source
    }
}

// MARK: - Finance

enum TransactionType: String, Codable {
    case income = "income"
    case expense = "expense"
}

enum FinanceCategory: String, Codable, CaseIterable {
    case food = "Еда"
    case transport = "Транспорт"
    case health = "Здоровье"
    case education = "Обучение"
    case entertainment = "Развлечения"
    case shopping = "Покупки"
    case salary = "Зарплата"
    case freelance = "Фриланс"
    case other = "Другое"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .entertainment: return "gamecontroller.fill"
        case .shopping: return "bag.fill"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

class Transaction: Codable, Identifiable {
    var id: String
    var title: String
    var amount: Double
    var type: String
    var category: String
    var date: Date
    var note: String

    init(title: String, amount: Double, type: TransactionType,
         category: FinanceCategory, note: String = "") {
        self.id = UUID().uuidString
        self.title = title
        self.amount = amount
        self.type = type.rawValue
        self.category = category.rawValue
        self.date = Date()
        self.note = note
    }
}

// MARK: - Learning

enum LearningStatus: String, Codable {
    case notStarted = "Не начат"
    case inProgress = "В процессе"
    case completed = "Завершён"
}

class Course: Codable, Identifiable {
    var id: String
    var title: String
    var category: String
    var totalLessons: Int
    var completedLessons: Int
    var status: String
    var startDate: Date?
    var targetDate: Date?
    var notes: String

    init(title: String, category: String, totalLessons: Int) {
        self.id = UUID().uuidString
        self.title = title
        self.category = category
        self.totalLessons = totalLessons
        self.completedLessons = 0
        self.status = LearningStatus.notStarted.rawValue
        self.notes = ""
    }

    var progress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
}

// MARK: - AI Chat

enum MessageRole: String, Codable {
    case user, assistant, system
}

struct ChatMessageItem: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date
    let isAgentMode: Bool
    let agentType: String?
}

struct ChatSession: Identifiable, Codable {
    let id: String
    var title: String
    var lastMessage: String
    var date: Date
    var messages: [ChatMessageItem]
}

enum AgentType: String, Codable, CaseIterable {
    case general = "Общий"
    case health = "Медицина"
    case finance = "Финансы"
    case learning = "Обучение"

    var icon: String {
        switch self {
        case .general: return "sparkles"
        case .health: return "heart.text.square.fill"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .learning: return "brain.head.profile"
        }
    }

    var color: String {
        switch self {
        case .general: return "blue"
        case .health: return "pink"
        case .finance: return "green"
        case .learning: return "purple"
        }
    }
}

class ChatMessage: Codable, Identifiable {
    var id: String
    var role: String
    var content: String
    var timestamp: Date
    var agentType: String
    var isAgentMode: Bool

    init(role: MessageRole, content: String,
         agentType: AgentType = .general, isAgentMode: Bool = false) {
        self.id = UUID().uuidString
        self.role = role.rawValue
        self.content = content
        self.timestamp = Date()
        self.agentType = agentType.rawValue
        self.isAgentMode = isAgentMode
    }
}

// MARK: - App Settings

struct AppSettings: Codable {
    var theme: AppTheme = .system
    var language: String = "ru_RU"
    var notificationsEnabled: Bool = true
    var healthKitConnected: Bool = false
    var ouraConnected: Bool = false
    var gaminConnected: Bool = false
    var whoopConnected: Bool = false
    var currency: String = "RUB"
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Светлая"
    case dark = "Тёмная"
    case system = "Системная"
}

// MARK: - Subscription

enum SubscriptionPlan: String, Codable {
    case free = "free"
    case pro = "pro"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Бесплатный"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
}
