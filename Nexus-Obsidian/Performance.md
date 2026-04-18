# Performance Optimization

## 🔴 Проблемы (сейчас)

### Auth Screen
- **Sheet lag on open** — 300-500ms задержка при открытии phone/email sheets
  - Phone menu с 15 странами — Menu() не оптимизирован
  - Email TextField ререндится без нужды
  
- **Theme toggle lag** — 100ms freeze при переключении темы
  - Слишком много Views ререндится одновременно
  - Animation слишком сложная

- **Language menu frame rate drop** — дропы при тапе на Menu
  - Menu() компонент дорогой
  - Возможно, каждый язык перестраивается

### Onboarding
- **Autofill lag** — замедление при автозаполнении пароля
  - SecureField обновляется медленнее

## ✅ Optimized (сделано)

- `@Environment(\.colorScheme)` вместо глобального colorScheme
- `@State` только для необходимых данных
- `.contentShape(Rectangle())` для правильного hit testing
- `.animation(nil, value:)` на Menu для предотвращения анимации выбора

## 📝 TODO

### Высокий приоритет
- [ ] **Lazy load country list** в phone sheet
  - Сейчас: ForEach по 15 странам в Menu
  - Решение: Custom Picker с LazyVStack
  
- [ ] **Simplify theme toggle animation**
  - Убрать лишние @State переменные
  - Использовать одну простую анимацию
  
- [ ] **Profile image caching**
  - Не загружать одно и то же изображение дважды
  - SDWebImageSwiftUI или похожее

### Средний приоритет
- [ ] **Reduce View hierarchy**
  - Слишком много nested ZStack
  - Использовать @ViewBuilder для сложных views

- [ ] **Font preloading**
  - SF Pro Display может быть тяжелым при первом рендере
  
- [ ] **Memory profiling**
  - Проверить утечки на долгой сессии

### Низкий приоритет
- [ ] **Background blur optimization**
  - `.ultraThinMaterial` дорогой на слабых устройствах
  
- [ ] **Animated gradient performance**
  - Canvas rendering может быть bottleneck
  - Профилировать на iPhone 12/13

## 📊 Метрики (до оптимизации)

| Операция | Текущее | Целевое |
|----------|---------|---------|
| Auth sheet open | 300-500ms | <100ms |
| Theme toggle | 100ms | <30ms |
| Language select | 150ms | <50ms |
| Onboarding autofill | 200ms | <100ms |

## 🔧 Tools для профилирования

- **Xcode Instruments** → Core Animation (FPS, GPU load)
- **SwiftUI Preview** → performance indicator
- **MetricKit** → real user metrics (потом)

## 💡 Best Practices

1. Избегай ForEach без ID
2. Используй `.equatable()` модификатор
3. Не вычисляй сложное в `@State`
4. Lazy load тяжёлые компоненты
5. Профилируй перед оптимизацией

---

**Последнее обновление:** 2026-04-14
**Статус:** Требуется серьёзная оптимизация перед production
