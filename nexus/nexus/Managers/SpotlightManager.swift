import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

// MARK: - Spotlight Manager
//
// Добавляет основные экраны Nexus в системный Spotlight поиск.
// Позволяет найти «Финансы», «Здоровье», «Обучение», «AI-ассистент», «Настройки»
// и т.п. прямо из Spotlight (свайп вниз на home screen).
//
// При включении тоггла в Settings — индексируем; при выключении — удаляем.

@MainActor
final class SpotlightManager {
    static let shared = SpotlightManager()

    /// Идентификатор домена (uniqueIdentifier берётся как "nexus.<slug>").
    private let domainID = "com.nexus.app.shortcuts"

    private init() {}

    // MARK: - Public API

    /// Проиндексировать все главные экраны приложения.
    func indexAppShortcuts() {
        let shortcuts: [(slug: String, title: String, subtitle: String, keywords: [String])] = [
            ("home",       "Главная",       "Обзор целей и активности",
             ["nexus", "главная", "обзор", "dashboard"]),
            ("health",     "Здоровье",      "HealthKit данные, тренды, граф за 30 дней",
             ["здоровье", "health", "healthkit", "шаги", "пульс"]),
            ("finance",    "Финансы",       "Транзакции, 50/30/20, категории, цели",
             ["финансы", "finance", "транзакции", "деньги", "бюджет"]),
            ("learning",   "Обучение",      "Курсы, прогресс, категории",
             ["обучение", "learning", "курсы", "прогресс"]),
            ("ai",         "AI-ассистент",  "Чат с ИИ, сессии, инсайты",
             ["ai", "чат", "ассистент", "gpt"]),
            ("profile",    "Профиль",       "Личные данные, фото, биография",
             ["профиль", "profile"]),
            ("settings",   "Настройки",     "Face ID, интеграции, подписка, язык",
             ["настройки", "settings", "face id", "язык", "тема"]),
            ("support",    "Поддержка",     "Написать в поддержку, заявки, FAQ",
             ["поддержка", "support", "faq", "помощь"])
        ]

        let items: [CSSearchableItem] = shortcuts.map { sc in
            let attr = CSSearchableItemAttributeSet(contentType: UTType.content)
            attr.title = sc.title
            attr.contentDescription = sc.subtitle
            attr.keywords = sc.keywords
            // Иконка — системный SF Symbol, конвертированный в PNG было бы избыточно.
            // Оставляем без thumbnailData — Spotlight возьмёт иконку приложения.

            let item = CSSearchableItem(
                uniqueIdentifier: "nexus.\(sc.slug)",
                domainIdentifier: domainID,
                attributeSet: attr
            )
            return item
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("[Spotlight] indexing error: \(error.localizedDescription)")
            }
        }
    }

    /// Удалить все проиндексированные элементы Nexus из Spotlight.
    func removeAllShortcuts() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainID]) { error in
            if let error = error {
                print("[Spotlight] delete error: \(error.localizedDescription)")
            }
        }
    }

    /// Полный сброс (удаляет вообще всё, что мы индексировали).
    func removeAllApplicationShortcuts() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("[Spotlight] delete-all error: \(error.localizedDescription)")
            }
        }
    }
}
