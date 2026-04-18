# Solutions & Insights

Заметки о решениях, которые сработали, и вещах, которые нужно помнить.

## 🎨 Дизайн решения

### Liquid Glass на Light Theme
**Проблема:** `.glassEffect()` на light theme даёт square shadow
**Решение:** Использовать `.regularMaterial` вместо `.glassEffect()` на light theme

```swift
.background(
    colorScheme == .dark ? AnyShapeStyle(.clear) : AnyShapeStyle(.regularMaterial),
    in: Capsule()
)
.if(colorScheme == .dark) { $0.glassEffect(.regular.interactive(), in: Capsule()) }
```

### Theme Toggle Drag Interaction
**Проблема:** Нужна способность крутить палец без отрыва + тапнуть
**Решение:** DragGesture с minimumDistance: 4, tap обработка отдельно

```swift
.simultaneousGesture(
    DragGesture(minimumDistance: 4)
        .onChanged { value in
            let progress = ...
            themeDragProgress = progress
        }
        .onEnded { value in
            themeDragProgress = nil
        }
)
.onTapGesture { ... } // работает параллельно
```

### AuthBackgroundView Independence
**Проблема:** Background читает SwiftUI colorScheme, но нужна независимость от app theme
**Решение:** Передавать `appState.settings.theme` напрямую

```swift
AuthBackgroundView(theme: appState.settings.theme)

private struct AuthBackgroundView: View {
    let theme: AppTheme
    var body: some View {
        FlameBackground(forceScheme: theme == .dark ? .dark : .light)
    }
}
```

### Adaptive Text & Icon Colors
**Проблема:** Glass buttons становятся белыми через 1 секунду (UIKit override)
**Решение:** Адаптивные цвета через `@Environment(\.colorScheme)`

```swift
@Environment(\.colorScheme) private var colorScheme
private var fg: Color { 
    colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
}
```

---

## 🔧 Техничное

### Capsule() vs RoundedRectangle()
**Правило:** Используй `Capsule()` для всех кнопок и инпутов (полное скругление)
- Выглядит лучше с glass эффектами
- Консистентнее с iOS дизайном

### ColorScheme vs AppTheme
- `@Environment(\.colorScheme)` — текущая система/SwiftUI тема
- `appState.settings.theme` — пользовательский выбор

**Пример:**
```swift
let isEffectiveDark = (appState.settings.theme == .dark) || 
                       (appState.settings.theme == .system && colorScheme == .dark)
```

### Gradient Colors (Correct)
```swift
// ✅ Голубой (iOS standard)
[Color(red: 0.0, green: 0.48, blue: 1.0), 
 Color(red: 0.34, green: 0.84, blue: 1.0)]

// ❌ Фиолетовый (avoid)
[Color(red: 0.3, green: 0.4, blue: 1.0), 
 Color(red: 0.5, green: 0.1, blue: 0.9)]
```

---

## 📱 UI Patterns

### Input Field Template
```swift
TextField("Placeholder", text: $text)
    .foregroundStyle(AuthPalette.primary(colorScheme))
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .frame(height: 50)
    .background(.ultraThinMaterial, in: Capsule())
    .overlay(Capsule().strokeBorder(border, lineWidth: 0.5))
```

### Glass Button Template
```swift
Button(action: action) {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .foregroundStyle(fg)
        Text(title)
            .foregroundStyle(fg)
        Spacer()
    }
    .padding(.horizontal, 20)
    .frame(height: 54)
    .frame(maxWidth: .infinity)
}
.buttonStyle(.plain)
.glassEffect(.regular.interactive(), in: Capsule())
```

### Glass Buttons (не двигают ScrollView)
**Проблема:** Когда нажимаешь glass button в ScrollView — экран двигается вниз вместо обычного press effect

**Решение:** Добавить `.simultaneousGesture(DragGesture().onChanged { _ in })`

```swift
Button {
    action()
} label: { ... }
.buttonStyle(.plain)
.simultaneousGesture(DragGesture().onChanged { _ in })  // ← Блокирует скролл
```

Это потребляет drag event и не даёт его дальше ScrollView.

### Menu with adaptive background
```swift
Menu { ... } label: { ... }
    .background(
        colorScheme == .dark ? AnyShapeStyle(.clear) : AnyShapeStyle(.regularMaterial),
        in: Capsule()
    )
    .if(colorScheme == .dark) { $0.glassEffect(.regular.interactive(), in: Capsule()) }
```

---

## 🎯 Do's & Don'ts

### ✅ DO
- Используй Capsule() для скруглений
- Адаптируй цвета через colorScheme
- Используй .if() модификатор для условной логики
- Весь контент в Capsule/RoundedRectangle с borders

### ❌ DON'T
- Не используй .clipShape() перед .background() (даёт square shadow)
- Не используй жёсткие цвета для текста (делай adaptive)
- Не забывай про .animation(nil, value:) на Menu выборах
- Не используй SlideIn/SlideOut анимации (дорогие на тяжелых устройствах)

### Task Filtering by Date
**Проблема:** При изменении selectedDate в датовом пикере задачи не фильтруются
**Решение:** Computed property `filteredTaskGroups` с Calendar.isDate(_:inSameDayAs:)

```swift
var filteredTaskGroups: [TaskGroup] {
    vm.taskGroups.compactMap { group in
        let tasksForDate = group.tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }
        guard !tasksForDate.isEmpty else { return nil }
        var filtered = group
        filtered.tasks = tasksForDate
        return filtered
    }
}
// Использовать filteredTaskGroups вместо vm.taskGroups в ForEach
```

### Header Alignment (Finance vs AI/Health)
**Проблема:** Заголовок "Финансы" ниже, чем "AI" и "Здоровье"
**Решение:** Убрать `alignment: .bottom` из HStack, использовать default center alignment
- AI: `HStack { VStack(...) }`
- Health: `HStack { VStack(...) }`
- Finance: `HStack { Text(...) }` + убрать `.padding(.bottom, 5)`

---

## 🔍 Debugging Tips

### Glass Effect не работает?
- Проверь, что view не имеет `.preferredColorScheme()`
- Проверь `.environment(\.colorScheme, ...)` — может перебить

### Sheet лагает при открытии?
- Используй Instruments → Core Animation для профилирования
- Уменьши количество views в menu (lazy load)
- Убери лишние states

### Цвета не совпадают между темами?
- Используй AuthPalette helper для консистентности
- Проверь, что light theme использует Color(red:green:blue:) правильно

---

**Последнее обновление:** 2026-04-14
**Добавляй сюда все ценные знания из сессий!**
