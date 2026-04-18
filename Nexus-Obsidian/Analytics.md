# Analytics & Metrics System (Планируется)

## 📊 Структура данных

### Firestore: `/analytics/{userId}/events/{eventId}`

```
eventId: {
  event: "screen_view" | "button_tap" | "subscription_purchase" | etc.
  screen: "auth" | "learning" | "settings" | ...
  timestamp: ISO8601
  properties: {}
  userId: "uid"
  appVersion: "1.0.0"
  osVersion: "17.4"
}
```

## 🎯 Key Events

### Authentication
- `auth_signup_started` → props: `provider` (email/google/apple)
- `auth_signup_completed` → props: `provider`, `time_to_complete`
- `auth_login` → props: `provider`
- `auth_logout`

### Onboarding
- `onboarding_started` → props: `step` (1-3)
- `onboarding_step_completed` → props: `step`, `time_spent`
- `onboarding_finished` → props: `total_time`

### Learning
- `learning_screen_view` → props: `category`
- `learning_content_started` → props: `content_id`, `duration_mins`
- `learning_content_completed` → props: `content_id`, `time_spent`

### Health
- `health_data_logged` → props: `type` (weight/heart_rate/sleep), `value`
- `health_goal_set` → props: `goal_type`, `target_value`

### Finance
- `finance_transaction_added` → props: `category`, `amount`, `type` (income/expense)
- `finance_budget_set` → props: `category`, `limit`

### AI
- `ai_message_sent` → props: `message_length`, `category`
- `ai_feedback_given` → props: `rating` (1-5)

### Subscription
- `subscription_viewed` → props: `plan` (monthly/6month/yearly)
- `subscription_purchased` → props: `plan`, `amount`
- `subscription_renewed` → props: `plan`
- `subscription_cancelled` → props: `plan`, `reason`

## 📈 Dashboards (Foresee)

### User Acquisition
- Daily/weekly/monthly signups
- Signup source (organic/app store/referral)
- Conversion rate (landing → signup)

### User Engagement
- DAU/MAU
- Session length
- Feature adoption rates
- Learning completion rate

### Retention
- Day 1/7/30 retention
- Churn rate
- Subscription retention by plan

### Revenue
- MRR (Monthly Recurring Revenue)
- LTV (Lifetime Value)
- Subscription plan breakdown
- Churn revenue impact

### Funnel Analysis
- Auth → Onboarding → First content view
- Learning content engagement funnel
- Subscription conversion funnel

## 🔧 Implementation Plan

### Phase 1 (MVP)
- [ ] Настроить Firestore collection для events
- [ ] Custom Analytics service в AppState
- [ ] Логирование основных событий (auth, screens)
- [ ] Простой dashboard (Firebase Console)

### Phase 2 (Метрики)
- [ ] Интегрировать Mixpanel или Amplitude
- [ ] Дашборды для продакта
- [ ] Alerts для аномалий
- [ ] Cohort analysis

### Phase 3 (AI)
- [ ] n8n workflow для обработки событий
- [ ] Автоматические рекомендации
- [ ] Прогнозирование churn
- [ ] A/B testing

## 💾 Firebase Rules

```
match /analytics/{userId}/events/{eventId} {
  allow create: if request.auth.uid == userId;
  allow read: if request.auth.uid == userId;
  allow delete: if false;
}
```

## 📝 Example Analytics Service

```swift
class AnalyticsService {
    static let shared = AnalyticsService()
    
    func logEvent(_ event: String, properties: [String: Any] = [:]) {
        let eventData: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.appVersion,
            "properties": properties
        ]
        // Save to Firestore
        db.collection("analytics")
            .document(userId)
            .collection("events")
            .addDocument(data: eventData)
    }
}

// Usage:
AnalyticsService.shared.logEvent("auth_signup_completed", 
    properties: ["provider": "google", "time": 45])
```

---

**Статус:** 📋 Planning
**Приоритет:** Low (после MVP)
**Последнее обновление:** 2026-04-14
