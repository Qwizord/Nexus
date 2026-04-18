import SwiftUI
import PhotosUI

// MARK: - Profile View

@MainActor
struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
    private let heights = Array(100...250)
    private let weights = Array(30...300)

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

    private var fg: Color {
        colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // ── Аватар ──
                    let avatarData    = appState.userProfile?.avatarData
                    let userInitials  = appState.userProfile?.initials ?? "AN"
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let data = avatarData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(red: 0.0, green: 0.48, blue: 1.0),
                                                 Color(red: 0.34, green: 0.84, blue: 1.0)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                Text(userInitials)
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Circle()
                                .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // ── ИМЯ ──
                    profileSection(title: "Имя") {
                        ProfileField("Имя", text: $firstName)
                        profileDivider
                        ProfileField("Отчество", text: $middleName, placeholder: "Введите")
                        profileDivider
                        ProfileField("Фамилия", text: $lastName)
                        profileDivider
                        ProfileField("Username", text: $username)
                    }

                    // ── ФИЗИЧЕСКИЕ ДАННЫЕ ──
                    profileSection(title: "Физические данные") {
                        HStack {
                            Text("Рост")
                                .font(.system(size: 15))
                                .foregroundStyle(fg)
                            Spacer()
                            Picker("", selection: $heightInt) {
                                ForEach(heights, id: \.self) { h in
                                    Text("\(h) см").tag(h)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(fg.opacity(0.5))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        profileDivider
                        HStack {
                            Text("Вес")
                                .font(.system(size: 15))
                                .foregroundStyle(fg)
                            Spacer()
                            Picker("", selection: $weightInt) {
                                ForEach(weights, id: \.self) { w in
                                    Text("\(w) кг").tag(w)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(fg.opacity(0.5))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        profileDivider
                        HStack {
                            Text("Пол")
                                .font(.system(size: 15))
                                .foregroundStyle(fg)
                            Spacer()
                            Picker("", selection: $gender) {
                                ForEach(genders, id: \.self) { g in
                                    Text(g).tag(g)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(fg.opacity(0.5))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        profileDivider
                        DatePicker("Дата рождения", selection: $birthDate, displayedComponents: .date)
                            .foregroundStyle(fg)
                            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }

                    // ── ПРОИСХОЖДЕНИЕ ──
                    profileSection(title: "Происхождение") {
                        profileMenuRow(label: "Раса", value: race, options: races) { race = $0 }
                        profileDivider
                        profileMenuRow(label: "Этнос / Национальность", value: ethnicity, options: ethnicities) { ethnicity = $0 }
                    }

                    // ── ОБРАЗ ЖИЗНИ ──
                    profileSection(title: "Образ жизни") {
                        HStack {
                            Text("Тип питания")
                                .font(.system(size: 15))
                                .foregroundStyle(fg)
                            Spacer()
                            Menu {
                                ForEach(diets, id: \.self) { d in
                                    Button(d) { dietType = d }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(dietType == "Не указан" ? "Выбрать" : dietType)
                                        .font(.system(size: 14))
                                        .foregroundStyle(fg.opacity(0.5))
                                        .lineLimit(1)
                                        .frame(maxWidth: 200, alignment: .trailing)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(fg.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        profileDivider
                        HStack {
                            Text("Семейное положение")
                                .font(.system(size: 15))
                                .foregroundStyle(fg)
                            Spacer()
                            Menu {
                                ForEach(maritalOpts, id: \.self) { opt in
                                    Button(opt) { maritalStatus = opt }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(maritalStatus == "Не указан" ? "Выбрать" : maritalStatus)
                                        .font(.system(size: 14))
                                        .foregroundStyle(fg.opacity(0.5))
                                        .lineLimit(1)
                                        .frame(maxWidth: 160, alignment: .trailing)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(fg.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }

                    // ── МЕСТОПОЛОЖЕНИЕ ──
                    profileSection(title: "Местоположение") {
                        profileMenuRow(label: "Страна", value: country, options: countries) { country = $0 }
                        profileDivider
                        ProfileField("Город", text: $city)
                    }

                    // ── О СЕБЕ ──
                    profileSection(title: "О себе") {
                        ZStack(alignment: .topLeading) {
                            if bio.isEmpty {
                                Text("Биография")
                                    .foregroundStyle(fg.opacity(0.35))
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 14)
                            }
                            TextEditor(text: $bio)
                                .foregroundStyle(fg)
                                .font(.system(size: 15))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(white: 0.28))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { saveProfile() } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                                .frame(width: 44, height: 44)
                            if isSaving {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }
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

    // MARK: - Menu Row Helper

    @ViewBuilder
    func profileMenuRow(label: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(fg)
            Spacer()
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
                        .frame(maxWidth: 180, alignment: .trailing)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(fg.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Section Builder

    @ViewBuilder
    func profileSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.5)
                .textCase(.uppercase)
                .foregroundStyle(fg.opacity(0.35))
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(fg.opacity(0.08), lineWidth: 0.5))
        }
    }

    var profileDivider: some View {
        Divider()
            .background(.white.opacity(0.06))
            .padding(.leading, 16)
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
            dismiss()
        }
    }
}

// MARK: - ProfileField

private struct ProfileField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var prefix: String = ""
    @Environment(\.colorScheme) private var colorScheme
    private var fg: Color { colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14) }

    init(_ label: String, text: Binding<String>, placeholder: String = "", prefix: String = "") {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.prefix = prefix
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(fg)
            Spacer()
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
        .padding(.vertical, 13)
    }
}
