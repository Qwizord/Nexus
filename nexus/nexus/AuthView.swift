import SwiftUI
import AuthenticationServices
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

private struct LanguageOption: Identifiable {
    let id: String
    let name: String
    let flag: String
    let defaultCountryId: String
}

private struct CountryOption: Identifiable {
    let id: String
    let name: String
    let flag: String
    let code: String
}

private let countryOptions: [CountryOption] = [
    .init(id: "US", name: "United States", flag: "🇺🇸", code: "+1"),
    .init(id: "RU", name: "Россия", flag: "🇷🇺", code: "+7"),
    .init(id: "ES", name: "España", flag: "🇪🇸", code: "+34"),
    .init(id: "FR", name: "France", flag: "🇫🇷", code: "+33"),
    .init(id: "DE", name: "Deutschland", flag: "🇩🇪", code: "+49"),
    .init(id: "IT", name: "Italia", flag: "🇮🇹", code: "+39"),
    .init(id: "BR", name: "Brasil", flag: "🇧🇷", code: "+55"),
    .init(id: "JP", name: "日本", flag: "🇯🇵", code: "+81"),
    .init(id: "KR", name: "대한민국", flag: "🇰🇷", code: "+82"),
    .init(id: "CN", name: "中国", flag: "🇨🇳", code: "+86"),
    .init(id: "SA", name: "السعودية", flag: "🇸🇦", code: "+966"),
    .init(id: "IN", name: "भारत", flag: "🇮🇳", code: "+91"),
    .init(id: "TR", name: "Türkiye", flag: "🇹🇷", code: "+90"),
    .init(id: "UA", name: "Україна", flag: "🇺🇦", code: "+380"),
    .init(id: "PL", name: "Polska", flag: "🇵🇱", code: "+48"),
]

private let languageOptions: [LanguageOption] = [
    .init(id: "en_US", name: "United States", flag: "🇺🇸", defaultCountryId: "US"),
    .init(id: "ru_RU", name: "Россия", flag: "🇷🇺", defaultCountryId: "RU"),
    .init(id: "es_ES", name: "España", flag: "🇪🇸", defaultCountryId: "ES"),
    .init(id: "fr_FR", name: "France", flag: "🇫🇷", defaultCountryId: "FR"),
    .init(id: "de_DE", name: "Deutschland", flag: "🇩🇪", defaultCountryId: "DE"),
    .init(id: "it_IT", name: "Italia", flag: "🇮🇹", defaultCountryId: "IT"),
    .init(id: "pt_BR", name: "Brasil", flag: "🇧🇷", defaultCountryId: "BR"),
    .init(id: "ja_JP", name: "日本", flag: "🇯🇵", defaultCountryId: "JP"),
    .init(id: "ko_KR", name: "대한민국", flag: "🇰🇷", defaultCountryId: "KR"),
    .init(id: "zh_CN", name: "中国", flag: "🇨🇳", defaultCountryId: "CN"),
    .init(id: "ar_SA", name: "السعودية", flag: "🇸🇦", defaultCountryId: "SA"),
    .init(id: "hi_IN", name: "भारत", flag: "🇮🇳", defaultCountryId: "IN"),
    .init(id: "tr_TR", name: "Türkiye", flag: "🇹🇷", defaultCountryId: "TR"),
    .init(id: "uk_UA", name: "Україна", flag: "🇺🇦", defaultCountryId: "UA"),
    .init(id: "pl_PL", name: "Polska", flag: "🇵🇱", defaultCountryId: "PL"),
]

private func languageOption(for id: String) -> LanguageOption {
    languageOptions.first { $0.id == id } ?? languageOptions[0]
}

private func countryOption(for id: String) -> CountryOption {
    countryOptions.first { $0.id == id } ?? countryOptions[0]
}

private func defaultCountryOption(for languageId: String) -> CountryOption {
    let lang = languageOption(for: languageId)
    return countryOption(for: lang.defaultCountryId)
}

private func countryShortCode(for option: CountryOption) -> String {
    option.code
}

private enum AuthPalette {
    static func primary(_ cs: ColorScheme) -> Color {
        cs == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
    }
    static func secondary(_ cs: ColorScheme) -> Color {
        cs == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.45)
    }
    static func tertiary(_ cs: ColorScheme) -> Color {
        cs == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.35)
    }
    static func border(_ cs: ColorScheme) -> Color {
        cs == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12)
    }
    static func borderStrong(_ cs: ColorScheme) -> Color {
        cs == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.15)
    }
    static func divider(_ cs: ColorScheme) -> Color {
        cs == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12)
    }
}

private struct AuthSheetHeader: View {
    let title: String
    let subtitle: String
    let onClose: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuthPalette.primary(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AuthPalette.primary(colorScheme))
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(AuthPalette.secondary(colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
    }
}

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEmailSheet = false
    @State private var email = ""
    @State private var password = ""
    @State private var showRegistration = false
    @State private var showPhoneSheet = false
    @State private var phoneNumber = ""
    @State private var countryCode = "+7"
    @State private var previousPhoneValue = ""
    @State private var errorText: String?
    @FocusState private var focusField: FocusField?
    @FocusState private var phoneField: PhoneField?
    @State private var selectedLanguageId = "ru_RU"
    @State private var selectedCountryId = "RU"
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Namespace private var themeNamespace

    enum FocusField: Hashable { case email, password }
    enum PhoneField: Hashable { case code, number }

    var body: some View {
        ZStack {
            Group {
                if verticalSizeClass == .compact {
                    GeometryReader { geo in
                        ScrollView(showsIndicators: true) {
                            authContent.frame(minHeight: geo.size.height)
                        }
                        .scrollIndicators(.visible)
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    authContent
                }
            }
        }
        .dismissKeyboardOnTap()
        .onAppear {
            let stored = appState.settings.language
            selectedLanguageId = languageOptions.contains { $0.id == stored } ? stored : "ru_RU"
            let defaultCountry = defaultCountryOption(for: selectedLanguageId)
            selectedCountryId = defaultCountry.id
            countryCode = defaultCountry.code
        }
        .onChange(of: selectedLanguageId) { _, newValue in
            appState.settings.language = newValue
            let defaultCountry = defaultCountryOption(for: newValue)
            selectedCountryId = defaultCountry.id
            countryCode = defaultCountry.code
        }
        .sheet(isPresented: $showPhoneSheet) {
            phoneSheet
                .presentationDetents([.medium])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEmailSheet) {
            emailLoginSheet
                .presentationDetents([.medium])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView(isPresented: $showRegistration)
                .environmentObject(appState)
                .presentationDetents([.medium, .large])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
    }

    var authContent: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    themeAppearanceToggle
                    Spacer()
                    languageSwitcher
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer(minLength: 0)

                logoSection.padding(.bottom, 60)

                VStack(spacing: 12) {
                    appleSignInButton

                    GoogleAuthButton(title: "Войти через Google") {
                        errorText = nil
                        handleGoogleSignIn()
                    }

                    GlassAuthButton(
                        icon: "envelope.fill",
                        title: "Войти по email",
                        iconColor: AuthPalette.primary(colorScheme)
                    ) {
                        errorText = nil
                        showEmailSheet = true
                    }

                    HStack {
                        Rectangle().fill(AuthPalette.divider(colorScheme)).frame(height: 0.5)
                        Text("или")
                            .font(.system(size: 13))
                            .foregroundStyle(AuthPalette.tertiary(colorScheme))
                        Rectangle().fill(AuthPalette.divider(colorScheme)).frame(height: 0.5)
                    }
                    .padding(.vertical, 4)

                    GlassAuthButton(
                        icon: "phone.fill",
                        title: "По номеру телефона",
                        iconColor: AuthPalette.primary(colorScheme)
                    ) {
                        errorText = nil
                        showPhoneSheet = true
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: verticalSizeClass == .compact ? 480 : .infinity)

                if verticalSizeClass == .compact {
                    HStack(spacing: 4) {
                        Text("Нет аккаунта?")
                            .font(.system(size: 14))
                            .foregroundStyle(AuthPalette.secondary(colorScheme))
                        Button("Зарегистрироваться") {
                            showRegistration = true
                            errorText = nil
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AuthPalette.primary(colorScheme))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if verticalSizeClass == .regular {
                HStack(spacing: 4) {
                    Text("Нет аккаунта?")
                        .font(.system(size: 14))
                        .foregroundStyle(AuthPalette.secondary(colorScheme))
                    Button("Зарегистрироваться") {
                        showRegistration = true
                        errorText = nil
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AuthPalette.primary(colorScheme))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 0)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Theme helpers

    private func isThemeModeSelected(_ mode: AppTheme) -> Bool {
        switch appState.settings.theme {
        case .dark:   return mode == .dark
        case .light:  return mode == .light
        case .system: return (mode == .dark && colorScheme == .dark) || (mode == .light && colorScheme == .light)
        }
    }

    // MARK: - Theme Toggle — pure SwiftUI

    @ViewBuilder
    private var themeAppearanceToggle: some View {
        let isDark = isThemeModeSelected(.dark)

        ZStack(alignment: isDark ? .leading : .trailing) {
            // Sliding indicator
            Capsule()
                .fill(.regularMaterial)
                .frame(width: 44, height: 36)
                .padding(6)

            // Buttons
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
                        appState.settings.theme = .dark
                    }
                } label: {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isDark ? AuthPalette.primary(colorScheme) : AuthPalette.tertiary(colorScheme))
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.70)) {
                        appState.settings.theme = .light
                    }
                } label: {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(!isDark ? AuthPalette.primary(colorScheme) : AuthPalette.tertiary(colorScheme))
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 96, height: 48)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(AuthPalette.borderStrong(colorScheme), lineWidth: 0.5))
    }

    // MARK: - Language Switcher (без GlassEffectContainer — убирает лаг и микроанимацию)

    var languageSwitcher: some View {
        let option = languageOption(for: selectedLanguageId)
        return Menu {
            ForEach(languageOptions) { lang in
                Button {
                    selectedLanguageId = lang.id
                } label: {
                    Text("\(lang.flag) \(lang.name)")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(option.flag)
                Text(option.name)
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AuthPalette.secondary(colorScheme))
            }
            .foregroundStyle(AuthPalette.primary(colorScheme))
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(AuthPalette.borderStrong(colorScheme), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        // Отключаем встроенную анимацию лейбла при смене языка
        .transaction { $0.animation = nil }
    }

    // MARK: - Subviews

    var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(AuthPalette.borderStrong(colorScheme), lineWidth: 0.5)
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AuthPalette.primary(colorScheme))
            }
            VStack(spacing: 6) {
                Text("Nexus")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AuthPalette.primary(colorScheme))
                Text("Твой AI-ассистент для роста")
                    .font(.system(size: 16))
                    .foregroundStyle(AuthPalette.secondary(colorScheme))
            }
        }
    }

    var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let auth): handleAppleAuth(auth)
            case .failure(let error):
                errorText = "Ошибка входа Apple"
                print(error)
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AuthPalette.borderStrong(colorScheme), lineWidth: 0.5)
        )
        .edgeSheen(cornerRadius: 16)
    }

    var emailLoginSheet: some View {
        ZStack {
            Color.clear
            VStack(spacing: 0) {
                AuthSheetHeader(title: "Вход по email", subtitle: "Введи адрес почты и пароль от аккаунта") {
                    showEmailSheet = false
                }
                VStack(spacing: 12) {
                    HStack {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($focusField, equals: .email)
                            .foregroundStyle(AuthPalette.primary(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                    .contentShape(Rectangle())
                    .onTapGesture { focusField = .email }

                    HStack {
                        SecureField("Пароль", text: $password)
                            .focused($focusField, equals: .password)
                            .foregroundStyle(AuthPalette.primary(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                    .contentShape(Rectangle())
                    .onTapGesture { focusField = .password }

                    if let err = errorText {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    Button { handleEmailAuth() } label: {
                        Text("Войти")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
        }
        .contentShape(Rectangle())
        .dismissKeyboardOnTap()
        .onAppear { focusField = .email }
    }

    // MARK: - Handlers

    func handleAppleAuth(_ auth: ASAuthorization) {
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
            errorText = "Не удалось получить данные Apple"; return
        }
        let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }
        let fullName = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")
        appState.signIn(with: AuthUser(provider: .apple, email: credential.email, phone: nil, fullName: fullName, password: nil, appleUserId: credential.user))
    }

    func handleEmailAuth() {
        errorText = nil
        let cleanEmail    = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(cleanEmail)   else { errorText = "Введите корректный email"; return }
        guard cleanPassword.count >= 6   else { errorText = "Пароль должен быть не короче 6 символов"; return }

        #if canImport(FirebaseAuth)
        Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword) { authResult, error in
            if let error { DispatchQueue.main.async { errorText = "Неверный email или пароль" }; print(error); return }
            if let user = authResult?.user {
                DispatchQueue.main.async { finalizeFirebaseUser(user, provider: .email, fullName: nil); showEmailSheet = false }
            }
        }
        #else
        if !appState.signInEmail(email: cleanEmail, password: cleanPassword) { errorText = "Неверный email или пароль" } else { showEmailSheet = false }
        #endif
    }

    func handleGoogleSignIn() {
        errorText = nil
        #if canImport(GoogleSignIn) && canImport(FirebaseAuth)
        guard let root = rootViewController() else { errorText = "Не удалось открыть Google вход"; return }
        #if canImport(FirebaseCore)
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        #endif
        GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
            if let error { errorText = "Ошибка входа Google"; print(error); return }
            guard let result else { errorText = "Не удалось получить данные Google"; return }
            guard let idToken = result.user.idToken?.tokenString else { errorText = "Не удалось получить токен Google"; return }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error { errorText = "Ошибка входа Google"; print(error); return }
                if let user = authResult?.user { finalizeFirebaseUser(user, provider: .google, fullName: result.user.profile?.name) }
            }
        }
        #else
        errorText = "Google Sign-In SDK не подключен"
        #endif
    }

    func isValidEmail(_ value: String) -> Bool { value.contains("@") && value.contains(".") && value.count >= 5 }

    var phoneSheet: some View {
        ZStack {
            Color.clear
            VStack(spacing: 0) {
                AuthSheetHeader(title: "Вход по номеру", subtitle: "Выбери код страны и введи номер") {
                    showPhoneSheet = false
                }
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Menu {
                                ForEach(countryOptions) { option in
                                    Button {
                                        selectedCountryId = option.id
                                        countryCode = option.code
                                    } label: { Text("\(option.flag) \(countryShortCode(for: option))") }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    let current = countryOption(for: selectedCountryId)
                                    Text(current.flag)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AuthPalette.secondary(colorScheme))
                                }
                                .foregroundStyle(AuthPalette.primary(colorScheme))
                            }
                            Divider().frame(height: 18).background(AuthPalette.divider(colorScheme))
                            TextField("+7", text: $countryCode)
                                .keyboardType(.phonePad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(AuthPalette.primary(colorScheme))
                                .focused($phoneField, equals: .code)
                        }
                        .frame(width: 96)
                        .padding(.horizontal, 12).padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                        .contentShape(Rectangle())
                        .onTapGesture { phoneField = .code }

                        TextField("(999) 942-42-42", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundStyle(AuthPalette.primary(colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12).padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                            .contentShape(Rectangle())
                            .focused($phoneField, equals: .number)
                            .onTapGesture { phoneField = .number }
                            .onChange(of: phoneNumber) { _, newValue in
                                let formatted = formatPhoneDigits(newValue, previous: previousPhoneValue, countryCode: countryCode)
                                if formatted != newValue { phoneNumber = formatted }
                                previousPhoneValue = formatted
                            }
                    }

                    Text("SMS‑вход временно недоступен без платного Apple Developer.")
                        .font(.system(size: 12))
                        .foregroundStyle(AuthPalette.secondary(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Button("Скоро") {}
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AuthPalette.tertiary(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            (colorScheme == .dark ? Color.white : Color.black).opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .disabled(true)
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
        }
        .contentShape(Rectangle())
        .dismissKeyboardOnTap()
        .onAppear {
            let defaultCountry = defaultCountryOption(for: selectedLanguageId)
            if countryCode.isEmpty { countryCode = defaultCountry.code }
            selectedCountryId = defaultCountry.id
        }
    }

    func finalizeFirebaseUser(_ user: User, provider: AuthProvider, fullName: String?) {
        appState.signIn(with: AuthUser(provider: provider, email: user.email, phone: user.phoneNumber, fullName: fullName, password: nil, appleUserId: provider == .apple ? user.uid : nil))
    }

    func rootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        return scene.windows.first { $0.isKeyWindow }?.rootViewController
    }

    func formatPhoneDigits(_ value: String, previous: String, countryCode: String) -> String {
        var digits = value.filter { $0.isNumber }
        let prevDigits = previous.filter { $0.isNumber }
        if value.count < previous.count, digits.count == prevDigits.count, !digits.isEmpty { digits = String(digits.dropLast()) }
        let countryDigits = countryCode.filter { $0.isNumber }
        if !countryDigits.isEmpty, digits.hasPrefix(countryDigits), digits.count == countryDigits.count + 10 {
            digits = String(digits.dropFirst(countryDigits.count))
        }
        if digits.isEmpty { return "" }
        var result = ""
        let chars = Array(digits)
        if !chars.isEmpty { result.append("(") }
        for i in 0..<min(chars.count, 10) {
            let ch = chars[i]
            switch i {
            case 0...2: result.append(ch); if i == 2 { result.append(") ") }
            case 3...5: result.append(ch); if i == 5 { result.append("-") }
            case 6...7: result.append(ch); if i == 7 { result.append("-") }
            default:    result.append(ch)
            }
        }
        return result
    }
}

// MARK: - RegistrationView

struct RegistrationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verificationCode = ""
    @State private var awaitingCode = false
    @State private var errorText: String?
    @FocusState private var focusField: FocusField?
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    enum FocusField: Hashable { case email, password, confirm, code }

    var body: some View {
        ZStack {
            Color.clear
            if verticalSizeClass == .compact {
                ScrollView(showsIndicators: true) { registrationContent }.scrollIndicators(.visible)
            } else {
                registrationContent
            }
        }
        .dismissKeyboardOnTap()
    }

    var registrationContent: some View {
        VStack(spacing: 0) {
            AuthSheetHeader(title: "Регистрация", subtitle: "Создай аккаунт, для новых достижений") {
                isPresented = false; dismiss()
            }
            VStack(spacing: 12) {
                if !awaitingCode {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled(true)
                        .focused($focusField, equals: .email).foregroundStyle(AuthPalette.primary(colorScheme))
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                        .contentShape(Rectangle()).onTapGesture { focusField = .email }

                    SecureField("Пароль", text: $password)
                        .focused($focusField, equals: .password).foregroundStyle(AuthPalette.primary(colorScheme))
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                        .contentShape(Rectangle()).onTapGesture { focusField = .password }

                    SecureField("Повтори пароль", text: $confirmPassword)
                        .focused($focusField, equals: .confirm).foregroundStyle(AuthPalette.primary(colorScheme))
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                        .contentShape(Rectangle()).onTapGesture { focusField = .confirm }
                } else {
                    Text("Мы отправили код подтверждения на почту.")
                        .font(.system(size: 14)).foregroundStyle(AuthPalette.secondary(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Код из письма", text: $verificationCode)
                        .keyboardType(.numberPad).focused($focusField, equals: .code).foregroundStyle(AuthPalette.primary(colorScheme))
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                        .contentShape(Rectangle()).onTapGesture { focusField = .code }
                }

                if !awaitingCode, !password.isEmpty, !confirmPassword.isEmpty, password != confirmPassword {
                    Text("Пароли не совпадают").font(.system(size: 13)).foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center).padding(.horizontal, 12)
                }
                if let errorText {
                    Text(errorText).font(.system(size: 13)).foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center).padding(.horizontal, 12)
                }

                Button {
                    awaitingCode ? verifyCodeAndFinish() : createAccount()
                } label: {
                    Text(awaitingCode ? "Подтвердить" : "Создать аккаунт")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSubmit ? Color.white : AuthPalette.primary(colorScheme))
                        .frame(maxWidth: verticalSizeClass == .compact ? 160 : 200)
                        .padding(.vertical, 14)
                        .background(
                            canSubmit
                            ? LinearGradient(colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [(colorScheme == .dark ? Color.white : Color.black).opacity(0.12), (colorScheme == .dark ? Color.white : Color.black).opacity(0.12)], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
    }

    var canSubmit: Bool {
        if awaitingCode { return verificationCode.trimmingCharacters(in: .whitespaces).count >= 4 }
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return e.contains("@") && e.contains(".") && p.count >= 6 && c.count >= 6 && p == c
    }

    func createAccount() {
        errorText = nil
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard e.contains("@"), e.contains(".") else { errorText = "Введите корректный email"; return }
        guard p.count >= 6 else { errorText = "Пароль должен быть не короче 6 символов"; return }
        guard p == c else { errorText = "Пароли не совпадают"; return }
        #if canImport(FirebaseAuth)
        Auth.auth().createUser(withEmail: e, password: p) { authResult, error in
            if let error { errorText = "Не удалось создать аккаунт"; print(error); return }
            if let user = authResult?.user { user.sendEmailVerification(completion: nil); awaitingCode = true }
        }
        #else
        awaitingCode = true
        #endif
    }

    func verifyCodeAndFinish() {
        guard canSubmit else { return }
        appState.signIn(with: AuthUser(provider: .email, email: email.trimmingCharacters(in: .whitespacesAndNewlines), phone: nil, fullName: nil, password: nil, appleUserId: nil))
        isPresented = false
    }
}

// MARK: - GlassAuthButton

struct GlassAuthButton: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(iconColor).frame(width: 24)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(AuthPalette.primary(colorScheme))
                Spacer()
            }
            .padding(.horizontal, 20).frame(height: 54)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AuthPalette.borderStrong(colorScheme), lineWidth: 0.5))
            .edgeSheen(cornerRadius: 16)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.2)) { pressed = true } }
            .onEnded   { _ in withAnimation(.spring(response: 0.3)) { pressed = false } }
        )
    }
}

// MARK: - GoogleAuthButton

struct GoogleAuthButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("Google-icon").resizable().scaledToFit().frame(width: 18, height: 18).frame(width: 24)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(AuthPalette.primary(colorScheme))
                Spacer()
            }
            .padding(.horizontal, 20).frame(height: 54)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AuthPalette.borderStrong(colorScheme), lineWidth: 0.5))
            .edgeSheen(cornerRadius: 16)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.2)) { pressed = true } }
            .onEnded   { _ in withAnimation(.spring(response: 0.3)) { pressed = false } }
        )
    }
}

// MARK: - GoogleLogoIcon

struct GoogleLogoIcon: View {
    let size: CGFloat
    var body: some View {
        Canvas { context, canvasSize in
            let lineWidth = canvasSize.width * 0.22
            let radius = min(canvasSize.width, canvasSize.height) / 2 - lineWidth / 2
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            func strokeArc(_ start: Double, _ end: Double, color: Color) {
                var path = Path()
                path.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
            strokeArc(-45, 45,  color: Color(red: 0.26, green: 0.52, blue: 0.96))
            strokeArc(45,  140, color: Color(red: 0.92, green: 0.26, blue: 0.22))
            strokeArc(140, 220, color: Color(red: 0.98, green: 0.74, blue: 0.02))
            strokeArc(220, 315, color: Color(red: 0.20, green: 0.66, blue: 0.33))
            let barHeight = lineWidth * 0.7
            let barRect = CGRect(x: center.x, y: center.y - barHeight / 2, width: radius * 0.9, height: barHeight)
            context.fill(Path(roundedRect: barRect, cornerRadius: barHeight / 2), with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Theme Segmented Control (UIViewRepresentable)
// Позволяет задать точную высоту UISegmentedControl через SwiftUI .frame()

private struct ThemeSegmentedControl: UIViewRepresentable {
    @Binding var selection: AppTheme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: [
            UIImage(systemName: "moon.fill") as Any,
            UIImage(systemName: "sun.max.fill") as Any
        ])
        control.selectedSegmentIndex = selection == .dark ? 0 : 1
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        let idx = selection == .dark ? 0 : 1
        if uiView.selectedSegmentIndex != idx {
            uiView.selectedSegmentIndex = idx
        }
    }

    class Coordinator: NSObject {
        let parent: ThemeSegmentedControl
        init(_ parent: ThemeSegmentedControl) { self.parent = parent }
        @objc func valueChanged(_ sender: UISegmentedControl) {
            parent.selection = sender.selectedSegmentIndex == 0 ? .dark : .light
        }
    }
}
