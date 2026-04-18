# Issues & Bugs

## 🔴 Active

### Auth Screen
- [ ] **Black dots in SecureField autofill (dark theme)** — при автозаполнении пароля показываются чёрные точки вместо белых
  - Файл: `AuthView.swift`, `AuthSecureInputField`
  - Причина: SecureField не уважает цвета при autofill
  - Решение: Переделать на UITextField с custom styling

- [ ] **Theme toggle lag on switch** — переключение темы замораживает UI на 100ms
  - Файл: `AuthView.swift`, `themeAppearanceToggle`
  - Причина: Реанимация слишком сложная
  - TODO: Упростить animation, убрать лишние перерисовки

- [ ] **Language menu shadow (light mode)** — квадратная тень вместо круглой
  - Файл: `AuthView.swift`, `languageSwitcher`
  - FIXED в предыдущей сессии (убрали clipShape)

### Onboarding
- [ ] **Gradient colors** — нужно изменить на голубые (было фиолетовые)
  - FIXED: Gradient → голубой (#0078FF → #56D8FF)

### Performance
- [ ] **Phone sheet lag on open** — задержка 500ms при открытии phone input sheet
  - Файл: `AuthView.swift`, `phoneSheet`
  - Причина: Тяжёлый Menu с 15 странами
  - TODO: Lazy load, или custom picker

- [ ] **Email sheet lag on open** — аналогично
  - Файл: `AuthView.swift`, `emailLoginSheet`
  - TODO: Оптимизировать TextFields rendering

### Landscape Mode
- [ ] **Theme switcher, logo, text не опускаются** — нужно двигать вниз на ландшафте
- [ ] **Phone input (999) слишком широкий** — занимает весь экран
- [ ] **Email input слишком широкий** — нормализовать ширину

---

## 🟡 Watching

### Eye Icon Visibility Toggle
- Both password fields toggle together (нужны независимые)
- Тап на eye icon не должен закрывать sheet

---

## ✅ Resolved

- **Square shadow on language menu** (2026-04-14) — убрали clipShape
- **Theme toggle too light in dark mode** (2026-04-14) — switched to `.regular.interactive()`
- **Button colors inverted** (previous) — fixed with adaptive colors

---

## 📊 Метрики

| Категория | Active | Watching | Resolved |
|-----------|--------|----------|----------|
| Auth      | 3      | 1        | 2        |
| Onboarding| 1      | 0        | 1        |
| Performance| 2     | 0        | 0        |
| Landscape | 3      | 0        | 0        |
| **Total** | **9**  | **1**    | **3**    |

---

**Последнее обновление:** 2026-04-14
