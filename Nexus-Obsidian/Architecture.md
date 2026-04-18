# Архитектура Nexus

## 🏗 MVVM + Repository Pattern

```
View (SwiftUI)
    ↓
ViewModel (@ObservedObject)
    ↓
Repository (AppState)
    ↓
Firebase + Local Storage
```

## 📱 Основные компоненты

### AppState
- Главный синглтон для управления состоянием
- Содержит: auth, settings, user profile, navigation
- Взаимодействует с Firebase через AuthManager

### Views
- **AuthView** — вход/регистрация (Email, Google, Apple, Phone)
- **OnboardingView** — сбор данных (имя, вес, рост, пол)
- **SettingsView** — настройки приложения (тема, язык, интеграции)
- **ProfileView** — редактирование профиля (фото, имя, вес, рост, пол)
- **HealthView** — трекинг здоровья (готовый макет)
- **FinanceView** — трекинг финансов (готовый макет с MockData)
- **LearningView** — обучение с 3 секциями (Новости, Задачи, База знаний)
- **AIAssistantView** — чат с ассистентом

### Утилиты (OtherViews.swift)
- **NetworkErrorView** — показ ошибок подключения
- **SkeletonBlock/Card/TransactionRow** — loading анимация
- **ShimmerModifier** — shimmer эффект
- **Extensions** — applyGlassCircle(), if(), shimmer()

## 🔐 Firebase Integration

### Authentication
- Email/Password
- Google Sign-In
- Apple Sign-In
- Phone SMS (планируется)

### Database (Firestore)
```
users/{userId}
  ├── email
  ├── fullName
  ├── avatar
  ├── settings (theme, language)
  ├── profile (weight, height, birth date)
  └── subscription (plan, expiry)

content/{contentId}
  ├── title
  ├── description
  ├── category (learning, health, finance)
  └── metadata

analytics/{userId}/events/{eventId}
  (планируется)
```

## 🎨 Дизайн система

- **Liquid Glass** — `.glassEffect(.regular.interactive(), in: Capsule())`
- **Цвета:**
  - Dark: #020212 (фон), #FFFFFF (текст)
  - Light: #C8DFF5 (фон), #1B1B1E (текст)
  - Gradient: голубой (#0078FF → #56D8FF)
- **Шрифты:** SF Pro Display (system)

## 🔄 n8n Workflows (планируется)

- Отправка уведомлений
- Синхронизация с внешними сервисами
- Обработка данных для аналитики

---

**Последнее обновление:** 2026-04-14
