import SwiftUI
import PhotosUI

// MARK: - Profile View
//
// Редактор профиля. По дизайну — один в один Settings:
// те же отступы, типографика, glass-карточки, accent-градиент.
// Без квадратных иконок в рядах — профиль про текст и значения.
//
// Ключевые фичи:
//  • Верхние кнопки — minimal glass-circle (как "закрыть" в кэше).
//  • Аватар близко к заголовку + кнопка удалить фото.
//  • Рост/вес — горизонтальный ruler picker с rubber-banding.

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs

    @State private var selectedPhotoItem: PhotosPickerItem?

    // ИМЯ
    @State private var firstName  = ""
    @State private var lastName   = ""
    @State private var middleName = ""
    @State private var username   = ""

    // ФИЗИЧЕСКИЕ ДАННЫЕ
    @State private var heightInt  = 175
    @State private var weightInt  = 70
    @State private var gender     = "Не указан"
    @State private var birthDate  = Date()

    // ПРОИСХОЖДЕНИЕ
    @State private var race      = "Не указан"
    @State private var ethnicity = "Не указан"

    // ОБРАЗ ЖИЗНИ
    @State private var dietType      = "Не указан"
    @State private var maritalStatus = "Не указан"

    // МЕСТОПОЛОЖЕНИЕ
    @State private var country = "Не указана"
    @State private var city    = ""

    // О СЕБЕ
    @State private var bio = ""

    @State private var isSaving = false
    @State private var closePressed = false
    @State private var savePressed  = false

    // MARK: Design tokens (зеркалят SettingsView.DS)
    private let accent1 = Color(red: 0.0, green: 0.48, blue: 1.0)   // #0077FF
    private let accent2 = Color(red: 0.0, green: 0.90, blue: 1.0)   // #00E5FF
    private var accentGrad: LinearGradient {
        LinearGradient(colors: [accent1, accent2],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private let hPad: CGFloat    = 16
    private let vGap: CGFloat    = 20
    private let rowV: CGFloat    = 10
    private let radius: CGFloat  = 20
    private let bodySz: CGFloat  = 15

    private var fg: Color {
        cs == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
    }
    private var stroke: Color {
        cs == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    // MARK: - Enums data

    private let genders = ["Не указан", "Мужской", "Женский", "Другой"]
    private let diets = [
        "Не указан",
        "Всеядный (без ограничений)",
        "Вегетарианство",
        "Веганство",
        "Пескетарианство (рыба + растения)",
        "Кетогенная диета",
        "Безглютеновая",
        "Другое"
    ]
    private let maritalOpts = [
        "Не указан",
        "Холост / Не замужем",
        "В отношениях",
        "Женат / Замужем",
        "Разведён / Разведена"
    ]
    private let races = [
        "Не указан", "Европеоид", "Азиат", "Латиноамериканец",
        "Темнокожий", "Ближневосточный", "Смешанный", "Другой"
    ]
    private let ethnicities = [
        "Не указан", "Русский", "Украинец", "Белорус", "Казах",
        "Татарин", "Армянин", "Грузин", "Узбек", "Азербайджанец",
        "Немец", "Американец", "Британец", "Француз", "Испанец",
        "Итальянец", "Китаец", "Японец", "Кореец", "Индиец", "Другой"
    ]
    private let countries = [
        "Не указана", "Россия", "Украина", "Беларусь", "Казахстан",
        "Германия", "США", "Великобритания", "Франция", "Испания",
        "Италия", "Польша", "Нидерланды", "Швеция", "Швейцария",
        "Китай", "Япония", "Южная Корея", "Индия", "ОАЭ",
        "Израиль", "Грузия", "Армения", "Азербайджан", "Узбекистан",
        "Канада", "Австралия", "Бразилия", "Аргентина", "Другая"
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: vGap) {
                    avatarBlock
                    nameSection
                    physicalSection
                    originSection
                    lifestyleSection
                    locationSection
                    bioSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, hPad)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { closeButton }
                ToolbarItem(placement: .topBarTrailing) { saveButton }
            }
        }
        .onAppear { loadData() }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    appState.updateAvatar(data)
                }
            }
        }
    }

    // MARK: - Toolbar buttons (glass-circle, как в CacheBreakdownSheet)

    private var closeButton: some View {
        Image(systemName: "xmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(cs == .dark ? .white : .black)
            .scaleEffect(closePressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: closePressed)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in closePressed = true }
                    .onEnded { g in
                        closePressed = false
                        if abs(g.translation.width) < 18 && abs(g.translation.height) < 18 {
                            dismiss()
                        }
                    }
            )
    }

    private var saveButton: some View {
        ZStack {
            if isSaving {
                ProgressView().tint(accent1).scaleEffect(0.8)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent1)
            }
        }
        .scaleEffect(savePressed ? 0.88 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: savePressed)
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isSaving { savePressed = true } }
                .onEnded { g in
                    savePressed = false
                    if !isSaving,
                       abs(g.translation.width) < 18 && abs(g.translation.height) < 18 {
                        saveProfile()
                    }
                }
        )
    }

    // MARK: - Avatar

    private var avatarBlock: some View {
        let avatarData   = appState.userProfile?.avatarData
        let userInitials = appState.userProfile?.initials ?? "AN"

        return VStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let data = avatarData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(
                                Circle().strokeBorder(stroke, lineWidth: 0.6)
                            )
                    } else {
                        ZStack {
                            Circle().fill(accentGrad).frame(width: 96, height: 96)
                            Text(userInitials)
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    Circle()
                        .fill(accent1)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().strokeBorder(
                                cs == .dark ? Color.black.opacity(0.25) : Color.white,
                                lineWidth: 2.5
                            )
                        )
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)

            // Имя под аватаркой (если заполнено) — маленькая подсказка,
            // чтобы блок выглядел законченным.
            if !(firstName.isEmpty && lastName.isEmpty) {
                Text("\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(fg)
            }

            // Кнопка удалить фото — показываем только если есть что удалять.
            if avatarData != nil {
                Button {
                    let h = UIImpactFeedbackGenerator(style: .light)
                    h.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.updateAvatar(nil)
                    }
                    selectedPhotoItem = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                        Text("Удалить фото")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.red.opacity(0.85))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.red.opacity(0.08), in: Capsule())
                    .overlay(Capsule().strokeBorder(.red.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Sections

    // MARK: - Palette for row icons

    private var cBlue:   Color { Color(red: 0.00, green: 0.48, blue: 1.00) }
    private var cCyan:   Color { Color(red: 0.20, green: 0.75, blue: 0.88) }
    private var cGreen:  Color { Color(red: 0.22, green: 0.72, blue: 0.35) }
    private var cOrange: Color { Color(red: 0.97, green: 0.58, blue: 0.14) }
    private var cRed:    Color { Color(red: 0.95, green: 0.30, blue: 0.34) }
    private var cPink:   Color { Color(red: 0.98, green: 0.40, blue: 0.60) }
    private var cPurple: Color { Color(red: 0.55, green: 0.25, blue: 0.95) }
    private var cIndigo: Color { Color(red: 0.37, green: 0.36, blue: 0.90) }
    private var cTeal:   Color { Color(red: 0.15, green: 0.65, blue: 0.65) }
    private var cBrown:  Color { Color(red: 0.60, green: 0.45, blue: 0.35) }
    private var cGold:   Color { Color(red: 0.95, green: 0.75, blue: 0.10) }

    private var nameSection: some View {
        glassSection(title: "ИМЯ") {
            ProfileField("Имя", text: $firstName, fg: fg,
                         icon: "person.fill", iconColor: cBlue)
            divider
            ProfileField("Отчество", text: $middleName, placeholder: "Введите", fg: fg,
                         icon: "person.2.fill", iconColor: cPurple)
            divider
            ProfileField("Фамилия", text: $lastName, fg: fg,
                         icon: "person.crop.rectangle.fill", iconColor: cTeal)
            divider
            ProfileField("Username", text: $username, fg: fg,
                         icon: "at", iconColor: cOrange)
        }
    }

    private var physicalSection: some View {
        glassSection(title: "ФИЗИЧЕСКИЕ ДАННЫЕ") {
            RulerPickerRow(
                label: "Рост",
                value: $heightInt,
                range: 100...250,
                unit: "см",
                fg: fg,
                accent: accent1,
                icon: "ruler.fill",
                iconColor: cGreen
            )
            divider
            RulerPickerRow(
                label: "Вес",
                value: $weightInt,
                range: 30...300,
                unit: "кг",
                fg: fg,
                accent: accent1,
                icon: "scalemass.fill",
                iconColor: cPink
            )
            divider
            menuRow(label: "Пол", value: gender, options: genders,
                    icon: "figure.stand", iconColor: cIndigo) { gender = $0 }
            divider
            HStack(spacing: 12) {
                NXIconBox(icon: "birthday.cake.fill", bg: cRed, size: 28, iconSize: 14)
                Text("Дата рождения")
                    .font(.system(size: bodySz))
                    .foregroundStyle(fg)
                Spacer(minLength: 4)
                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(accent1)
            }
            .padding(.horizontal, hPad).padding(.vertical, rowV)
        }
    }

    private var originSection: some View {
        glassSection(title: "ПРОИСХОЖДЕНИЕ") {
            menuRow(label: "Раса", value: race, options: races,
                    icon: "globe.europe.africa.fill", iconColor: cBlue) { race = $0 }
            divider
            menuRow(label: "Этнос / Национальность", value: ethnicity, options: ethnicities,
                    icon: "flag.fill", iconColor: cRed) { ethnicity = $0 }
        }
    }

    private var lifestyleSection: some View {
        glassSection(title: "ОБРАЗ ЖИЗНИ") {
            menuRow(label: "Тип питания", value: dietType, options: diets,
                    icon: "leaf.fill", iconColor: cGreen,
                    valueMaxWidth: 200) { dietType = $0 }
            divider
            menuRow(label: "Семейное положение", value: maritalStatus, options: maritalOpts,
                    icon: "heart.fill", iconColor: cPink,
                    valueMaxWidth: 160) { maritalStatus = $0 }
        }
    }

    private var locationSection: some View {
        glassSection(title: "МЕСТОПОЛОЖЕНИЕ") {
            menuRow(label: "Страна", value: country, options: countries,
                    icon: "globe", iconColor: cCyan) { country = $0 }
            divider
            ProfileField("Город", text: $city, fg: fg,
                         icon: "building.2.fill", iconColor: cOrange)
        }
    }

    private var bioSection: some View {
        glassSection(title: "О СЕБЕ") {
            HStack(alignment: .top, spacing: 12) {
                NXIconBox(icon: "text.quote", bg: cPurple, size: 28, iconSize: 14)
                    .padding(.top, 10)
                ZStack(alignment: .topLeading) {
                    if bio.isEmpty {
                        Text("Биография")
                            .foregroundStyle(fg.opacity(0.35))
                            .font(.system(size: bodySz))
                            .padding(.top, 14)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $bio)
                        .foregroundStyle(fg)
                        .font(.system(size: bodySz))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100, maxHeight: 160)
                        .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.5)
                .textCase(.uppercase)
                .foregroundStyle(fg.opacity(0.45))
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(stroke, lineWidth: 0.5))
        }
    }

    private var divider: some View {
        Divider().background(fg.opacity(0.06)).padding(.leading, hPad)
    }

    @ViewBuilder
    private func menuRow(label: String,
                         value: String,
                         options: [String],
                         icon: String? = nil,
                         iconColor: Color = .blue,
                         valueMaxWidth: CGFloat = 180,
                         onSelect: @escaping (String) -> Void) -> some View {
        HStack(spacing: 12) {
            if let icon {
                NXIconBox(icon: icon, bg: iconColor, size: 28, iconSize: 14)
            }
            Text(label)
                .font(.system(size: bodySz))
                .foregroundStyle(fg)
            Spacer(minLength: 4)
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { onSelect(opt) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(value.isEmpty || value.contains("Не указ") ? "Выбрать" : value)
                        .font(.system(size: 14))
                        .foregroundStyle(fg.opacity(0.5))
                        .lineLimit(1)
                        .frame(maxWidth: valueMaxWidth, alignment: .trailing)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(fg.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, rowV)
    }

    // MARK: - Save / Load

    @MainActor private func loadData() {
        guard let p = appState.userProfile else { return }
        firstName     = p.firstName
        lastName      = p.lastName
        middleName    = p.middleName
        username      = p.username
        bio           = p.bio
        weightInt     = p.weightKg > 0 ? Int(p.weightKg) : 70
        heightInt     = p.heightCm > 0 ? Int(p.heightCm) : 175
        birthDate     = p.birthDate
        gender        = p.gender.isEmpty ? "Не указан" : p.gender
        race          = p.race.isEmpty ? "Не указан" : p.race
        ethnicity     = p.ethnicity.isEmpty ? "Не указан" : p.ethnicity
        dietType      = p.dietType.isEmpty ? "Не указан" : p.dietType
        maritalStatus = p.maritalStatus.isEmpty ? "Не указан" : p.maritalStatus
        country       = p.country.isEmpty ? "Не указана" : p.country
        city          = p.city
    }

    @MainActor private func saveProfile() {
        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let profile = appState.userProfile ?? UserProfile()
        profile.firstName     = firstName
        profile.lastName      = lastName
        profile.middleName    = middleName
        profile.username      = username
        profile.bio           = bio
        profile.weightKg      = Double(weightInt)
        profile.heightCm      = Double(heightInt)
        profile.birthDate     = birthDate
        profile.gender        = gender
        profile.race          = race
        profile.ethnicity     = ethnicity
        profile.dietType      = dietType
        profile.maritalStatus = maritalStatus
        profile.country       = country
        profile.city          = city
        appState.updateProfile(profile)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isSaving = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        }
    }
}

// MARK: - ProfileField (text row)

private struct ProfileField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var prefix: String = ""
    let fg: Color
    var icon: String? = nil
    var iconColor: Color = .blue

    init(_ label: String, text: Binding<String>,
         placeholder: String = "", prefix: String = "", fg: Color,
         icon: String? = nil, iconColor: Color = .blue) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.prefix = prefix
        self.fg = fg
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                NXIconBox(icon: icon, bg: iconColor, size: 28, iconSize: 14)
            }
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(fg)
            Spacer(minLength: 4)
            if !prefix.isEmpty {
                Text(prefix)
                    .foregroundStyle(fg.opacity(0.35))
                    .font(.system(size: 15))
            }
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(fg)
                .font(.system(size: 15))
                .frame(maxWidth: 180)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Ruler Picker
//
// Горизонтальная шкала со свободным скроллом + snap к ближайшему тику,
// rubber-banding на границах диапазона (native iOS scroll), haptic feedback
// на каждое изменение значения. Вдохновлено Opal.
//
// Реализация через ScrollView + scrollTargetLayout + scrollPosition(id:).
// Native-инерция и резиновый bounce на границах идут из коробки.

private struct RulerPickerRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let fg: Color
    let accent: Color
    var icon: String? = nil
    var iconColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon {
                    NXIconBox(icon: icon, bg: iconColor, size: 28, iconSize: 14)
                }
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(fg)
                Spacer(minLength: 4)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(value)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(fg)
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(fg.opacity(0.45))
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.85), value: value)
            }
            Ruler(value: $value, range: range, fg: fg, accent: accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct Ruler: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let fg: Color
    let accent: Color

    /// Расстояние между соседними тиками.
    private let tickSpacing: CGFloat = 10
    /// Высота тика для обычной / для "каждый 5" / для "каждый 10".
    private let tickH: CGFloat = 10
    private let tickMidH: CGFloat = 16
    private let tickMajorH: CGFloat = 22

    /// Адаптер-байндинг для scrollPosition. Прокси между
    /// `@Binding var value: Int` и ожидаемым `Binding<Int?>`.
    /// Чисто прокидывает новое значение наверх и триггерит haptic —
    /// без промежуточного @State, который раньше вызывал «отбрасывание».
    private var positionBinding: Binding<Int?> {
        Binding(
            get: { value },
            set: { new in
                if let n = new, n != value {
                    value = n
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
        )
    }

    var body: some View {
        GeometryReader { geo in
            let centerPad = geo.size.width / 2
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(range, id: \.self) { i in
                        tickView(for: i)
                            .frame(width: tickSpacing, alignment: .center)
                            .id(i)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, centerPad)
                .padding(.vertical, 8)
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
            .scrollPosition(id: positionBinding, anchor: .center)
            .overlay(alignment: .center) {
                // Центральный индикатор — треугольник сверху + вертикальная линия.
                VStack(spacing: 2) {
                    Triangle()
                        .fill(accent)
                        .frame(width: 8, height: 6)
                    Rectangle()
                        .fill(accent)
                        .frame(width: 2, height: 26)
                }
                .shadow(color: accent.opacity(0.4), radius: 4, y: 1)
                .allowsHitTesting(false)
            }
            // Плавное затухание по краям, чтобы крайние тики не выглядели обрезанными.
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0),   location: 0.00),
                        .init(color: .black,              location: 0.12),
                        .init(color: .black,              location: 0.88),
                        .init(color: .black.opacity(0),   location: 1.00)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        }
        .frame(height: 56)
    }

    @ViewBuilder
    private func tickView(for i: Int) -> some View {
        let isMajor = i % 10 == 0
        let isMid   = i % 5 == 0 && !isMajor
        let h: CGFloat = isMajor ? tickMajorH : (isMid ? tickMidH : tickH)
        let opacity: Double = isMajor ? 0.8 : (isMid ? 0.5 : 0.28)

        VStack(spacing: 3) {
            Rectangle()
                .fill(fg.opacity(opacity))
                .frame(width: 1, height: h)
            if isMajor {
                Text("\(i)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(fg.opacity(0.5))
                    .fixedSize()
            } else {
                Color.clear.frame(height: 10)
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
