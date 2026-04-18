# Статус разработки Nexus

## ✅ Готово (95%+)
- [[Feature-Auth]] — вход/регистрация email, Google, Apple, телефон
- [[Feature-Learning]] — интерактивная фильтрация по датам + 3 секции
- [[Feature-AI]] — базовый чат с AI

## 🔄 В работе (70-90%)
- [[Feature-Settings]] — все настройки готовы, профиль отделен в отдельный экран
- [[Feature-Finance]] — макет готов, нужна Firebase интеграция
- [[Feature-Health]] — макет готов, нужна HealthKit интеграция
- Рефакторинг структуры (OtherViews.swift разбит на: FinanceView.swift, SettingsView.swift, ProfileView.swift)

## 📋 Планируется (0-30%)
- [[Feature-Health]] — трекер здоровья (ЧСС, вес, сон)
- [[Feature-Finance]] — трекер финансов
- [[Feature-Splash]] — экран загрузки + Lottie анимация
- [[Feature-Analytics]] — аналитика и метрики

## 🎨 Техстек
- **UI:** SwiftUI, Liquid Glass (iOS 26+)
- **Backend:** Firebase Auth, Firestore
- **Automation:** n8n (в планах)
- **Analytics:** нет (нужна система)

## 📊 Метрики
- Auth: 4 способа входа ✅
- Screens: 8 основных (готово 3-4)
- Performance: не профилировано
- Tests: нет

---

**Обновлено:** 2026-04-14
**Следующее:** Доделать Learning, потом Health/Finance архитектура
