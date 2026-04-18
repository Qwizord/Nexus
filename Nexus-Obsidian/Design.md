# Design System Nexus

## 🎨 Палитры

### Dark Theme
```
Primary:        #FFFFFF (text, icons)
Secondary:      #FFFFFF 50% (secondary text)
Tertiary:       #FFFFFF 40% (hint text)
Border:         #FFFFFF 15%
Background:     #020212 (основной фон)
Accent:         Голубой gradient
```

### Light Theme
```
Primary:        #1B1B1E (text, icons)
Secondary:      #000000 45% (secondary text)
Tertiary:       #000000 35% (hint text)
Border:         #000000 12%
Background:     #C8DFF5 (основной фон)
Accent:         Голубой gradient
```

## 🎛 Компоненты

### Gradient (Primary Action)
```swift
LinearGradient(
    colors: [
        Color(red: 0.0, green: 0.48, blue: 1.0),    // Синий
        Color(red: 0.34, green: 0.84, blue: 1.0)    // Голубой
    ],
    startPoint: .leading,
    endPoint: .trailing
)
```

### Liquid Glass
```swift
.glassEffect(.regular.interactive(), in: Capsule())
// Для light theme используем:
.background(.regularMaterial, in: Capsule())
```

### Input Fields
```swift
.background(.ultraThinMaterial, in: Capsule())
.overlay(Capsule().strokeBorder(border, lineWidth: 0.5))
```

### Buttons
```swift
// Primary button (glass)
.glassEffect(.regular.interactive(), in: Capsule())

// Secondary button (material)
.background(.ultraThinMaterial, in: Capsule())

// Action button (gradient)
.background(gradient, in: Capsule())
```

## 🌊 Animated Background

### Light Mode Colors
```javascript
const lightConfig = {
    colors: [
        '#A8C8F0', '#C4DAEF', '#9EC0E8',
        '#B8D0EC', '#8AB4E0', '#D0E4F8'
    ],
    colorBrightness: 0.95,
    colorSaturation: 2,
    backgroundColor: '#C8DFF5'
}
```

### Dark Mode Colors
```javascript
const darkConfig = {
    colors: [
        '#0A1F4D', '#1A3A6F', '#082847',
        '#1E4C8E', '#0F2E5F', '#2B5FA0'
    ],
    colorBrightness: 0.7,
    colorSaturation: 1.5,
    backgroundColor: '#020212'
}
```

## 📐 Типография

- **Display:** SF Pro Display, 32pt, bold, rounded
- **Headline:** SF Pro Display, 17-24pt, semibold
- **Body:** SF Pro Display, 16-17pt, regular
- **Caption:** SF Pro Display, 13-14pt, regular
- **Small:** SF Pro Display, 12pt, regular

## 📏 Spacing

```
XS: 4pt
S:  8pt
M:  12pt
L:  16pt
XL: 20pt
XXL: 24pt
```

## 🎭 Corner Radius

- **Small inputs:** Capsule() (полное скругление)
- **Cards:** 16pt
- **Buttons:** Capsule()
- **Modals:** 20pt top

## 🔄 Animations

- **Spring:** `response: 0.35, dampingFraction: 0.78` (standard)
- **Interactive:** `response: 0.18, dampingFraction: 0.85` (drag)
- **Transitions:** `.spring(response: 0.4)`

## 📱 Responsive

- **Portrait:** Full width, 24pt padding
- **Landscape:** Max width 480pt, centered
- **Compact height:** ScrollView for content

## 🌙 Theme Switcher

- Icon: moon.fill (dark) / sun.max.fill (light)
- Indicator: Primary color, 25% opacity
- Size: 52pt width × 44pt height
- Shape: Capsule

---

**Последнее обновление:** 2026-04-14
**Figma:** (не используется, всё в коде)
