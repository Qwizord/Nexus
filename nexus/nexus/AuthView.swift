import SwiftUI
import Combine
import AuthenticationServices
import UIKit
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
            .padding(.top, 20)

            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AuthPalette.primary(colorScheme))
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(AuthPalette.secondary(colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Typewriter View

private struct TypewriterText: View {
    let phrases: [String]
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayed = ""
    @State private var phraseIndex: Int
    @State private var charIndex = 0
    @State private var isDeleting = false
    @State private var cursorVisible = true
    @State private var timer: Timer?
    @State private var cursorTimer: Timer?

    private let typeSpeed: TimeInterval = 0.055
    private let deleteSpeed: TimeInterval = 0.03
    private let pauseAfterType: TimeInterval = 1.8
    private let pauseAfterDelete: TimeInterval = 0.4

    init(phrases: [String]) {
        self.phrases = phrases
        _phraseIndex = State(initialValue: Int.random(in: 0..<phrases.count))
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(displayed)
                .font(.system(size: 16))
                .foregroundStyle(AuthPalette.secondary(colorScheme))
            Rectangle()
                .fill(AuthPalette.primary(colorScheme).opacity(0.65))
                .frame(width: 2.4, height: 18)
                .opacity(cursorVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: cursorVisible)
        }
        .onAppear { startCursor(); scheduleNext(delay: 0.5) }
        .onDisappear { timer?.invalidate(); cursorTimer?.invalidate() }
    }

    private func startCursor() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }

    private func scheduleNext(delay: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            tick()
        }
    }

    private func tick() {
        let phrase = phrases[phraseIndex]
        if !isDeleting {
            if charIndex < phrase.count {
                charIndex += 1
                displayed = String(phrase.prefix(charIndex))
                scheduleNext(delay: typeSpeed)
            } else {
                isDeleting = true
                scheduleNext(delay: pauseAfterType)
            }
        } else {
            if charIndex > 0 {
                charIndex -= 1
                displayed = String(phrase.prefix(charIndex))
                scheduleNext(delay: deleteSpeed)
            } else {
                isDeleting = false
                phraseIndex = (phraseIndex + 1) % phrases.count
                scheduleNext(delay: pauseAfterDelete)
            }
        }
    }
}

// MARK: - Auth Animated Background

private struct AuthBackgroundView: View {
    let theme: AppTheme
    var body: some View {
        FlameBackground(forceScheme: theme == .dark ? .dark : .light)
            .ignoresSafeArea()
    }
}


// MARK: - iOS 18 MeshGradient

@available(iOS 18.0, *)
private struct MeshBackground: View {
    let isDark: Bool
    @State private var flipped = false

    // Точки A и B — MeshGradient анимирует между ними через withAnimation
    private let pointsA: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5,  0.0], [1.0, 0.0],
        [0.0, 0.5], [0.55, 0.42], [1.0, 0.5],
        [0.0, 1.0], [0.5,  1.0], [1.0, 1.0],
    ]
    private let pointsB: [SIMD2<Float>] = [
        [0.0, 0.0], [0.44, 0.0], [1.0, 0.0],
        [0.0, 0.5], [0.40, 0.60], [1.0, 0.5],
        [0.0, 1.0], [0.58, 1.0], [1.0, 1.0],
    ]

    // Тёмные синие цвета
    private let darkColors: [Color] = [
        Color(red: 0.02, green: 0.02, blue: 0.12),   // TL — почти чёрный синий
        Color(red: 0.05, green: 0.08, blue: 0.35),   // TC — тёмный синий
        Color(red: 0.02, green: 0.02, blue: 0.10),   // TR
        Color(red: 0.04, green: 0.06, blue: 0.28),   // ML
        Color(red: 0.10, green: 0.18, blue: 0.65),   // MC — яркий синий акцент
        Color(red: 0.03, green: 0.04, blue: 0.20),   // MR
        Color(red: 0.02, green: 0.02, blue: 0.08),   // BL
        Color(red: 0.06, green: 0.10, blue: 0.38),   // BC
        Color(red: 0.02, green: 0.02, blue: 0.10),   // BR
    ]

    // Светлые цвета — более явные синие оттенки
    private let lightColors: [Color] = [
        Color(red: 0.78, green: 0.84, blue: 1.00),
        Color(red: 0.55, green: 0.65, blue: 0.97),
        Color(red: 0.85, green: 0.90, blue: 1.00),
        Color(red: 0.62, green: 0.72, blue: 0.98),
        Color(red: 0.90, green: 0.94, blue: 1.00),
        Color(red: 0.58, green: 0.68, blue: 0.97),
        Color(red: 0.80, green: 0.87, blue: 1.00),
        Color(red: 0.60, green: 0.70, blue: 0.97),
        Color(red: 0.86, green: 0.92, blue: 1.00),
    ]

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: flipped ? pointsB : pointsA,
            colors: isDark ? darkColors : lightColors,
            smoothsColors: true
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true)
            ) {
                flipped = true
            }
        }
    }
}

// MARK: - Fallback iOS 17

private struct MeshBackgroundFallback: View {
    let isDark: Bool
    @State private var t: Double = 0
    private let timer = Timer.publish(every: 1.0 / 24.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas(opaque: true) { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(isDark ? Color(red:0.02,green:0.02,blue:0.12) : Color(red:0.90,green:0.93,blue:1.00)))
            let blobs: [(Double,Double,Double, Double,Double, Double,Double, Double,Double)] = isDark
            ? [
                (0.10,0.18,0.65, 0.14,0.11, 0.0,0.0, 0.32,0.38),
                (0.05,0.10,0.42, 0.09,0.13, 2.1,1.4, 0.40,0.28),
                (0.08,0.14,0.55, 0.11,0.08, 4.2,3.0, 0.26,0.42),
                (0.04,0.07,0.32, 0.07,0.12, 1.5,5.3, 0.44,0.24),
              ]
            : [
                (0.72,0.78,0.98, 0.14,0.11, 0.0,0.0, 0.32,0.38),
                (0.78,0.84,0.99, 0.09,0.13, 2.1,1.4, 0.40,0.28),
                (0.74,0.80,0.98, 0.11,0.08, 4.2,3.0, 0.26,0.42),
                (0.80,0.86,0.99, 0.07,0.12, 1.5,5.3, 0.44,0.24),
              ]
            for (r,g,b,xF,yF,xP,yP,xA,yA) in blobs {
                let cx = size.width  * (0.5 + xA * sin(t * xF + xP))
                let cy = size.height * (0.5 + yA * cos(t * yF + yP))
                let rad = max(size.width, size.height) * 0.72
                let grad = Gradient(stops: [
                    .init(color: Color(red:r,green:g,blue:b).opacity(isDark ? 0.90 : 0.65), location: 0),
                    .init(color: Color(red:r,green:g,blue:b).opacity(0.20), location: 0.55),
                    .init(color: .clear, location: 1),
                ])
                var bCtx = ctx; bCtx.blendMode = isDark ? .screen : .multiply
                bCtx.fill(
                    Path(ellipseIn: CGRect(x:cx-rad,y:cy-rad,width:rad*2,height:rad*2)),
                    with: .radialGradient(grad, center:.init(x:cx,y:cy), startRadius:0, endRadius:rad)
                )
            }
        }
        .onReceive(timer) { _ in t += 1.0 / 24.0 }
    }
}

// MARK: - Animated Grain (быстро мелькающий шум)

private struct AnimatedGrainOverlay: View {
    let isDark: Bool

    // Тёмные кадры для тёмной темы (белые пиксели → .overlay)
    private static let darkFrames: [UIImage] = makeFrames(light: false)
    // Тёмные пиксели для светлой темы (чёрные пиксели → .multiply даёт тёмный шум)
    private static let lightFrames: [UIImage] = makeFrames(light: true)

    private static func makeFrames(light: Bool) -> [UIImage] {
        (0..<6).map { seed in
            let side = 128
            UIGraphicsBeginImageContextWithOptions(.init(width: side, height: side), false, 1)
            let ctx = UIGraphicsGetCurrentContext()!
            var s = UInt64(bitPattern: Int64(seed &* 2654435761 &+ 1013904223)) | 1
            for y in 0..<side {
                for x in 0..<side {
                    s ^= s << 13; s ^= s >> 7; s ^= s << 17
                    let v = CGFloat(s & 0xff) / 255.0
                    if light {
                        // Светлая тема: только тёмные пиксели, высокая альфа
                        let a = (1.0 - v) * (1.0 - v) * 0.55
                        ctx.setFillColor(UIColor(white: 0, alpha: a).cgColor)
                    } else {
                        // Тёмная тема: белые и чёрные пиксели
                        let a = v * v * 0.50
                        ctx.setFillColor(UIColor(white: v > 0.5 ? 1 : 0, alpha: a).cgColor)
                    }
                    ctx.fill(.init(x: x, y: y, width: 1, height: 1))
                }
            }
            let img = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return img
        }
    }

    @State private var frameIndex = 0
    private let timer = Timer.publish(every: 1.0 / 20.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Image(uiImage: isDark ? Self.darkFrames[frameIndex] : Self.lightFrames[frameIndex])
            .resizable(resizingMode: .tile)
            .blendMode(isDark ? .overlay : .multiply)
            .opacity(isDark ? 0.32 : 0.45)
            .allowsHitTesting(false)
            .onReceive(timer) { _ in
                frameIndex = (frameIndex + 1) % 6
            }
    }
}

// MARK: - Phrases

private let authPhrases: [String] = [
    "Твой AI-ассистент для роста",
    "Здоровье, финансы, обучение — всё здесь",
    "Достигай целей вместе с AI",
    "Умный трекер твоей жизни",
    "Один помощник для всего важного",
    "Анализируй, планируй, достигай",
    "Твой личный коуч в кармане",
    "AI который знает тебя лучше всех",
    "Прокачивай себя каждый день",
    "Nexus — точка роста твоей жизни",
]

// MARK: - AuthView

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEmailSheet = false
    @State private var email = ""
    @State private var password = ""
    @State private var showRegistration = false
    @State private var showPhoneSheet = false
    @State private var showEmailPassword = false
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
            // Фон читает тему из appState напрямую — не зависит от colorScheme
            AuthBackgroundView(theme: appState.settings.theme)

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
                        .ignoresSafeArea(.keyboard)
                }
            }
        }
        .tint(colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14))
        .dismissKeyboardOnTap()
        .onAppear {
            let stored = appState.settings.language
            selectedLanguageId = languageOptions.contains { $0.id == stored } ? stored : "ru_RU"
            let defaultCountry = defaultCountryOption(for: selectedLanguageId)
            selectedCountryId = defaultCountry.id
            countryCode = defaultCountry.code
        }
        .onChange(of: selectedLanguageId) { _, newValue in
            let defaultCountry = defaultCountryOption(for: newValue)
            selectedCountryId = defaultCountry.id
            countryCode = defaultCountry.code
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                appState.settings.language = newValue
            }
        }
        .sheet(isPresented: $showPhoneSheet) {
            phoneSheet
                .tint(colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14))
                .presentationDetents([.height(320)])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
                .environment(\.colorScheme, colorScheme)
                .preferredColorScheme(colorScheme == .dark ? .dark : .light)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(320)))
        }
        .sheet(isPresented: $showEmailSheet) {
            emailLoginSheet
                .tint(colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14))
                .presentationDetents([.height(420)])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
                .environment(\.colorScheme, colorScheme)
                .preferredColorScheme(colorScheme == .dark ? .dark : .light)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(420)))
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView(isPresented: $showRegistration)
                .tint(colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14))
                .environmentObject(appState)
                .presentationDetents([.medium, .large])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
                .preferredColorScheme(colorScheme == .dark ? .dark : .light)
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
                .padding(.top, verticalSizeClass == .compact ? 28 : 14)

                Spacer(minLength: 0)

                logoSection.padding(.bottom, verticalSizeClass == .compact ? 42 : 60)

                VStack(spacing: 12) {
                    appleSignInButton

                    GoogleAuthButton(title: L("auth.google")) {
                        errorText = nil
                        handleGoogleSignIn()
                    }

                    GlassAuthButton(
                        icon: "envelope.fill",
                        title: L("auth.email_login")
                    ) {
                        errorText = nil
                        showEmailSheet = true
                    }

                    HStack {
                        Rectangle().fill(AuthPalette.divider(colorScheme)).frame(height: 0.5)
                        Text(L("auth.or"))
                            .font(.system(size: 13))
                            .foregroundStyle(AuthPalette.tertiary(colorScheme))
                        Rectangle().fill(AuthPalette.divider(colorScheme)).frame(height: 0.5)
                    }
                    .padding(.vertical, 4)

                    GlassAuthButton(
                        icon: "phone.fill",
                        title: L("auth.phone")
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

    private func effectiveThemeMode() -> AppTheme {
        switch appState.settings.theme {
        case .dark, .light:
            return appState.settings.theme
        case .system:
            return colorScheme == .dark ? .dark : .light
        }
    }

    private func isThemeModeSelected(_ mode: AppTheme) -> Bool {
        effectiveThemeMode() == mode
    }

    // MARK: - Theme Toggle — Floating glass pill with fluid drag

    private static let themeItems: [(AppTheme, String)] = [
        (.dark,  "moon.fill"),
        (.light, "sun.max.fill"),
    ]
    private let themeItemW: CGFloat = 52
    private let themeH: CGFloat = 44

    /// nil = not dragging; otherwise = thumb left-edge progress between 0 and 1
    @State private var themeDragProgress: CGFloat? = nil
    @State private var themeDraggedTheme: AppTheme? = nil

    @ViewBuilder
    private var themeAppearanceToggle: some View {
        let items   = Self.themeItems
        let selIdx  = isThemeModeSelected(.dark) ? 0 : 1
        let totalW  = themeItemW * CGFloat(items.count)
        let pad: CGFloat = 4
        let thumbTravel = totalW - themeItemW
        let indicatorX: CGFloat = {
            if let progress = themeDragProgress {
                return thumbTravel * progress + pad / 2
            }
            return CGFloat(selIdx) * themeItemW + pad / 2
        }()

        ZStack(alignment: .leading) {
            // Sliding indicator
            Capsule()
                .fill(AuthPalette.primary(colorScheme).opacity(0.25))
                .frame(width: themeItemW - pad, height: themeH - pad)
                .offset(x: indicatorX)
                .animation(themeDragProgress == nil
                    ? .spring(response: 0.35, dampingFraction: 0.78)
                    : .interactiveSpring(response: 0.18, dampingFraction: 0.85),
                    value: indicatorX)

            // Icons
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    let (theme, icon) = item
                    let selected = isThemeModeSelected(theme)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(selected ? AuthPalette.primary(colorScheme) : AuthPalette.primary(colorScheme).opacity(0.38))
                        .frame(width: themeItemW, height: themeH)
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                themeDragProgress = nil
                                themeDraggedTheme = nil
                                appState.settings.theme = theme
                            }
                        }
                }
            }
        }
        .frame(width: totalW, height: themeH)
        .contentShape(Capsule())
        .glassEffect(.regular.interactive(), in: Capsule())
        .simultaneousGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    let leftEdge = min(max(value.location.x - themeItemW / 2, 0), thumbTravel)
                    let progress = thumbTravel == 0 ? 0 : leftEdge / thumbTravel
                    let idx = progress >= 0.5 ? 1 : 0
                    let theme = items[idx].0
                    themeDragProgress = progress

                    guard themeDraggedTheme != theme else { return }
                    themeDraggedTheme = theme
                    guard appState.settings.theme != theme else { return }
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.86)) {
                        appState.settings.theme = theme
                    }
                }
                .onEnded { value in
                    let leftEdge = min(max(value.location.x - themeItemW / 2, 0), thumbTravel)
                    let progress = thumbTravel == 0 ? 0 : leftEdge / thumbTravel
                    let idx = progress >= 0.5 ? 1 : 0
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        appState.settings.theme = items[idx].0
                        themeDragProgress = nil
                        themeDraggedTheme = nil
                    }
                }
        )
    }

    // MARK: - Language Switcher — Liquid Glass

    var languageSwitcher: some View {
        let option = languageOption(for: selectedLanguageId)
        return ZStack {
            HStack(spacing: 6) {
                Text(option.flag)
                    .font(.system(size: 14))
                Text(option.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AuthPalette.primary(colorScheme))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AuthPalette.secondary(colorScheme))
            }
            .foregroundStyle(AuthPalette.primary(colorScheme))
            .padding(.horizontal, 14)
            .frame(height: 44)
            .animation(nil, value: option.name)
            .glassEffect(.regular.interactive(), in: Capsule())
            .allowsHitTesting(false)

            Menu {
                ForEach(languageOptions) { lang in
                    Button {
                        selectedLanguageId = lang.id
                    } label: {
                        Text("\(lang.flag) \(lang.name)")
                    }
                }
            } label: {
                Capsule()
                    .fill(.clear)
                    .frame(minWidth: 148, minHeight: 44)
                    .contentShape(Capsule())
            }
        }
        .fixedSize()
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .transaction { $0.animation = nil }
    }

    // MARK: - Subviews

    var logoSection: some View {
        VStack(spacing: 12) {
            Image("Logo_Main")
                .resizable()
                .scaledToFit()
                .frame(height: 72)
                .colorMultiply(colorScheme == .dark ? .white : .black)
            TypewriterText(phrases: authPhrases)
                .frame(height: 20)
        }
    }

    var appleSignInButton: some View {
        ZStack {
            // Невидимая нативная кнопка — получает тапы
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
            .opacity(0.001)

            // Визуальная белая кнопка — не перехватывает тапы
            HStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18))
                    .foregroundStyle(.black)
                Text("Вход с Apple")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
            .allowsHitTesting(false)
        }
        .frame(height: 54)
    }

    var canSubmitEmail: Bool {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return e.contains("@") && e.contains(".") && e.count >= 5 && p.count >= 6
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
                    .frame(height: 50)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
                    .contentShape(Rectangle())
                    .onTapGesture { focusField = .email }

                    HStack {
                        ZStack(alignment: .leading) {
                            if showEmailPassword {
                                TextField("Пароль", text: $password)
                                    .textContentType(.oneTimeCode)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .foregroundStyle(AuthPalette.primary(colorScheme))
                                    .tint(AuthPalette.primary(colorScheme))
                                    .focused($focusField, equals: .password)
                            } else {
                                AuthSecureInputField(
                                    placeholder: "Пароль",
                                    text: $password,
                                    isFirstResponder: focusField == .password,
                                    textColor: UIColor(AuthPalette.primary(colorScheme)),
                                    placeholderColor: UIColor(AuthPalette.secondary(colorScheme)),
                                    textContentType: .oneTimeCode
                                ) { isFocused in
                                    if isFocused {
                                        focusField = .password
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            showEmailPassword.toggle()
                            DispatchQueue.main.async { focusField = .password }
                        } label: {
                            Image(systemName: showEmailPassword ? "eye" : "eye.slash")
                                .foregroundStyle(AuthPalette.secondary(colorScheme))
                                .frame(width: 24)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .frame(height: 50)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))

                    if let err = errorText {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(height: 16)
                    }

                    Button { handleEmailAuth() } label: {
                        Text("Войти")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(canSubmitEmail ? Color.white : AuthPalette.secondary(colorScheme))
                            .frame(width: 180)
                            .padding(.vertical, 16)
                            .background {
                                AuthPrimaryActionBackground(isEnabled: canSubmitEmail)
                            }
                    }
                    .disabled(!canSubmitEmail)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
        }
        .dismissKeyboardOnTap()
        .ignoresSafeArea(.keyboard)
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
                                    } label: { Text("\(option.flag) \(option.name)  \(option.code)") }
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
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
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
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))
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
                        .frame(width: 180)
                        .padding(.vertical, 14)
                        .background(
                            (colorScheme == .dark ? Color.white : Color.black).opacity(0.08),
                            in: Capsule()
                        )
                        .disabled(true)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
        }
        .dismissKeyboardOnTap()
        .ignoresSafeArea(.keyboard)
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
    @State private var errorText: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusField: FocusField?
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    enum FocusField: Hashable { case email, password, confirm }

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
        .tint(colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14))
    }

    var registrationContent: some View {
        VStack(spacing: 0) {
            AuthSheetHeader(title: "Регистрация", subtitle: "Создай аккаунт, для новых достижений") {
                isPresented = false; dismiss()
            }
            VStack(spacing: 12) {
                // Email
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(.emailAddress)
                    .focused($focusField, equals: .email)
                    .foregroundStyle(AuthPalette.primary(colorScheme))
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .frame(height: 50)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))

                // Пароль
                HStack {
                    ZStack(alignment: .leading) {
                        if showPassword {
                            TextField("Пароль", text: $password)
                                .textContentType(.newPassword)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .foregroundStyle(AuthPalette.primary(colorScheme))
                                .focused($focusField, equals: .password)
                        } else {
                            AuthSecureInputField(
                                placeholder: "Пароль",
                                text: $password,
                                isFirstResponder: focusField == .password,
                                textColor: UIColor(AuthPalette.primary(colorScheme)),
                                placeholderColor: UIColor(AuthPalette.secondary(colorScheme)),
                                textContentType: .newPassword
                            ) { isFocused in
                                if isFocused {
                                    focusField = .password
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        showPassword.toggle()
                        DispatchQueue.main.async { focusField = .password }
                    } label: {
                        Image(systemName: showPassword ? "eye" : "eye.slash")
                            .foregroundStyle(AuthPalette.secondary(colorScheme)).frame(width: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))

                // Повтори пароль
                HStack {
                    ZStack(alignment: .leading) {
                        if showConfirmPassword {
                            TextField("Повтори пароль", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .foregroundStyle(AuthPalette.primary(colorScheme))
                                .focused($focusField, equals: .confirm)
                        } else {
                            AuthSecureInputField(
                                placeholder: "Повтори пароль",
                                text: $confirmPassword,
                                isFirstResponder: focusField == .confirm,
                                textColor: UIColor(AuthPalette.primary(colorScheme)),
                                placeholderColor: UIColor(AuthPalette.secondary(colorScheme)),
                                textContentType: .newPassword
                            ) { isFocused in
                                if isFocused {
                                    focusField = .confirm
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        showConfirmPassword.toggle()
                        DispatchQueue.main.async { focusField = .confirm }
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                            .foregroundStyle(AuthPalette.secondary(colorScheme)).frame(width: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(AuthPalette.border(colorScheme), lineWidth: 0.5))

                VStack(spacing: 4) {
                    if !password.isEmpty, !confirmPassword.isEmpty, password != confirmPassword {
                        Text("Пароли не совпадают")
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
                .frame(minHeight: 32)

                Button {
                    createAccount()
                } label: {
                    Text("Создать аккаунт")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSubmit ? Color.white : AuthPalette.secondary(colorScheme))
                        .frame(maxWidth: verticalSizeClass == .compact ? 160 : 200)
                        .padding(.vertical, 14)
                        .background {
                            AuthPrimaryActionBackground(isEnabled: canSubmit)
                        }
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            // Fix 1: минимальная высота зафиксирована — нет прыжка при autofill
            .frame(minHeight: 260, alignment: .top)
            Spacer(minLength: 0)
        }
    }

    var canSubmit: Bool {
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
            if let error {
                if (error as NSError).code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    errorText = "Этот email уже зарегистрирован"
                } else {
                    errorText = "Не удалось создать аккаунт"
                }
                print(error)
                return
            }
            guard let user = authResult?.user else { return }
            // Сразу входим без верификации
            appState.signIn(with: AuthUser(
                provider: .email,
                email: user.email ?? e,
                phone: nil, fullName: nil, password: nil, appleUserId: nil
            ))
            isPresented = false
        }
        #else
        appState.signIn(with: AuthUser(provider: .email, email: e, phone: nil, fullName: nil, password: nil, appleUserId: nil))
        isPresented = false
        #endif
    }
}

private struct AuthSecureInputField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isFirstResponder: Bool
    var textColor: UIColor
    var placeholderColor: UIColor
    var textContentType: UITextContentType
    var onFocusChange: ((Bool) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocusChange: onFocusChange)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.isSecureTextEntry = true
        textField.overrideUserInterfaceStyle = .dark
        textField.keyboardAppearance = .dark
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 17)
        textField.textAlignment = .left
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.onFocusChange = onFocusChange
        if uiView.text != text {
            uiView.text = text
            // Re-apply secure rendering after autofill so password bullets keep the intended color.
            let cursorOffset = uiView.selectedTextRange
            uiView.isSecureTextEntry = false
            uiView.isSecureTextEntry = true
            uiView.selectedTextRange = cursorOffset
        }

        uiView.textColor = textColor
        uiView.tintColor = textColor
        uiView.overrideUserInterfaceStyle = .dark
        uiView.keyboardAppearance = .dark
        uiView.textContentType = textContentType
        uiView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor]
        )

        if isFirstResponder, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onFocusChange: ((Bool) -> Void)?

        init(text: Binding<String>, onFocusChange: ((Bool) -> Void)?) {
            _text = text
            self.onFocusChange = onFocusChange
        }

        @objc func textChanged(_ sender: UITextField) {
            text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            onFocusChange?(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            onFocusChange?(false)
        }
    }
}

private struct AuthPrimaryActionBackground: View {
    let isEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Capsule()
            .fill(colorScheme == .dark ? AnyShapeStyle(.clear) : AnyShapeStyle(.regularMaterial))
            .overlay {
                Capsule()
                    .fill(
                        isEnabled
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.02, green: 0.45, blue: 0.98).opacity(0.92),
                                Color(red: 0.12, green: 0.72, blue: 0.98).opacity(0.86)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [
                                (colorScheme == .dark ? Color.white : Color.black).opacity(0.12),
                                (colorScheme == .dark ? Color.white : Color.black).opacity(0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        isEnabled ? .white.opacity(0.18) : .white.opacity(0.08),
                        lineWidth: 0.5
                    )
            }
            .if(isEnabled) { $0.glassEffect(.regular.interactive(), in: Capsule()) }
    }
}



// MARK: - GlassAuthButton

struct GlassAuthButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var fg: Color { colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(fg).frame(width: 24)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(fg)
                Spacer()
            }
            .padding(.horizontal, 20).frame(height: 54)
            .frame(maxWidth: .infinity)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .transaction { $0.animation = nil }
        .glassEffect(.regular.interactive(), in: Capsule())
    }
}

// MARK: - GoogleAuthButton

struct GoogleAuthButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var fg: Color { colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("Google-icon").resizable().scaledToFit().frame(width: 18, height: 18).frame(width: 24)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(fg)
                Spacer()
            }
            .padding(.horizontal, 20).frame(height: 54)
            .frame(maxWidth: .infinity)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .transaction { $0.animation = nil }
        .glassEffect(.regular.interactive(), in: Capsule())
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
