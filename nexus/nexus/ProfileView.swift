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
    @State private var confirmDeletePhoto = false

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
    /// Этнические группы / национальности. Отсортированы по алфавиту (ru_RU),
    /// "Не указан" всегда первый, "Другой" — последний.
    private let ethnicities: [String] = {
        let base = [
            // Народы России
            "Русский", "Татарин", "Башкир", "Чуваш", "Мордвин", "Удмурт",
            "Марийец", "Коми", "Карел", "Калмык", "Бурят", "Якут",
            "Тувинец", "Алтаец", "Хакас",
            // Кавказ
            "Чеченец", "Ингуш", "Осетин", "Аварец", "Лезгин", "Даргинец",
            "Кумык", "Лакец", "Табасаран", "Ногаец",
            "Кабардинец", "Балкарец", "Карачаевец", "Адыгеец", "Черкес",
            // СНГ
            "Украинец", "Белорус", "Казах", "Киргиз", "Узбек", "Таджик",
            "Туркмен", "Каракалпак", "Азербайджанец", "Армянин", "Грузин",
            "Абхаз", "Молдаванин", "Литовец", "Латыш", "Эстонец",
            // Европа
            "Немец", "Австриец", "Британец", "Ирландец", "Француз", "Бельгиец",
            "Голландец", "Швейцарец", "Испанец", "Португалец", "Итальянец",
            "Швед", "Норвежец", "Датчанин", "Финн", "Исландец",
            "Поляк", "Чех", "Словак", "Венгр", "Румын", "Болгарин",
            "Серб", "Хорват", "Словенец", "Македонец", "Албанец", "Грек",
            // Ближний Восток / Азия
            "Еврей", "Араб", "Турок", "Перс", "Курд",
            "Афганец", "Пакистанец", "Индиец", "Бенгалец", "Шри‑ланкиец",
            "Китаец", "Японец", "Кореец", "Монгол", "Вьетнамец", "Таец",
            "Индонезиец", "Филиппинец", "Малайзиец",
            // Америки / Африка / Океания
            "Американец", "Канадец", "Мексиканец", "Бразилец", "Аргентинец",
            "Африканец", "Австралиец", "Новозеландец",
            "Цыган", "Метис", "Смешанного происхождения"
        ]
        let sorted = base.sorted { $0.localizedCompare($1) == .orderedAscending }
        return ["Не указан"] + sorted + ["Другой"]
    }()
    /// Флаг для названия страны. Возвращает пустую строку для плейсхолдеров.
    private static func flag(for country: String) -> String {
        let map: [String: String] = [
            "Россия": "🇷🇺", "Украина": "🇺🇦", "Беларусь": "🇧🇾", "Казахстан": "🇰🇿",
            "Германия": "🇩🇪", "США": "🇺🇸", "Великобритания": "🇬🇧", "Франция": "🇫🇷",
            "Испания": "🇪🇸", "Италия": "🇮🇹", "Польша": "🇵🇱", "Нидерланды": "🇳🇱",
            "Швеция": "🇸🇪", "Швейцария": "🇨🇭", "Китай": "🇨🇳", "Япония": "🇯🇵",
            "Южная Корея": "🇰🇷", "Индия": "🇮🇳", "ОАЭ": "🇦🇪", "Израиль": "🇮🇱",
            "Грузия": "🇬🇪", "Армения": "🇦🇲", "Азербайджан": "🇦🇿", "Узбекистан": "🇺🇿",
            "Канада": "🇨🇦", "Австралия": "🇦🇺", "Бразилия": "🇧🇷", "Аргентина": "🇦🇷",
            "Турция": "🇹🇷", "Кыргызстан": "🇰🇬", "Таджикистан": "🇹🇯", "Туркменистан": "🇹🇲",
            "Молдова": "🇲🇩", "Литва": "🇱🇹", "Латвия": "🇱🇻", "Эстония": "🇪🇪",
            "Чехия": "🇨🇿", "Австрия": "🇦🇹", "Португалия": "🇵🇹", "Норвегия": "🇳🇴",
            "Дания": "🇩🇰", "Финляндия": "🇫🇮", "Ирландия": "🇮🇪", "Бельгия": "🇧🇪",
            "Мексика": "🇲🇽", "Вьетнам": "🇻🇳", "Таиланд": "🇹🇭", "Индонезия": "🇮🇩",
            "Сингапур": "🇸🇬", "Саудовская Аравия": "🇸🇦"
        ]
        return map[country] ?? ""
    }

    private let countries = [
        "Не указана",
        "Россия", "Украина", "Беларусь", "Казахстан", "Кыргызстан",
        "Таджикистан", "Туркменистан", "Узбекистан", "Молдова",
        "Грузия", "Армения", "Азербайджан",
        "Германия", "Франция", "Испания", "Италия", "Португалия",
        "Нидерланды", "Бельгия", "Швеция", "Норвегия", "Дания", "Финляндия",
        "Швейцария", "Австрия", "Ирландия", "Великобритания",
        "Польша", "Чехия", "Литва", "Латвия", "Эстония",
        "США", "Канада", "Мексика", "Бразилия", "Аргентина",
        "Китай", "Япония", "Южная Корея", "Индия", "Вьетнам", "Таиланд",
        "Индонезия", "Сингапур",
        "Турция", "Израиль", "ОАЭ", "Саудовская Аравия",
        "Австралия", "Другая"
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
            // Inline-заголовок — как было изначально: компактный верх,
            // профиль начинается сразу под тулбаром.
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { closeButton }
                ToolbarItem(placement: .topBarTrailing) { saveButton }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .onAppear { loadData() }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    appState.updateAvatar(data)
                }
            }
        }
        .alert("Удалить фото?", isPresented: $confirmDeletePhoto) {
            Button("Удалить", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.updateAvatar(nil)
                }
                selectedPhotoItem = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы точно хотите удалить фото профиля?")
        }
    }

    // MARK: - Toolbar buttons (glass-circle, как в CacheBreakdownSheet)

    /// Нативный Button в ToolbarItem → iOS рисует круглую glass-капсулу
    /// и сам обеспечивает тап-таргет ≥ 44pt (без ручного frame, который
    /// превращал glass в овал).
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(cs == .dark ? .white : .black)
        }
        .buttonStyle(ToolbarCloseStyle())
    }

    /// Save-кнопка в тулбаре: используем нативный iOS-26 toolbar-button с
    /// `.borderedProminent` + `.buttonBorderShape(.circle)` — это даёт ровно
    /// ту же круглую капсулу, что и закрывающий ×, но с заливкой акцентом.
    /// Так синяя кнопка визуально 1-в-1 совпадает с белой close-кнопкой,
    /// только заливка — фирменный синий, а галочка — белая.
    private var saveButton: some View {
        Button {
            guard !isSaving else { return }
            saveProfile()
        } label: {
            if isSaving {
                ProgressView()
                    .tint(.white)
                    .controlSize(.small)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(accent1)
        .disabled(isSaving)
    }

    // MARK: - Avatar

    private var avatarBlock: some View {
        let avatarData   = appState.userProfile?.avatarData
        let userInitials = appState.userProfile?.initials ?? "AN"
        let hasPhoto     = avatarData != nil

        // Аватар + единый бейдж в правом-нижнем углу:
        //   • нет фото  → синий кружок с "camera.fill" → открывает PhotosPicker
        //   • есть фото → красный кружок с "xmark"     → удаляет фото
        // Так не надо отдельной кнопки-капсулы снизу.
        return VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                // Сам аватар.
                Group {
                    if let data = avatarData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(stroke, lineWidth: 0.6))
                    } else {
                        ZStack {
                            Circle().fill(accent1).frame(width: 96, height: 96)
                            Text(userInitials)
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }

                // Бейдж-переключатель (добавить / удалить).
                if hasPhoto {
                    // Красный крестик — удалить фото (с подтверждением).
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        confirmDeletePhoto = true
                    } label: {
                        badgeCircle(
                            fill: cRed,
                            systemName: "xmark"
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else {
                    // Синий "добавить фото".
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        badgeCircle(fill: accent1, systemName: "camera.fill")
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }

            // Имя под аватаркой (если заполнено).
            if !(firstName.isEmpty && lastName.isEmpty) {
                Text("\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(fg)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    /// Единый бейдж 28×28 поверх аватарки. Используется и для "добавить",
    /// и для "удалить" — меняется только заливка и SF Symbol.
    @ViewBuilder
    private func badgeCircle(fill: Color, systemName: String) -> some View {
        // Без обводки — чистый цвет круга. Лёгкая тень даёт необходимое
        // визуальное разделение с аватаркой, но не вводит лишний цвет.
        Circle()
            .fill(fill)
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
            .offset(x: 2, y: 2)
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
        glassSection(title: "Имя") {
            ProfileField("Имя", text: $firstName, fg: fg,
                         icon: "person.fill", iconColor: cBlue)
            divider
            ProfileField("Фамилия", text: $lastName, fg: fg,
                         icon: "person.crop.rectangle.fill", iconColor: cTeal)
            divider
            ProfileField("Отчество", text: $middleName, placeholder: "Введите", fg: fg,
                         icon: "person.2.fill", iconColor: cPurple)
            divider
            ProfileField("Username", text: $username, fg: fg,
                         icon: "at", iconColor: cOrange)
        }
    }

    private var physicalSection: some View {
        glassSection(title: "Физические данные") {
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
            HStack(spacing: 14) {
                NXIconBox(icon: "birthday.cake.fill", bg: cRed)
                Text("Дата рождения")
                    .font(.system(size: bodySz))
                    .foregroundStyle(fg)
                Spacer(minLength: 4)
                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(accent1)
                    .environment(\.font, .system(size: 13))
                    .scaleEffect(0.88, anchor: .trailing)
                    .fixedSize()
            }
            .padding(.horizontal, hPad).padding(.vertical, rowV)
        }
    }

    private var originSection: some View {
        glassSection(title: "Происхождение") {
            menuRow(label: "Раса", value: race, options: races,
                    icon: "globe.europe.africa.fill", iconColor: cBlue) { race = $0 }
            divider
            // Короткий label — "Национальность" влезает в одну строку.
            menuRow(label: "Национальность", value: ethnicity, options: ethnicities,
                    icon: "flag.fill", iconColor: cRed) { ethnicity = $0 }
        }
    }

    private var lifestyleSection: some View {
        glassSection(title: "Образ жизни") {
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
        glassSection(title: "Местоположение") {
            menuRow(label: "Страна", value: country, options: countries,
                    icon: "globe", iconColor: cCyan,
                    optionPrefix: { Self.flag(for: $0) }) { country = $0 }
            divider
            ProfileField("Город", text: $city, fg: fg,
                         icon: "building.2.fill", iconColor: cOrange)
        }
    }

    private var bioSection: some View {
        // Без иконки — биография должна "дышать" на всю ширину секции.
        glassSection(title: "О себе") {
            ZStack(alignment: .topLeading) {
                if bio.isEmpty {
                    Text("Расскажите о себе…")
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
                    .frame(minHeight: 110, maxHeight: 170)
                    .padding(.vertical, 6)
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    /// Заголовок секции — точно как `NXSection` в SettingsView:
    /// 15pt medium, secondaryLabel, без uppercase/kerning, leading-отступ = hPad (16).
    /// Вертикальный gap между заголовком и карточкой = 6.
    @ViewBuilder
    private func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.leading, hPad)
            VStack(spacing: 0) { content() }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(stroke, lineWidth: 0.5))
        }
    }

    private var divider: some View {
        Divider().background(fg.opacity(0.06)).padding(.leading, hPad)
    }

    /// Универсальный row с Menu-пикером.
    /// - Parameters:
    ///   - optionPrefix: опциональная функция, возвращающая префикс для каждого пункта (например, флаг страны).
    /// Строка всегда single-line: label имеет `lineLimit(1)` + layoutPriority(1), value — `lineLimit(1)`.
    @ViewBuilder
    private func menuRow(label: String,
                         value: String,
                         options: [String],
                         icon: String? = nil,
                         iconColor: Color = .blue,
                         valueMaxWidth: CGFloat = 160,
                         optionPrefix: ((String) -> String)? = nil,
                         onSelect: @escaping (String) -> Void) -> some View {
        HStack(spacing: 14) {
            if let icon {
                NXIconBox(icon: icon, bg: iconColor)
            }
            Text(label)
                .font(.system(size: bodySz))
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .layoutPriority(1)
            Spacer(minLength: 4)
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button {
                        onSelect(opt)
                    } label: {
                        if let prefix = optionPrefix?(opt), !prefix.isEmpty {
                            Text("\(prefix)  \(opt)")
                        } else {
                            Text(opt)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    let isPlaceholder = value.isEmpty || value.contains("Не указ")
                    let displayPrefix = (optionPrefix?(value) ?? "")
                    let shownText = isPlaceholder
                        ? "Выбрать"
                        : (displayPrefix.isEmpty ? value : "\(displayPrefix) \(value)")
                    Text(shownText)
                        .font(.system(size: 14))
                        .foregroundStyle(fg.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.tail)
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
        HStack(spacing: 14) {
            if let icon {
                NXIconBox(icon: icon, bg: iconColor)
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
        .padding(.vertical, 10)
    }
}

// MARK: - Ruler Picker
//
// Горизонтальная шкала со свободным drag'ом + snap к ближайшему тику + momentum
// по `predictedEndTranslation`. Никаких ScrollView / scrollPosition — именно
// нативный scroll раньше "отбрасывал" значение, потому что во время drag'а
// SwiftUI успевал пересчитать якорь.
//
// Вся логика — чистый DragGesture + один @State `offsetX`. Rubber-banding за
// границами диапазона — вручную, 0.35 коэффициент как у UIScrollView.

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
            HStack(spacing: 14) {
                if let icon {
                    NXIconBox(icon: icon, bg: iconColor)
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
        .padding(.vertical, 10)
    }
}

private struct Ruler: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let fg: Color
    let accent: Color

    /// Расстояние между соседними тиками.
    private let tickSpacing: CGFloat = 10
    private let tickH: CGFloat = 10
    private let tickMidH: CGFloat = 16
    private let tickMajorH: CGFloat = 22

    /// Текущий "сырой" сдвиг полосы. offsetX = 0 → в центре тик `range.lowerBound`;
    /// чтобы показать значение v, нужен `offsetFor(v) = -(v - lowerBound) * tickSpacing`.
    @State private var offsetX: CGFloat = 0
    /// offsetX в момент начала drag'а. Пока не nil — drag активен, внешний `value`
    /// НЕ переписывает offsetX (это и убирает snap-back).
    @State private var dragStart: CGFloat? = nil
    /// Последнее значение, на котором отыграл haptic — чтобы не спамить тик за тиком
    /// при одинаковом индексе.
    @State private var lastHaptic: Int = .min

    // MARK: Math

    private var count: Int { range.upperBound - range.lowerBound + 1 }
    private var minOffset: CGFloat { -CGFloat(count - 1) * tickSpacing }
    private let maxOffset: CGFloat = 0

    private func offsetFor(_ v: Int) -> CGFloat {
        -CGFloat(v - range.lowerBound) * tickSpacing
    }
    private func valueAt(_ offset: CGFloat) -> Int {
        let idx = Int((-offset / tickSpacing).rounded())
        let clamped = max(0, min(count - 1, idx))
        return range.lowerBound + clamped
    }
    /// Классическое iOS-овое сопротивление за пределами диапазона.
    private func rubberBand(_ x: CGFloat) -> CGFloat {
        if x > maxOffset { return maxOffset + (x - maxOffset) * 0.35 }
        if x < minOffset { return minOffset + (x - minOffset) * 0.35 }
        return x
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ZStack {
                // Полоса тиков — фиксированная ширина = count * tickSpacing.
                // Рисуем её выровненной по левому краю контейнера, а центрирование
                // делаем вручную через offset(centerX + offsetX).
                HStack(spacing: 0) {
                    ForEach(range, id: \.self) { i in
                        tickView(for: i)
                            .frame(width: tickSpacing, alignment: .center)
                    }
                }
                .padding(.vertical, 8)
                .offset(x: centerX + offsetX, y: 0)
                .frame(width: geo.size.width, height: 56, alignment: .leading)

                // Центральный индикатор (прозрачен для тапов — drag идёт по полосе).
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
            .contentShape(Rectangle())
            // Плавное затухание по краям.
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.00),
                        .init(color: .black,            location: 0.12),
                        .init(color: .black,            location: 0.88),
                        .init(color: .black.opacity(0), location: 1.00)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if dragStart == nil { dragStart = offsetX }
                        let raw = (dragStart ?? 0) + g.translation.width
                        offsetX = rubberBand(raw)
                        let v = valueAt(offsetX)
                        if v != lastHaptic {
                            UISelectionFeedbackGenerator().selectionChanged()
                            lastHaptic = v
                        }
                        if v != value { value = v }
                    }
                    .onEnded { g in
                        // Прогноз iOS — куда бы инерция затащила палец.
                        let start = dragStart ?? offsetX
                        let predictedRaw = start + g.predictedEndTranslation.width
                        // Всегда останавливаемся на существующем тике.
                        let targetValue = valueAt(predictedRaw)
                        let target = offsetFor(targetValue)
                        dragStart = nil
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            offsetX = target
                        }
                        if targetValue != value {
                            value = targetValue
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        lastHaptic = targetValue
                    }
            )
        }
        .frame(height: 56)
        // Внешние изменения value (loadData, программное обновление) синхронизируют
        // offsetX — но ТОЛЬКО если юзер сейчас не тянет. initial:true seed'ит позицию
        // при первом появлении.
        .onChange(of: value, initial: true) { _, new in
            guard dragStart == nil else { return }
            let target = offsetFor(new)
            if abs(offsetX - target) > 0.5 {
                offsetX = target
            }
            lastHaptic = new
        }
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
