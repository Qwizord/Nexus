import Foundation
import Combine

// MARK: - User

class UserProfile: Codable, ObservableObject {
    var id: String
    var firstName: String
    var lastName: String
    var middleName: String
    var username: String
    var bio: String
    var email: String
    var phone: String?
    var avatarData: Data?
    var birthDate: Date
    var weightKg: Double
    var heightCm: Double
    var gender: String
    var race: String
    var ethnicity: String
    var dietType: String
    var maritalStatus: String
    var country: String
    var city: String
    var createdAt: Date
    var subscriptionActive: Bool

    init(id: String = UUID().uuidString,
         firstName: String = "",
         lastName: String = "",
         middleName: String = "",
         username: String = "",
         bio: String = "",
         email: String = "",
         birthDate: Date = Date(),
         weightKg: Double = 70,
         heightCm: Double = 175,
         gender: String = "Не указан",
         race: String = "",
         ethnicity: String = "",
         dietType: String = "",
         maritalStatus: String = "",
         country: String = "",
         city: String = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.middleName = middleName
        self.username = username
        self.bio = bio
        self.email = email
        self.birthDate = birthDate
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.gender = gender
        self.race = race
        self.ethnicity = ethnicity
        self.dietType = dietType
        self.maritalStatus = maritalStatus
        self.country = country
        self.city = city
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
    // Покупки
    case food = "Еда, продукты"
    case clothing = "Одежда"
    case household = "Вещи для дома"
    // Обязательные
    case utilities = "ЖКХ"
    case phone = "Телефон"
    case taxes = "Налоги"
    case rent = "На квартиру"
    // Здоровье
    case medicine = "Медицина"
    case beauty = "Красота"
    // Транспорт
    case car = "Машина"
    case transit = "Проезд"
    case taxi = "Такси"
    // Развлечения
    case entertainment = "Развлечения"
    case travel = "Путешествия"
    // Праздники
    case gifts = "Подарки"
    case celebrations = "Праздники"
    // Долги
    case debt = "Кредит/Долги"
    // Подписки
    case subscriptions = "Подписки"
    // Прочее
    case other = "Прочее"
    case unexpected = "Внеплановые расходы"
    case bankFees = "Банковские расходы"
    // Работа
    case workExpenses = "Затраты на работу"
    // Инвестиции
    case stocks = "Акции"
    case crypto = "Криптовалюта"
    case realty = "Недвижимость"
    case otherInvestment = "Другие инвестиции"
    // Доходы
    case salary = "Зарплата"
    case freelance = "Фриланс"
    case otherIncome = "Другие доходы"

    var icon: String {
        switch self {
        case .food:          return "cart.fill"
        case .clothing:      return "tshirt.fill"
        case .household:     return "house.fill"
        case .utilities:     return "bolt.fill"
        case .phone:         return "phone.fill"
        case .taxes:         return "doc.text.fill"
        case .rent:          return "building.2.fill"
        case .medicine:      return "cross.fill"
        case .beauty:        return "sparkles"
        case .car:           return "car.fill"
        case .transit:       return "tram.fill"
        case .taxi:          return "car.circle.fill"
        case .entertainment: return "gamecontroller.fill"
        case .travel:        return "airplane"
        case .gifts:         return "gift.fill"
        case .celebrations:  return "party.popper.fill"
        case .debt:          return "creditcard.fill"
        case .subscriptions: return "repeat"
        case .other:         return "ellipsis.circle.fill"
        case .unexpected:    return "exclamationmark.triangle.fill"
        case .bankFees:      return "building.columns.fill"
        case .workExpenses:  return "briefcase.fill"
        case .stocks:           return "chart.line.uptrend.xyaxis"
        case .crypto:           return "bitcoinsign.circle.fill"
        case .realty:           return "building.2.crop.circle.fill"
        case .otherInvestment:  return "dollarsign.arrow.circlepath"
        case .salary:        return "banknote.fill"
        case .freelance:     return "laptopcomputer"
        case .otherIncome:   return "plus.circle.fill"
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
    var isBusiness: Bool

    init(title: String, amount: Double, type: TransactionType,
         category: FinanceCategory, note: String = "", isBusiness: Bool = false) {
        self.id = UUID().uuidString
        self.title = title
        self.amount = amount
        self.type = type.rawValue
        self.category = category.rawValue
        self.date = Date()
        self.note = note
        self.isBusiness = isBusiness
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
    var measurementSystem: MeasurementSystem = .metric
    var timezone: String = "Europe/Moscow"
    var notificationsEnabled: Bool = true
    var healthKitConnected: Bool = false
    var ouraConnected: Bool = false
    var gaminConnected: Bool = false
    var whoopConnected: Bool = false
    var currency: String = "RUB"
    var spotlightEnabled: Bool = true
    var calendarEnabled: Bool = false
    var iCloudEnabled: Bool = false
    var faceIDEnabled: Bool = false
    /// Включён ли в приложении 4-значный код-пароль (Telegram-style).
    /// Сам код-хэш хранится в `AppPasscodeStore` (UserDefaults+SHA256),
    /// здесь только флаг для UI и Firestore-синка.
    var appPasscodeEnabled: Bool = false
    /// Интервал auto-lock в секундах. 0 = блокировать сразу. -1 = «никогда»
    /// (актуально только когда appPasscodeEnabled = true).
    var appAutoLockSec: Int = 3600
}

enum MeasurementSystem: String, Codable, CaseIterable {
    case metric   = "metric"
    case imperial = "imperial"

    var displayName: String {
        switch self {
        case .metric:   return "Метрическая (кг, см, °C)"
        case .imperial: return "Имперская (lb, ft, °F)"
        }
    }
}

enum AppTimezone: String, CaseIterable {
    case moscow        = "Europe/Moscow"
    case kaliningrad   = "Europe/Kaliningrad"
    case samara        = "Europe/Samara"
    case yekaterinburg = "Asia/Yekaterinburg"
    case omsk          = "Asia/Omsk"
    case krasnoyarsk   = "Asia/Krasnoyarsk"
    case irkutsk       = "Asia/Irkutsk"
    case yakutsk       = "Asia/Yakutsk"
    case vladivostok   = "Asia/Vladivostok"
    case magadan       = "Asia/Magadan"
    case kamchatka     = "Asia/Kamchatka"
    case kyiv          = "Europe/Kyiv"
    case minsk         = "Europe/Minsk"
    case almaty        = "Asia/Almaty"
    case tashkent      = "Asia/Tashkent"
    case tbilisi       = "Asia/Tbilisi"
    case dubai         = "Asia/Dubai"
    case london        = "Europe/London"
    case berlin        = "Europe/Berlin"
    case newYork       = "America/New_York"
    case losAngeles    = "America/Los_Angeles"
    case utc           = "UTC"

    var displayName: String {
        switch self {
        case .moscow:        return "Москва (UTC+3)"
        case .kaliningrad:   return "Калининград (UTC+2)"
        case .samara:        return "Самара (UTC+4)"
        case .yekaterinburg: return "Екатеринбург (UTC+5)"
        case .omsk:          return "Омск (UTC+6)"
        case .krasnoyarsk:   return "Красноярск (UTC+7)"
        case .irkutsk:       return "Иркутск (UTC+8)"
        case .yakutsk:       return "Якутск (UTC+9)"
        case .vladivostok:   return "Владивосток (UTC+10)"
        case .magadan:       return "Магадан (UTC+11)"
        case .kamchatka:     return "Камчатка (UTC+12)"
        case .kyiv:          return "Киев (UTC+2/+3)"
        case .minsk:         return "Минск (UTC+3)"
        case .almaty:        return "Алма-Ата (UTC+5/+6)"
        case .tashkent:      return "Ташкент (UTC+5)"
        case .tbilisi:       return "Тбилиси (UTC+4)"
        case .dubai:         return "Дубай (UTC+4)"
        case .london:        return "Лондон (UTC+0/+1)"
        case .berlin:        return "Берлин (UTC+1/+2)"
        case .newYork:       return "Нью-Йорк (UTC-5/-4)"
        case .losAngeles:    return "Лос-Анджелес (UTC-8/-7)"
        case .utc:           return "UTC (UTC+0)"
        }
    }

    var shortName: String {
        switch self {
        case .moscow:        return "Москва"
        case .kaliningrad:   return "Калининград"
        case .samara:        return "Самара"
        case .yekaterinburg: return "Екатеринбург"
        case .omsk:          return "Омск"
        case .krasnoyarsk:   return "Красноярск"
        case .irkutsk:       return "Иркутск"
        case .yakutsk:       return "Якутск"
        case .vladivostok:   return "Владивосток"
        case .magadan:       return "Магадан"
        case .kamchatka:     return "Камчатка"
        case .kyiv:          return "Киев"
        case .minsk:         return "Минск"
        case .almaty:        return "Алма-Ата"
        case .tashkent:      return "Ташкент"
        case .tbilisi:       return "Тбилиси"
        case .dubai:         return "Дубай"
        case .london:        return "Лондон"
        case .berlin:        return "Берлин"
        case .newYork:       return "Нью-Йорк"
        case .losAngeles:    return "Лос-Анджелес"
        case .utc:           return "UTC"
        }
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Светлая"
    case dark = "Тёмная"
    case system = "Системная"
}

enum AppLanguage: String, Codable, CaseIterable {
    case english    = "en_US"
    case russian    = "ru_RU"
    case spanish    = "es_ES"
    case french     = "fr_FR"
    case german     = "de_DE"
    case italian    = "it_IT"
    case portuguese = "pt_BR"
    case japanese   = "ja_JP"
    case korean     = "ko_KR"
    case chinese    = "zh_CN"
    case arabic     = "ar_SA"
    case hindi      = "hi_IN"
    case turkish    = "tr_TR"
    case ukrainian  = "uk_UA"
    case polish     = "pl_PL"

    var displayName: String {
        switch self {
        case .english:    return "🇺🇸 United States"
        case .russian:    return "🇷🇺 Россия"
        case .spanish:    return "🇪🇸 España"
        case .french:     return "🇫🇷 France"
        case .german:     return "🇩🇪 Deutschland"
        case .italian:    return "🇮🇹 Italia"
        case .portuguese: return "🇧🇷 Brasil"
        case .japanese:   return "🇯🇵 日本"
        case .korean:     return "🇰🇷 대한민국"
        case .chinese:    return "🇨🇳 中国"
        case .arabic:     return "🇸🇦 السعودية"
        case .hindi:      return "🇮🇳 भारत"
        case .turkish:    return "🇹🇷 Türkiye"
        case .ukrainian:  return "🇺🇦 Україна"
        case .polish:     return "🇵🇱 Polska"
        }
    }
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

// MARK: - Feedback

/// Одно сообщение внутри обращения. `fromAdmin` различает реплики
/// пользователя и команды Nexus.
struct FeedbackMessage: Identifiable, Codable {
    var id: String
    var text: String
    var fromAdmin: Bool
    var createdAt: Date

    init(id: String = UUID().uuidString,
         text: String,
         fromAdmin: Bool,
         createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.fromAdmin = fromAdmin
        self.createdAt = createdAt
    }
}

struct FeedbackTicket: Identifiable, Codable {
    var id: String
    /// Человеко-читаемый номер обращения: №1, №2, …
    /// Выдаётся монотонно возрастающим счётчиком в `FeedbackRepository`.
    var number: Int
    var userId: String
    var userName: String
    var message: String
    /// Дополнительные сообщения в треде (пользователь + админ).
    /// Первое «оригинальное» сообщение живёт в `message` — для обратной
    /// совместимости со старыми тикетами; все последующие реплики пишутся сюда.
    var messages: [FeedbackMessage]
    var status: FeedbackStatus
    var createdAt: Date
    var adminReply: String?
    var repliedAt: Date?

    init(id: String = UUID().uuidString,
         number: Int = 0,
         userId: String,
         userName: String,
         message: String) {
        self.id = id
        self.number = number
        self.userId = userId
        self.userName = userName
        self.message = message
        self.messages = []
        self.status = .open
        self.createdAt = Date()
        self.adminReply = nil
        self.repliedAt = nil
    }

    // Ручной Decodable — чтобы старые тикеты без `number`/`messages`
    // не ломали декод.
    enum CodingKeys: String, CodingKey {
        case id, number, userId, userName, message, messages,
             status, createdAt, adminReply, repliedAt
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.number = (try? c.decode(Int.self, forKey: .number)) ?? 0
        self.userId = try c.decode(String.self, forKey: .userId)
        self.userName = try c.decode(String.self, forKey: .userName)
        self.message = try c.decode(String.self, forKey: .message)
        self.messages = (try? c.decode([FeedbackMessage].self, forKey: .messages)) ?? []
        self.status = (try? c.decode(FeedbackStatus.self, forKey: .status)) ?? .open
        self.createdAt = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.adminReply = try? c.decode(String.self, forKey: .adminReply)
        self.repliedAt = try? c.decode(Date.self, forKey: .repliedAt)
    }
}

enum FeedbackStatus: String, Codable, CaseIterable {
    case open     = "open"
    case answered = "answered"
    case closed   = "closed"

    var displayName: String {
        switch self {
        case .open:     return "Открыто"
        case .answered: return "Отвечено"
        case .closed:   return "Закрыто"
        }
    }

    var color: String {
        switch self {
        case .open:     return "orange"
        case .answered: return "green"
        case .closed:   return "gray"
        }
    }
}
