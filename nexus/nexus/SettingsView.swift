import SwiftUI
import PhotosUI
import UIKit
import LocalAuthentication
import UserNotifications
import StoreKit
import CryptoKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Design System

private enum DS {
    // Colors
    static let accent1 = Color(red: 0.0,  green: 0.48, blue: 1.0)   // #0077FF
    static let accent2 = Color(red: 0.0,  green: 0.90, blue: 1.0)   // #00E5FF
    static var accentGrad: LinearGradient {
        LinearGradient(colors: [accent1, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Spacing
    static let hPad:   CGFloat = 16
    static let vGap:   CGFloat = 20
    static let rowV:   CGFloat = 10
    static let radius: CGFloat = 20
    static let iconSz: CGFloat = 34

    // Typography
    static let titleSz:   CGFloat = 32
    static let sectionSz: CGFloat = 11
    static let bodySz:    CGFloat = 15
    static let subSz:     CGFloat = 13

    // Animation
    static let tapDur:    Double = 0.18
    static let toggleDur: Double = 0.25
    static let enterDur:  Double = 0.4
}

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var cs
    let radius: CGFloat
    init(radius: CGFloat = DS.radius) { self.radius = radius }
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(cs == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07),
                                  lineWidth: 0.5)
            )
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: DS.tapDur), value: configuration.isPressed)
    }
}

/// Стиль для toolbar-кнопок × / ✓: нативный Button → iOS сам даёт круглую
/// glass-обёртку (не овал!) и тап-таргет ≥ 44pt. Просто press-scale.
/// (Раньше был `simultaneousGesture(DragGesture)` «поглотитель» — он съедал
/// Button.tap на iOS 26. Убрал: тулбар и так вне ScrollView, скролл не страдает.)
struct ToolbarCloseStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: DS.enterDur).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func glassCard(radius: CGFloat = DS.radius) -> some View { modifier(GlassCardModifier(radius: radius)) }
    func slideIn(delay: Double = 0) -> some View { modifier(SlideInModifier(delay: delay)) }
}

// MARK: - Shared Glass Section

struct NXSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.leading, DS.hPad)
            VStack(spacing: 0) { content }
                .glassCard()
        }
    }
}

struct NXDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.white.opacity(0.06))
            .padding(.leading, 62)
    }
}

// MARK: - Morphing Title

/// Заголовок, который по ходу скролла плавно перемещается из верхнего-левого
/// угла (крупный, bold) в центр тулбара (inline, semibold). Размер, вес и
/// позиция интерполируются от scrollY (0 → 40 pt).
private struct MorphingTitle: View {
    let text: String
    let scrollY: CGFloat
    let fg: Color

    private struct WidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    @State private var smallWidth: CGFloat = 0
    @State private var bigWidth:   CGFloat = 0

    private static let bigSize:   CGFloat = 32
    private static let smallSize: CGFloat = 17

    var body: some View {
        GeometryReader { proxy in
            let raw = min(max(scrollY / 40, 0), 1)
            let p   = raw * raw * (3 - 2 * raw)            // smoothstep
            let size   = Self.bigSize + (Self.smallSize - Self.bigSize) * p
            let weight = Font.Weight.bold
            // Стартовая точка центра текста: слева (hPad + width/2).
            let startCenterX = DS.hPad + bigWidth / 2
            let startCenterY = 8 + Self.bigSize / 2
            // Конечная точка: горизонт. центр контейнера, высота inline-бара (~44 pt).
            let endCenterX   = proxy.size.width / 2
            let endCenterY:  CGFloat = 22
            let cx = startCenterX + (endCenterX - startCenterX) * p
            let cy = startCenterY + (endCenterY - startCenterY) * p

            ZStack(alignment: .topLeading) {
                // Скрытые измерители ширины.
                Text(text)
                    .font(.system(size: Self.bigSize, weight: weight, design: .rounded))
                    .fixedSize()
                    .hidden()
                    .background(GeometryReader { g in
                        Color.clear.preference(key: WidthKey.self, value: g.size.width)
                    })
                    .onPreferenceChange(WidthKey.self) { bigWidth = $0 }

                Text(text)
                    .font(.system(size: Self.smallSize, weight: weight, design: .rounded))
                    .fixedSize()
                    .hidden()
                    .background(GeometryReader { g in
                        Color.clear.preference(key: WidthKey.self, value: g.size.width)
                    })
                    .onPreferenceChange(WidthKey.self) { smallWidth = $0 }

                // Видимый заголовок.
                Text(text)
                    .font(.system(size: size, weight: weight, design: .rounded))
                    .foregroundStyle(fg)
                    .fixedSize()
                    .position(x: cx, y: cy)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

// MARK: - Marquee Text

struct NXMarqueeText: View {
    let text: String
    var font: Font = .system(size: 14)
    var color: Color = Color(.secondaryLabel)
    var speed: Double = 30   // pts per second

    @State private var textWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            if textWidth > w + 1 {
                let gap: CGFloat = 28
                let cycle = textWidth + gap
                let dur = cycle / speed
                // .periodic(0.033) → ~30 fps. Для прокрутки текста этого хватает,
                // а CPU/GPU нагрузка падает в 4 раза vs .animation (120 fps).
                TimelineView(.periodic(from: .now, by: 1.0/30.0)) { ctx in
                    let phase = CGFloat(
                        ctx.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: dur)
                    ) / dur
                    HStack(spacing: gap) { textLabel; textLabel }
                        .offset(x: -phase * cycle)
                        // Фиксируем размер marquee-контейнера шириной GeometryReader'а,
                        // чтобы обе копии текста помещались строго в отведённое окно
                        // и не выходили за пределы/за иконку копирования.
                        .frame(width: w, height: 20, alignment: .leading)
                        .clipped()
                }
            } else {
                textLabel.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: 20)
        .background(
            // Скрытая копия лейбла — замер ширины один раз на мгновение появления.
            // `.id(text)` заставляет SwiftUI пересоздать хидден-копию при смене текста,
            // что триггерит .onAppear заново и замер обновляется без preference-каскадов.
            textLabel.fixedSize().hidden()
                .background(GeometryReader { g in
                    Color.clear.onAppear { textWidth = g.size.width }
                })
                .id(text)
        )
    }

    private var textLabel: some View {
        Text(text).font(font).foregroundStyle(color).lineLimit(1).fixedSize()
    }
}

struct NXIconBox: View {
    let icon: String
    let bg: Color
    var size: CGFloat = DS.iconSz
    var iconSize: CGFloat = 17
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(bg)
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

struct NXGradientIconBox: View {
    let icon: String
    var size: CGFloat = DS.iconSz
    var iconSize: CGFloat = 17
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(DS.accentGrad)
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    /// Инкрементируется из MainTabView при повторном тапе на таб «Настройки».
    /// ScrollViewReader реагирует на изменение и прокручивает список наверх,
    /// возвращая большой навигационный заголовок.
    var scrollToTopTrigger: Int = 0

    @EnvironmentObject private var appState: AppState
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) private var cs
    /// Нативный системный промпт «Оцените приложение» (SKStoreReviewController под капотом).
    /// Показывается внутри приложения без перехода в App Store.
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false

    // Integration toggles
    @State private var healthOn    = true
    @State private var calendarOn  = true
    @State private var iCloudOn    = false
    @AppStorage("nx.settings.notifOn")   private var notifOn     = true
    @AppStorage("nx.settings.spotlightOn") private var spotlightOn = true

    // Security
    // FaceID state хранится в AppSettings (через AppState) — иначе при перезапуске
    // SettingsView показывал бы «включено», но ContentView/lock-flow не знал об этом.
    @State private var faceIDSuccess = false
    // Telegram-style flow: настоящий setup/change/disable теперь живёт в
    // `PasscodeLockView` (push'ится из строки «Код-пароль и Face ID»).
    // Здесь храним только тик для force-refresh `securitySection` после
    // того, как push-страница что-то поменяла.
    @State private var passcodeTick: Int = 0

    // Preferences
    @State private var selectedTheme    = AppTheme.system
    @AppStorage("nx.settings.units")    private var selectedUnits    = "Метрическая"
    @AppStorage("nx.settings.timezone") private var selectedTimezone = "Europe/Moscow"
    @AppStorage("nx.settings.currency") private var selectedCurrency = "🇷🇺 Рубль (₽)"

    // Cache
    @State private var cacheSize         = "—"
    @State private var showCacheBreakdown = false

    // Integrations carousel custom scroll
    @State private var carouselOffset: CGFloat = 0
    @State private var carouselDragStart: CGFloat = 0
    /// Открытая карточка интеграции — детальный sheet.
    @State private var selectedIntegration: IntegrationItem? = nil
    /// Runtime-состояние подключений (переопределяет `connected` из allIntegrations).
    /// Ключ — `name` интеграции.
    @AppStorage("nx.settings.integrationStates") private var integrationStatesJSON = "{}"
    @State private var integrationStates: [String: Bool] = [:]
    /// Шейдер цилиндра включается только после того, как splash/FaceID отработали,
    /// иначе Metal-пайплайн конкурирует за GPU со startup-анимациями и всё лагает.
    @State private var cacheItems: [CacheItem] = []

    // Scroll offset for top blur fade-in
    @State private var scrollY: CGFloat = 0

    // Account actions
    @State private var showChangeEmail    = false
    @State private var showChangePassword = false
    @State private var showLinkPhone      = false
    /// Открытая карточка auth-метода в секции Account — показывает
    /// bottom-sheet с опциями connect/disconnect/change.
    @State private var selectedAuthMethod: AuthMethodKind? = nil
    @State private var authErrorMessage: String? = nil
    @State private var showAuthError = false

    // Overlays / Sheets
    @State private var showProfileEdit    = false
    @State private var showShareSheet     = false
    @State private var showStatsDetail    = false
    @State private var showSignOutAlert   = false
    @State private var showLanguageAlert  = false
    @State private var showPrivacyOverlay = false
    @State private var showInfoSheet: InfoSheetKind? = nil
    @State private var showFeedback      = false
    @State private var copiedID = false

    enum InfoSheetKind: Identifiable {
        case faq, changelog, terms
        var id: Self { self }
        var title: String {
            switch self {
            case .faq:       return "FAQ"
            case .changelog: return "Журнал изменений"
            case .terms:     return "Условия использования"
            }
        }
    }

    enum AuthMethodKind: String, Identifiable, Hashable {
        case apple, google, email, password, phone
        var id: String { rawValue }
        var providerID: String {
            switch self {
            case .apple:    return "apple.com"
            case .google:   return "google.com"
            case .email:    return "password"
            case .password: return "password"
            case .phone:    return "phone"
            }
        }
        var title: String {
            switch self {
            case .apple:    return "Apple ID"
            case .google:   return "Google"
            case .email:    return "Email"
            case .password: return "Пароль"
            case .phone:    return "Телефон"
            }
        }
    }

    // MARK: Computed
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    private var bg: Color { cs == .dark ? .black : .white }

    private var user: UserProfile? { appState.userProfile }
    private var userContact: String {
        if let e = user?.email, !e.isEmpty { return e }
        if let p = user?.phone, !p.isEmpty { return p }
        return "—"
    }
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
    private var userID: String {
        #if canImport(FirebaseAuth)
        return FirebaseAuth.Auth.auth().currentUser?.uid ?? "—"
        #else
        return "—"
        #endif
    }

    // MARK: Data
    struct IntegrationItem: Hashable, Identifiable {
        var id: String { name }
        /// SF Symbol — fallback когда нет брендового ассета.
        let icon: String
        /// Имя бренд-ассета в Assets.xcassets (PNG/PDF/SVG).
        /// Если ассет найден — он показывается вместо `icon`.
        /// Шаблон имени: `brand.<name>` (lower-cased, без пробелов).
        let asset: String?
        /// Рендерить бренд-ассет в original-цвете (true) или как template
        /// с белой заливкой (false). Для монохромных лого ставь `false`.
        let assetColorful: Bool
        let bg: Color
        let name: String
        let connected: Bool
        init(icon: String, asset: String? = nil, assetColorful: Bool = false,
             bg: Color, name: String, connected: Bool) {
            self.icon = icon
            self.asset = asset
            self.assetColorful = assetColorful
            self.bg = bg
            self.name = name
            self.connected = connected
        }
        func hash(into hasher: inout Hasher) { hasher.combine(name) }
        static func == (l: Self, r: Self) -> Bool { l.name == r.name }
    }
    // NB: Чтобы подключить брендовую иконку — добавь PNG/PDF в
    // Assets.xcassets с именем, равным `asset:` ниже (например `brand.oura`).
    // Ассет должен быть шаблонным (template) для монохромных лого —
    // assetColorful: false; для цветных логотипов — assetColorful: true.
    private let allIntegrations: [IntegrationItem] = [
        // Apple native — SF Symbols уже выглядят «брендово»
        .init(icon: "heart.fill",             asset: "brand.health",      assetColorful: false, bg: Color(red:0.9,green:0.1,blue:0.2),  name: "Health",         connected: true ),
        .init(icon: "calendar",               asset: "brand.calendar",    assetColorful: false, bg: Color(red:0.6,green:0.0,blue:0.0),  name: "Calendar",       connected: true ),
        .init(icon: "icloud.fill",            asset: "brand.icloud",      assetColorful: false, bg: Color(red:0.0,green:0.35,blue:0.9), name: "iCloud",         connected: false),
        .init(icon: "applewatch",             asset: "brand.applewatch",  assetColorful: false, bg: Color(red:0.3,green:0.3,blue:0.35), name: "Apple Watch",    connected: false),
        // Third-party — кидай PDF/PNG в Assets.xcassets с этими именами
        .init(icon: "circle.hexagongrid.fill",asset: "brand.oura",        assetColorful: false, bg: Color(red:0.45,green:0.3,blue:0.9), name: "Oura Ring",      connected: false),
        .init(icon: "waveform.path.ecg",      asset: "brand.garmin",      assetColorful: false, bg: Color(red:0.0,green:0.6,blue:0.3),  name: "Garmin",         connected: false),
        .init(icon: "bolt.heart.fill",        asset: "brand.whoop",       assetColorful: false, bg: Color(red:0.85,green:0.1,blue:0.1), name: "Whoop",          connected: false),
        .init(icon: "figure.run",             asset: "brand.fitbit",      assetColorful: false, bg: Color(red:0.0,green:0.5,blue:1.0),  name: "Fitbit",         connected: false),
        .init(icon: "target",                 asset: "brand.polar",       assetColorful: false, bg: Color(red:0.7,green:0.0,blue:0.0),  name: "Polar",          connected: false),
        .init(icon: "scalemass.fill",         asset: "brand.withings",    assetColorful: false, bg: Color(red:0.3,green:0.5,blue:0.9),  name: "Withings",       connected: false),
        .init(icon: "drop.fill",              asset: "brand.dexcom",      assetColorful: false, bg: Color(red:0.0,green:0.5,blue:0.8),  name: "Dexcom",         connected: false),
        .init(icon: "s.circle.fill",          asset: "brand.samsung",     assetColorful: false, bg: Color(red:0.0,green:0.6,blue:0.3),  name: "Samsung",        connected: false),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DS.vGap) {
                            // Первая карточка несёт id-якорь для scroll-to-top
                            // при повторном тапе на таб «Настройки». Раньше тут
                                // был отдельный Color.clear, но VStack(spacing:)
                                // добавлял ему 20pt отступа сверху и снизу — и
                                // заголовок «Настройки» визуально «отъезжал»
                                // от карточки профиля.
                            profileSection
                                .id("nxSettingsTop")
                                .slideIn(delay: 0.10)
                            subscriptionBanner.slideIn(delay: 0.12)
                            integrationsCarousel.slideIn(delay: 0.15)
                            preferencesSection.slideIn(delay: 0.20)
                            securitySection.slideIn(delay: 0.25)
                            accountSection.slideIn(delay: 0.30)
                            supportInfoSection.slideIn(delay: 0.35)
                            signOutSection.slideIn(delay: 0.40)
                            bottomLinks.slideIn(delay: 0.45)

                            Text("Nexus version: \(appVersion)")
                                .font(.system(size: 12))
                                .foregroundStyle(fg.opacity(0.25))
                                .slideIn(delay: 0.50)

                            Spacer(minLength: 60)
                        }
                        .padding(.horizontal, DS.hPad)
                        .padding(.top, 8)
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geo in
                        geo.contentOffset.y + geo.contentInsets.top
                    } action: { _, newY in
                        scrollY = newY
                    }
                    // Повторный тап на таб «Настройки» → плавно прокрутить наверх.
                    // scrollToTopTrigger = 0 при init, поэтому onChange(initial: false)
                    // чтобы не скроллить при первом рендере.
                    .onChange(of: scrollToTopTrigger) { _, _ in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            proxy.scrollTo("nxSettingsTop", anchor: .top)
                        }
                    }
                }


                // Copy toast — liquid glass
                if copiedID {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 0.15, green: 0.78, blue: 0.35))
                            Text("ID скопирован")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(fg)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(fg.opacity(0.12), lineWidth: 0.7))
                        .glassEffect(.regular.interactive(), in: Capsule())
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                        .padding(.bottom, 80)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(8)
                    .allowsHitTesting(false)
                }
            }
            // Штатный nav-bar iOS: крупный заголовок сверху, сворачивается в
            // inline-заголовок при скролле, под ним автоматический material-блюр
            // (всё как в стоковом Settings.app).
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .tint(fg)
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .animation(.easeInOut(duration: 0.3), value: copiedID)
        .sheet(isPresented: $showProfileEdit)    { ProfileView().environmentObject(appState) }
        .sheet(isPresented: $showStatsDetail)    { StatsDetailView().environmentObject(appState) }
        .sheet(isPresented: $showChangeEmail)    { ChangeEmailSheet() }
        .sheet(isPresented: $showChangePassword) { ChangePasswordSheet() }
        .sheet(isPresented: $showLinkPhone)      { LinkPhoneSheet() }
        .sheet(item: $showInfoSheet) { kind in
            InfoSheet(kind: kind)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showPrivacyOverlay) {
            PrivacySheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCacheBreakdown) {
            CacheBreakdownSheet(items: cacheItems, totalSize: cacheSize, onClear: performClearCache)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        // Sheet'ы для setup/change/disable перенесены внутрь PasscodeLockView,
        // которая push'ится с экрана Settings. Здесь ничего не нужно.
        .sheet(isPresented: $showShareSheet) { ShareSheet(activityItems: ["Я использую Nexus!"]) }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
                .environmentObject(appState)
                // Один фиксированный детент 0.78 — sheet чуть ниже, чем был
                // 0.85, и его НЕЛЬЗЯ растянуть на full-screen (только один
                // вариант высоты).
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.hidden)
                // Без явного presentationBackground — iOS 26 сам отрисует
                // нативный liquid-glass для sheet'а. Это и есть тот «блюр
                // сверху», что был на «Поддержке».
        }
        .sheet(item: $selectedIntegration) { item in
            IntegrationDetailSheet(
                integration: item,
                connected: isConnected(item),
                onToggle: { toggleConnection(for: item) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(appState)
        }
        .sheet(item: $selectedAuthMethod) { kind in
            AuthMethodSheet(
                kind: kind,
                status: authStatus(for: kind),
                subtitle: authSubtitle(for: kind),
                onConnect: { handleConnect(kind: kind) },
                onChange:  { handleChange(kind: kind) },
                onDisconnect: { handleDisconnect(kind: kind) }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Ошибка", isPresented: $showAuthError, actions: {
            Button("OK", role: .cancel) {}
        }, message: { Text(authErrorMessage ?? "") })
        .alert("Выйти из аккаунта?", isPresented: $showSignOutAlert) {
            Button("Выйти", role: .destructive) { appState.signOut() }
            Button("Отмена", role: .cancel) {}
        }
        .alert("Язык изменён", isPresented: $showLanguageAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Перезапусти приложение чтобы применить.") }
        .onAppear {
            selectedTheme = appState.settings.theme
            computeCacheSize()
            configureNavBarAppearance()
            loadIntegrationStates()
            syncNotificationAuthorization()
            syncSpotlightState()
        }
    }

    /// Шрифт заголовка как у остальных экранов: 32pt bold rounded для large,
    /// 17pt semibold rounded для inline. Плюс пружинная анимация при
    /// сворачивании large → inline.
    private func configureNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        let largeDesc = UIFont.systemFont(ofSize: DS.titleSz, weight: .bold)
            .fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: DS.titleSz, weight: .bold).fontDescriptor
        let inlineDesc = UIFont.systemFont(ofSize: 17, weight: .semibold)
            .fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: 17, weight: .semibold).fontDescriptor

        appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: largeDesc, size: DS.titleSz)]
        appearance.titleTextAttributes      = [.font: UIFont(descriptor: inlineDesc, size: 17)]

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Настройки")
                .font(.system(size: DS.titleSz, weight: .bold, design: .rounded))
                .foregroundStyle(fg)
            Spacer()
            Button { showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(fg)
                    .frame(width: 38, height: 38)
                    .applyGlassCircle()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Profile

    // MARK: - Subscription Banner
    //
    // Анимированная плитка подписки между профилем и интеграциями.
    // Для не-подписчика — промо с медленно вращающимся конус-градиентом
    // по обводке + лёгкий shimmer-sweep по поверхности.
    // Для подписчика — compact-режим с зелёной галочкой и планом.

    private var subscriptionBanner: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPaywall = true
        } label: {
            if subscriptionManager.isSubscribed {
                subscribedCard
            } else {
                promoCard
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// Не-подписчик: премиальное промо с анимированным градиентом.
    //
    // Архитектура:
    //   • Внутреннее содержимое (фон, specular, контент, обводки) кладём
    //     в ZStack и КЛИПУЕМ через `.clipShape(RoundedRectangle)` — это
    //     гарантирует, что никакой слой не вылезает за скруглённые края.
    //   • Тени (цветная аура + contact) применяем СНАРУЖИ клипа — они
    //     должны быть видны за пределами карточки, но не должны влиять
    //     на внутренние слои.
    //   • `.compositingGroup()` собирает всё внутреннее в один слой,
    //     чтобы тень считалась один раз от итогового силуэта.
    //   • Радиусы теней СТАТИЧНЫ → Core Animation кэширует блюр и каждый
    //     кадр меняет только цвет/opacity (дёшево, без re-blur).
    private var promoCard: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate

            // Тайминги. Намеренно медленные — премиум = неторопливо.
            let breath      = 0.5 + 0.5 * sin(t * 0.55)         // ~11 сек цикл
            let borderAngle = Angle(degrees: (t * 24)
                .truncatingRemainder(dividingBy: 360))           // ~15 сек оборот

            // Тёплый hue для основной ауры (violet → magenta → coral).
            let hueA = (0.85 + 0.13 * sin(t * 0.18))
                .truncatingRemainder(dividingBy: 1.0)
            // Контр-фаза для второй ауры (cool → indigo → blue).
            let hueB = (0.62 + 0.08 * sin(t * 0.18 + .pi))
                .truncatingRemainder(dividingBy: 1.0)

            // Specular — центр плавает диагонально, имитируя живой блик.
            let specX = 0.22 + 0.10 * sin(t * 0.33)
            let specY = 0.18 + 0.07 * sin(t * 0.22 + 1.1)

            // Sweep — горизонтальная световая полоса, проходит каждые ~7с.
            let sweepX = (sin(t * 0.45) + 1) * 0.5               // 0..1
            let sweepWidth: CGFloat = 0.18

            // Корнер-радиус выносим, чтобы клип и обводки совпадали 1:1.
            let radius: CGFloat = 22
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

            ZStack {
                // 1. База
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: cs == .dark
                                ? [Color(red: 0.07, green: 0.06, blue: 0.11),
                                   Color(red: 0.11, green: 0.07, blue: 0.17)]
                                : [Color.white,
                                   Color(red: 0.97, green: 0.96, blue: 0.99)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 2. Movable specular (highlight).
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(cs == .dark ? 0.16 : 0.32),
                                Color.clear
                            ],
                            center: UnitPoint(x: specX, y: specY),
                            startRadius: 8,
                            endRadius: 200
                        )
                    )
                    .allowsHitTesting(false)

                // 3. Sweep — диагональная световая полоса, бесконечно
                //     ползёт слева направо. Узкая, мягкая.
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: max(0, sweepX - sweepWidth)),
                                .init(color: Color.white.opacity(cs == .dark ? 0.10 : 0.22), location: sweepX),
                                .init(color: .clear, location: min(1, sweepX + sweepWidth)),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)

                // 4. Контент
                promoContent

                // 5. Конусная обводка — медленно вращается.
                shape
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.42, green: 0.25, blue: 0.95), // violet
                                Color(red: 0.72, green: 0.28, blue: 0.96), // purple
                                Color(red: 0.96, green: 0.35, blue: 0.72), // magenta
                                Color(red: 1.00, green: 0.45, blue: 0.48), // coral
                                Color(red: 1.00, green: 0.62, blue: 0.35), // amber
                                Color(red: 0.42, green: 0.25, blue: 0.95), // back
                            ]),
                            center: .center,
                            angle: borderAngle
                        ),
                        lineWidth: 1.1
                    )
                    .allowsHitTesting(false)

                // 6. Inner glass rim — отполированный верхний кант.
                shape
                    .inset(by: 0.8)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(cs == .dark ? 0.38 : 0.55),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 0.6
                    )
                    .allowsHitTesting(false)
            }
            .frame(height: 108)
            // КРИТИЧНО: клипаем всё внутреннее по форме карточки.
            // Без этого specular/sweep вылезают за скруглённые углы.
            .clipShape(shape)
            .contentShape(shape)
            // Собираем внутренние слои в один композит → одна тень.
            .compositingGroup()
            // Тени — снаружи клипа, статические радиусы.
            .shadow(
                color: Color(hue: hueA, saturation: 0.78, brightness: 1.0)
                    .opacity(0.34 + breath * 0.18),
                radius: 28, x: 0, y: 10
            )
            .shadow(
                color: Color(hue: hueB, saturation: 0.62, brightness: 1.0)
                    .opacity(0.18 + (1 - breath) * 0.12),
                radius: 22, x: 0, y: -4
            )
            .shadow(
                color: Color.black.opacity(cs == .dark ? 0.42 : 0.10),
                radius: 4, x: 0, y: 2
            )
        }
    }

    private var promoContent: some View {
        HStack(spacing: 14) {
            // Иконка
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.25, blue: 0.95),
                                Color(red: 0.0, green: 0.48, blue: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color(red: 0.55, green: 0.25, blue: 0.95).opacity(0.5), radius: 10, y: 4)
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Nexus")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(fg)
                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .kerning(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color(red:0.95,green:0.35,blue:0.65), in: Capsule())
                }
                Text("Все агенты, безлимитный чат, приоритет")
                    .font(.system(size: 12))
                    .foregroundStyle(fg.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // CTA-стрелка в gradient-круге
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.48, blue: 1.0),
                                Color(red: 0.55, green: 0.25, blue: 0.95),
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                )
        }
        .padding(.horizontal, 16)
    }

    /// Подписчик: компактный плиточный статус с зелёной галочкой.
    private var subscribedCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color(red:0.0,green:0.65,blue:0.35)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .green.opacity(0.4), radius: 6, y: 3)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Nexus").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(fg)
                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .kerning(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color(red:0.95,green:0.35,blue:0.65), in: Capsule())
                    Text("активна").font(.system(size: 12)).foregroundStyle(.green)
                }
                Text("План: \(subscriptionManager.currentPlan.displayName)")
                    .font(.system(size: 11))
                    .foregroundStyle(fg.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(fg.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
        )
    }

    private var profileSection: some View {
        Button { showProfileEdit = true } label: {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    if let data = user?.avatarData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 60, height: 60).clipShape(Circle())
                    } else {
                        Circle()
                            .fill(DS.accentGrad)
                            .frame(width: 60, height: 60)
                        Text(user?.initials ?? "AN")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: DS.accent1.opacity(0.3), radius: 8, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.fullName.trimmingCharacters(in: .whitespaces).isEmpty == false
                         ? (user?.fullName ?? "Имя не указано") : "Имя не указано")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(fg)
                    Text(userContact)
                        .font(.system(size: DS.subSz))
                        .foregroundStyle(fg.opacity(0.45))
                    if let u = user {
                        HStack(spacing: 6) {
                            if u.age > 0      { NXPill("\(u.age) лет") }
                            if u.weightKg > 0 { NXPill("\(Int(u.weightKg)) кг") }
                            if u.heightCm > 0 { NXPill("\(Int(u.heightCm)) см") }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(16)
            .glassCard()
            .contentShape(RoundedRectangle(cornerRadius: DS.radius))
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Integrations Carousel

    private var integrationsCarousel: some View {
        NXSection(title: "Интеграции") {
            GeometryReader { geo in
                let cardW: CGFloat = 80
                let spacing: CGFloat = 10
                let totalW = CGFloat(allIntegrations.count) * cardW
                          + CGFloat(allIntegrations.count - 1) * spacing
                let minOffset = min(0, geo.size.width - totalW - DS.hPad * 2)

                ZStack(alignment: .leading) {
                    // Серая подложка — заполнит любые пиксели, куда шейдер «дотянулся»
                    // мимо карточек (чтобы не было чёрных областей).
                    Color(white: cs == .dark ? 0.12 : 0.92)

                    HStack(spacing: spacing) {
                        ForEach(allIntegrations, id: \.name) { item in
                            IntegrationCard(
                                icon: item.icon,
                                asset: item.asset,
                                assetColorful: item.assetColorful,
                                bg: item.bg,
                                name: item.name,
                                connected: isConnected(item)
                            )
                            .onTapGesture {
                                let hap = UIImpactFeedbackGenerator(style: .light)
                                hap.impactOccurred()
                                selectedIntegration = item
                            }
                        }
                    }
                    .padding(.horizontal, DS.hPad)
                    .frame(width: totalW + DS.hPad * 2, height: geo.size.height, alignment: .leading)
                    .offset(x: carouselOffset)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                .contentShape(Rectangle())
                // Сначала жёстко обрезаем по rect — чтобы шейдер не сэмплировал
                // содержимое соседних вьюх.
                .clipped()
                .distortionEffect(
                    ShaderLibrary.cylinderDistort(
                        .float2(Float(geo.size.width), Float(geo.size.height)),
                        .float(1.0)
                    ),
                    maxSampleOffset: CGSize(width: 60, height: 40)
                )
                // Финальный клип по скруглённой форме секции — ПОСЛЕ шейдера,
                // чтобы distortionEffect не рисовал пиксели за пределами углов.
                .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            if g.translation == .zero {
                                carouselDragStart = carouselOffset
                            }
                            let target = carouselDragStart + g.translation.width
                            // Rubber-band за границами
                            if target > 0 {
                                carouselOffset = target * 0.35
                            } else if target < minOffset {
                                carouselOffset = minOffset + (target - minOffset) * 0.35
                            } else {
                                carouselOffset = target
                            }
                        }
                        .onEnded { g in
                            // Momentum + clamp
                            let velocity = g.predictedEndTranslation.width - g.translation.width
                            var final = carouselOffset + velocity * 0.6
                            final = max(minOffset, min(0, final))
                            withAnimation(.interpolatingSpring(stiffness: 120, damping: 22)) {
                                carouselOffset = final
                            }
                        }
                )
            }
            .frame(height: 124)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        NXSection(title: "Внешний вид") {
            // Все 5 меню используют один и тот же кастомный `Menu`-лейбл
            // (prefMenuLabel) вместо нативного `Picker(.menu)`. Нативный
            // picker-style добавляет свой внутренний паддинг → значение
            // не доходит до правого края. С кастомным лейблом текст +
            // chevron хуггают правый край ряда (упираются в DS.hPad),
            // а ряды визуально идентичны между собой.

            // Theme
            prefRow(icon: "paintbrush.fill", bg: Color(red:0.55,green:0.1,blue:0.9), label: "Тема") {
                Menu {
                    ForEach(AppTheme.allCases, id: \.self) { t in
                        Button(t.rawValue) {
                            selectedTheme = t
                            appState.settings.theme = t
                        }
                    }
                } label: {
                    prefMenuLabel(selectedTheme.rawValue)
                }
            }
            NXDivider()
            // Language
            prefRow(icon: "globe", bg: Color(red:0.0,green:0.4,blue:0.9), label: "Язык") {
                Menu {
                    ForEach(Self.languageOptions, id: \.0) { tag, title in
                        Button(title) {
                            appState.settings.language = tag
                            showLanguageAlert = true
                        }
                    }
                } label: {
                    prefMenuLabel(Self.languageLabel(appState.settings.language))
                }
            }
            NXDivider()
            // Units
            prefRow(icon: "ruler.fill", bg: Color(red:0.3,green:0.3,blue:0.36), label: "Единицы") {
                Menu {
                    Button("Метрическая") { selectedUnits = "Метрическая" }
                    Button("Имперская")   { selectedUnits = "Имперская" }
                } label: {
                    prefMenuLabel(selectedUnits)
                }
            }
            NXDivider()
            // Timezone — полный список идентификаторов IANA
            prefRow(icon: "clock.fill", bg: Color(red:0.2,green:0.5,blue:0.85), label: "Часовой пояс") {
                Menu {
                    ForEach(Self.sortedTimezoneIDs, id: \.self) { tzId in
                        Button(Self.timezoneLabel(tzId)) { selectedTimezone = tzId }
                    }
                } label: {
                    prefMenuLabel(Self.timezoneLabel(selectedTimezone))
                }
            }
            NXDivider()
            // Currency
            prefRow(icon: "dollarsign", bg: Color(red:0.1,green:0.65,blue:0.35), label: "Валюта") {
                Menu {
                    ForEach(["🇷🇺 Рубль (₽)","🇺🇸 Доллар ($)","🇪🇺 Евро (€)",
                             "🇬🇧 Фунт (£)","🇯🇵 Иена (¥)","🇨🇭 Франк (CHF)",
                             "🇦🇺 AUD (A$)","🇨🇦 CAD (C$)","🇸🇬 SGD (S$)",
                             "🇭🇰 HKD (HK$)","🇮🇳 Рупия (₹)","🇲🇽 Песо (Mex$)",
                             "🇧🇷 Реал (R$)","🇰🇷 Вона (₩)","🇸🇪 Крона (kr)"], id: \.self) { c in
                        Button(c) { selectedCurrency = c }
                    }
                } label: {
                    prefMenuLabel(selectedCurrency)
                }
            }
        }
    }

    // MARK: - Unified trailing label for preferences menus
    //
    // Все 5 рядов секции «Внешний вид» используют эту форму: значение
    // серого цвета + маленький chevron, без фиксированной ширины — так
    // содержимое естественно прижимается к правому краю ряда.
    @ViewBuilder
    private func prefMenuLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(fg.opacity(0.5))
                .lineLimit(1)
                .truncationMode(.middle)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(fg.opacity(0.3))
        }
    }

    // MARK: - Language options
    //
    // Источник правды для списка языков + соответствия «tag → красивый
    // заголовок с флагом». Используем и для меню, и для trailing-label'а,
    // чтобы не рассинхронизировать (было: Picker содержал тексты, но при
    // выбранном значении «ru_RU» нигде не был записан label для отрисовки).
    private static let languageOptions: [(String, String)] = [
        ("en_US", "🇺🇸 English"),
        ("ru_RU", "🇷🇺 Русский"),
        ("es_ES", "🇪🇸 Español"),
        ("fr_FR", "🇫🇷 Français"),
        ("de_DE", "🇩🇪 Deutsch"),
        ("it_IT", "🇮🇹 Italiano"),
        ("pt_BR", "🇧🇷 Português"),
        ("ja_JP", "🇯🇵 日本語"),
        ("ko_KR", "🇰🇷 한국어"),
        ("zh_CN", "🇨🇳 中文"),
        ("ar_SA", "🇸🇦 العربية"),
        ("hi_IN", "🇮🇳 हिन्दी"),
        ("tr_TR", "🇹🇷 Türkçe"),
        ("uk_UA", "🇺🇦 Українська"),
        ("pl_PL", "🇵🇱 Polski")
    ]

    private static func languageLabel(_ tag: String) -> String {
        languageOptions.first(where: { $0.0 == tag })?.1 ?? tag
    }

    @ViewBuilder
    private func prefRow<T: View>(icon: String, bg: Color, label: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack(spacing: 14) {
            NXIconBox(icon: icon, bg: bg)
            Text(label).font(.system(size: DS.bodySz)).foregroundStyle(fg)
            Spacer()
            trailing()
        }
        .padding(.horizontal, DS.hPad)
        .padding(.vertical, DS.rowV)
    }

    // MARK: - Security

    private var securitySection: some View {
        // passcodeTick читается, чтобы view перерисовалась после set/clear
        // кода-пароля внутри PasscodeLockView (статический helper не @Published).
        _ = passcodeTick
        let passcodeIsSet = AppPasscodeStore.isSet
        let faceOn = appState.settings.faceIDEnabled && passcodeIsSet

        return NXSection(title: "Безопасность") {
            // ──────────────────────────────────────────────────────────
            // ОДНА строка — «Код-пароль и Face ID». Push открывает
            // полноэкранную PasscodeLockView (как в Telegram: «Passcode
            // Lock»). Внутри — Set/Change/Off + Auto-Lock + Face ID toggle.
            // ──────────────────────────────────────────────────────────
            NavigationLink {
                PasscodeLockView(passcodeTick: $passcodeTick)
                    .environmentObject(appState)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.iconSz * 0.26)
                            .fill(passcodeIsSet ? Color.green : Color(red: 0.55, green: 0.55, blue: 0.60))
                            .frame(width: DS.iconSz, height: DS.iconSz)
                        Image(systemName: passcodeIsSet ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Код-пароль и Face ID")
                            .font(.system(size: DS.bodySz))
                            .foregroundStyle(fg)
                        Text(securityRowSubtitle(set: passcodeIsSet, face: faceOn))
                            .font(.system(size: 11))
                            .foregroundStyle(fg.opacity(0.45))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.30))
                }
                .padding(.horizontal, DS.hPad)
                .padding(.vertical, DS.rowV)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            NXDivider()

            // Notifications
            toggleRow(icon: "bell.fill", bg: Color(red:0.35,green:0.35,blue:0.4),
                      label: "Уведомления", isOn: $notifOn)
                .onChange(of: notifOn) { _, enabled in
                    handleNotificationsToggle(enabled)
                }
            NXDivider()

            // Spotlight
            toggleRow(icon: "magnifyingglass", bg: Color(red:0.35,green:0.35,blue:0.4),
                      label: "Spotlight", isOn: $spotlightOn)
                .onChange(of: spotlightOn) { _, enabled in
                    handleSpotlightToggle(enabled)
                }
        }
    }

    /// Подзаголовок под «Код-пароль и Face ID»: показывает текущее состояние
    /// одной короткой фразой, чтобы пользователь видел что внутри без захода.
    private func securityRowSubtitle(set: Bool, face: Bool) -> String {
        if !set         { return "Выключено" }
        if face         { return "Включён · Face ID" }
        return "Включён"
    }

    @ViewBuilder
    private func toggleRow(icon: String, bg: Color, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            NXIconBox(icon: icon, bg: bg)
            Text(label).font(.system(size: DS.bodySz)).foregroundStyle(fg)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(DS.accent1)
        }
        .padding(.horizontal, DS.hPad)
        .padding(.vertical, DS.rowV)
    }

    // MARK: - Account

    private var accountSection: some View {
        NXSection(title: "Аккаунт") {
            // User ID — tap to copy
            Button {
                UIPasteboard.general.string = userID
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation { copiedID = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { copiedID = false }
                }
            } label: {
                HStack(spacing: 14) {
                    NXGradientIconBox(icon: "person.text.rectangle.fill")
                    Text("User ID")
                        .font(.system(size: DS.bodySz))
                        .foregroundStyle(fg)
                        .fixedSize()
                        .layoutPriority(1)
                    Spacer(minLength: 0)
                    // ID + иконка копирования — плотная группа справа.
                    // ID идёт через marquee (прокручивается, если не помещается),
                    // и смещён на 2pt вниз, чтобы моноширинные цифры визуально
                    // выравнивались по baseline заголовка.
                    HStack(spacing: 14) {
                        NXMarqueeText(
                            text: userID,
                            font: .system(size: 11, design: .monospaced),
                            color: Color(.secondaryLabel),
                            speed: 22
                        )
                        .frame(width: 160)
                        .offset(y: 2)
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.accent1.opacity(0.7))
                            .fixedSize()
                    }
                }
                .padding(.horizontal, DS.hPad)
                .padding(.vertical, DS.rowV)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())

            NXDivider()

            // Apple ID
            accountMethodRow(kind: .apple,
                icon: "apple.logo",
                iconBg: cs == .dark ? Color(red:0.2,green:0.2,blue:0.22) : Color(red:0.85,green:0.85,blue:0.87),
                iconColor: cs == .dark ? .white : .black)
            NXDivider()

            // Google
            accountMethodRow(kind: .google,
                icon: "Google-icon",
                iconBg: .white, iconColor: .white,
                isAsset: true)
            NXDivider()

            // Email
            accountMethodRow(kind: .email,
                icon: "envelope.fill",
                iconBg: Color(red:0.0,green:0.35,blue:0.9), iconColor: .white)
            NXDivider()

            // Password
            accountMethodRow(kind: .password,
                icon: "lock.fill",
                iconBg: Color(red:0.4,green:0.4,blue:0.45), iconColor: .white)
            NXDivider()

            // Phone
            accountMethodRow(kind: .phone,
                icon: "phone.fill",
                iconBg: Color(red:0.1,green:0.7,blue:0.3), iconColor: .white)
        }
    }

    /// Возвращает актуальный статус для auth-метода, запрашивая AuthenticationManager.
    private func authStatus(for kind: AuthMethodKind) -> AccountLinkStatus {
        switch kind {
        case .apple:    return authManager.hasAppleProvider  ? .connected : .notConnected
        case .google:   return authManager.hasGoogleProvider ? .connected : .notConnected
        case .email, .password:
            return authManager.hasEmailProvider ? .connected : .notConnected
        case .phone:    return authManager.hasPhoneProvider  ? .connected : .notConnected
        }
    }

    /// Текст-значение под названием: email для .email, номер телефона для .phone, etc.
    private func authSubtitle(for kind: AuthMethodKind) -> String? {
        switch kind {
        case .email:
            return authManager.linkedEmailAddress
        case .phone:
            return authManager.linkedPhoneNumber
        case .apple, .google, .password:
            return nil
        }
    }

    @ViewBuilder
    private func accountMethodRow(kind: AuthMethodKind,
                                  icon: String, iconBg: Color, iconColor: Color,
                                  isAsset: Bool = false) -> some View {
        let status = authStatus(for: kind)
        let subtitle = authSubtitle(for: kind)

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedAuthMethod = kind
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.iconSz * 0.26)
                        .fill(iconBg)
                        .frame(width: DS.iconSz, height: DS.iconSz)
                    if isAsset {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: DS.iconSz * 0.56, height: DS.iconSz * 0.56)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(iconColor)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title).font(.system(size: DS.bodySz)).foregroundStyle(fg)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(fg.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                Spacer()
                switch status {
                case .connected:
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("Подключён").font(.system(size: 12)).foregroundStyle(.green)
                    }
                case .notConnected:
                    Text("Подключить")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.accent1.opacity(0.7))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(DS.accent1.opacity(0.1), in: Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(fg.opacity(0.25))
            }
            .padding(.horizontal, DS.hPad)
            .padding(.vertical, DS.rowV)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Support & Info

    private var supportInfoSection: some View {
        NXSection(title: "Поддержка и информация") {
            // Write to support
            actionRow(icon: "bubble.left.fill", bg: .blue.opacity(0.8), title: "Написать в поддержку") {
                showFeedback = true
            }
            NXDivider()

            // «Поддержать проект» убран: вместо него будет подписка (см. плитку над профилем).

            actionRow(icon: "star.fill", bg: Color(red:1,green:0.75,blue:0), title: "Оценить приложение") {
                // Нативный in-app prompt — iOS сам решит, показывать его сейчас или нет
                // (SKStoreReviewController квотирует до 3 показов в год).
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                requestReview()
            }
            NXDivider()

            // iPadOS version (disabled, coming soon)
            comingSoonRow(icon: "ipad", title: "iPadOS версия")
            NXDivider()

            // macOS version (disabled, coming soon)
            comingSoonRow(icon: "desktopcomputer", title: "macOS версия")

            NXDivider()
            actionRow(icon: "questionmark.circle.fill", bg: DS.accent1.opacity(0.9), title: "FAQ") {
                showInfoSheet = .faq
            }
            NXDivider()

            // Privacy
            Button { showPrivacyOverlay = true } label: {
                HStack(spacing: 14) {
                    NXIconBox(icon: "doc.text.fill", bg: Color(red:0.42,green:0.22,blue:0.78))
                    Text("Политика конфиденциальности")
                        .font(.system(size: DS.bodySz))
                        .foregroundStyle(fg)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(fg.opacity(0.2))
                }
                .padding(.horizontal, DS.hPad)
                .padding(.vertical, DS.rowV)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())

            NXDivider()
            actionRow(icon: "list.clipboard.fill", bg: .orange, title: "Журнал изменений") {
                showInfoSheet = .changelog
            }
            NXDivider()
            actionRow(icon: "doc.fill", bg: Color(red:0.42,green:0.22,blue:0.78), title: "Условия использования") {
                showInfoSheet = .terms
            }
            NXDivider()

            // Cache
            Button { prepareAndShowCacheBreakdown() } label: {
                HStack(spacing: 14) {
                    NXIconBox(icon: "trash.fill", bg: .red.opacity(0.85))
                    Text("Очистить кэш")
                        .font(.system(size: DS.bodySz))
                        .foregroundStyle(fg)
                    Spacer()
                    Text(cacheSize)
                        .font(.system(size: DS.subSz))
                        .foregroundStyle(fg.opacity(0.35))
                }
                .padding(.horizontal, DS.hPad)
                .padding(.vertical, DS.rowV)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    /// Строка-заглушка для платформ, которые пока не готовы (iPadOS, macOS).
    /// Визуально блекнет в тёмной теме и не принимает тапы.
    @ViewBuilder
    private func comingSoonRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            NXIconBox(icon: icon, bg: (cs == .dark ? Color.white.opacity(0.06) : Color.gray.opacity(0.22)))
            Text(title)
                .font(.system(size: DS.bodySz))
                .foregroundStyle(fg.opacity(cs == .dark ? 0.25 : 0.35))
            Spacer()
            Text("Скоро")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(cs == .dark ? Color.white.opacity(0.45) : .white)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background((cs == .dark ? Color.white.opacity(0.08) : Color.gray.opacity(0.4)),
                            in: Capsule())
        }
        .padding(.horizontal, DS.hPad)
        .padding(.vertical, DS.rowV)
        .opacity(cs == .dark ? 0.55 : 1.0)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func actionRow(icon: String, bg: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                NXIconBox(icon: icon, bg: bg)
                Text(title).font(.system(size: DS.bodySz)).foregroundStyle(fg)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(fg.opacity(0.2))
            }
            .padding(.horizontal, DS.hPad)
            .padding(.vertical, DS.rowV)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Sign Out

    private var signOutSection: some View {
        SignOutButton { showSignOutAlert = true }
    }

    // MARK: - Bottom Links

    private var bottomLinks: some View {
        HStack(spacing: 8) {
            SBottomIcon(icon: "paperplane.fill", label: "Канал") { openURL("https://t.me/nexus_app") }
            SBottomIcon(icon: "envelope.fill",   label: "Почта")  { openURL("mailto:qwizord@icloud.com") }
            SBottomIcon(icon: "person.fill",     label: "Автор")  { openURL("https://t.me/vector_anton") }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Timezone helper

    /// Курированный список популярных таймзон, отсортированный по смещению от GMT.
    /// Полный IANA-список (~400 зон) был избыточен — оставили ~50 ключевых городов.
    static let sortedTimezoneIDs: [String] = {
        let picked: [String] = [
            // Pacific (-12 … -8)
            "Pacific/Midway",           // GMT-11
            "Pacific/Honolulu",         // GMT-10
            "America/Anchorage",        // GMT-9
            "America/Los_Angeles",      // GMT-8
            "America/Vancouver",        // GMT-8
            // Americas (-7 … -3)
            "America/Denver",           // GMT-7
            "America/Phoenix",          // GMT-7
            "America/Chicago",          // GMT-6
            "America/Mexico_City",      // GMT-6
            "America/New_York",         // GMT-5
            "America/Toronto",          // GMT-5
            "America/Caracas",          // GMT-4
            "America/Sao_Paulo",        // GMT-3
            "America/Buenos_Aires",     // GMT-3
            // Atlantic / Europe / Africa (0 … +3)
            "Atlantic/Azores",          // GMT-1
            "UTC",                      // GMT+0
            "Europe/London",            // GMT+0
            "Europe/Dublin",            // GMT+0
            "Europe/Lisbon",            // GMT+0
            "Africa/Casablanca",        // GMT+1
            "Europe/Paris",             // GMT+1
            "Europe/Berlin",            // GMT+1
            "Europe/Madrid",            // GMT+1
            "Europe/Rome",              // GMT+1
            "Europe/Amsterdam",         // GMT+1
            "Europe/Warsaw",            // GMT+1
            "Europe/Prague",            // GMT+1
            "Europe/Stockholm",         // GMT+1
            "Europe/Vienna",            // GMT+1
            "Europe/Athens",            // GMT+2
            "Europe/Helsinki",          // GMT+2
            "Europe/Kiev",              // GMT+2
            "Europe/Istanbul",          // GMT+3
            "Europe/Moscow",            // GMT+3
            "Europe/Minsk",             // GMT+3
            // Middle East / Asia (+3 … +9)
            "Asia/Dubai",               // GMT+4
            "Asia/Tehran",              // GMT+3:30
            "Asia/Karachi",             // GMT+5
            "Asia/Yekaterinburg",       // GMT+5
            "Asia/Kolkata",             // GMT+5:30
            "Asia/Dhaka",               // GMT+6
            "Asia/Novosibirsk",         // GMT+7
            "Asia/Bangkok",             // GMT+7
            "Asia/Jakarta",             // GMT+7
            "Asia/Shanghai",            // GMT+8
            "Asia/Hong_Kong",           // GMT+8
            "Asia/Singapore",           // GMT+8
            "Asia/Seoul",               // GMT+9
            "Asia/Tokyo",               // GMT+9
            // Australia / Pacific (+10 … +14)
            "Australia/Sydney",         // GMT+10
            "Australia/Melbourne",      // GMT+10
            "Asia/Vladivostok",         // GMT+10
            "Pacific/Auckland",         // GMT+12
            "Asia/Kamchatka"            // GMT+12
        ]
        return picked.sorted { a, b in
            let sa = TimeZone(identifier: a)?.secondsFromGMT() ?? 0
            let sb = TimeZone(identifier: b)?.secondsFromGMT() ?? 0
            if sa != sb { return sa < sb }
            return a < b
        }
    }()

    /// Преобразует IANA-идентификатор в русскоязычную метку вида «Москва (GMT+3)».
    static func timezoneLabel(_ identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return identifier }
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let mins = abs(seconds % 3600) / 60
        let sign = hours >= 0 ? "+" : "-"
        let offset: String = (mins == 0)
            ? String(format: "GMT%@%d", sign, abs(hours))
            : String(format: "GMT%@%d:%02d", sign, abs(hours), mins)

        // 1) Сначала наш собственный словарь (самые частые города — красивее перевод).
        let raw = identifier.split(separator: "/").last
            .map { String($0).replacingOccurrences(of: "_", with: " ") } ?? identifier
        if let fromDict = cityRu[raw] {
            return "\(fromDict) (\(offset))"
        }
        // 2) iOS-локализация на русский — убираем «стандартное время» / «летнее время».
        let ru = Locale(identifier: "ru_RU")
        let locName = tz.localizedName(for: .standard, locale: ru)
                   ?? tz.localizedName(for: .generic,  locale: ru)
                   ?? raw
        let cleaned = locName
            .replacingOccurrences(of: ", стандартное время", with: "")
            .replacingOccurrences(of: " стандартное время", with: "")
            .replacingOccurrences(of: ", летнее время", with: "")
            .replacingOccurrences(of: " летнее время", with: "")
            .replacingOccurrences(of: "Стандартное время ", with: "")
            .replacingOccurrences(of: "Летнее время ", with: "")
            .trimmingCharacters(in: .whitespaces)
        return "\(cleaned) (\(offset))"
    }

    /// Ручной словарь перевода английских названий городов на русский.
    /// Покрывает популярные таймзоны; для остальных возвращает оригинал.
    private static let cityRu: [String: String] = [
        "Moscow": "Москва", "Kaliningrad": "Калининград", "Samara": "Самара",
        "Volgograd": "Волгоград", "Saratov": "Саратов", "Astrakhan": "Астрахань",
        "Yekaterinburg": "Екатеринбург", "Omsk": "Омск", "Novosibirsk": "Новосибирск",
        "Krasnoyarsk": "Красноярск", "Irkutsk": "Иркутск", "Yakutsk": "Якутск",
        "Vladivostok": "Владивосток", "Magadan": "Магадан", "Srednekolymsk": "Среднеколымск",
        "Kamchatka": "Камчатка", "Anadyr": "Анадырь", "Sakhalin": "Сахалин",
        "Khandyga": "Хандыга", "Ust-Nera": "Усть-Нера", "Chita": "Чита", "Tomsk": "Томск",
        "Barnaul": "Барнаул", "Novokuznetsk": "Новокузнецк", "Ulyanovsk": "Ульяновск",
        "Kirov": "Киров", "Simferopol": "Симферополь", "Kiev": "Киев", "Kyiv": "Киев",
        "Minsk": "Минск", "Tbilisi": "Тбилиси", "Yerevan": "Ереван", "Baku": "Баку",
        "Almaty": "Алматы", "Aqtobe": "Актобе", "Aqtau": "Актау", "Atyrau": "Атырау",
        "Bishkek": "Бишкек", "Tashkent": "Ташкент", "Samarkand": "Самарканд",
        "Dushanbe": "Душанбе", "Ashgabat": "Ашхабад", "Kabul": "Кабул",
        "London": "Лондон", "Paris": "Париж", "Berlin": "Берлин", "Madrid": "Мадрид",
        "Rome": "Рим", "Amsterdam": "Амстердам", "Brussels": "Брюссель", "Vienna": "Вена",
        "Warsaw": "Варшава", "Prague": "Прага", "Budapest": "Будапешт", "Zurich": "Цюрих",
        "Lisbon": "Лиссабон", "Dublin": "Дублин", "Stockholm": "Стокгольм",
        "Oslo": "Осло", "Helsinki": "Хельсинки", "Copenhagen": "Копенгаген",
        "Athens": "Афины", "Istanbul": "Стамбул", "Bucharest": "Бухарест",
        "Sofia": "София", "Belgrade": "Белград", "Zagreb": "Загреб", "Luxembourg": "Люксембург",
        "Reykjavik": "Рейкьявик", "Riga": "Рига", "Tallinn": "Таллин", "Vilnius": "Вильнюс",
        "Chisinau": "Кишинёв", "Kaliningrad_RU": "Калининград",
        "New York": "Нью-Йорк", "Los Angeles": "Лос-Анджелес", "Chicago": "Чикаго",
        "Denver": "Денвер", "Phoenix": "Финикс", "Anchorage": "Анкоридж",
        "Honolulu": "Гонолулу", "Toronto": "Торонто", "Vancouver": "Ванкувер",
        "Mexico City": "Мехико", "Sao Paulo": "Сан-Паулу", "Buenos Aires": "Буэнос-Айрес",
        "Tokyo": "Токио", "Seoul": "Сеул", "Shanghai": "Шанхай", "Hong Kong": "Гонконг",
        "Singapore": "Сингапур", "Bangkok": "Бангкок", "Jakarta": "Джакарта",
        "Manila": "Манила", "Ho Chi Minh": "Хошимин", "Kolkata": "Калькутта",
        "Mumbai": "Мумбаи", "Delhi": "Дели", "Karachi": "Карачи", "Dhaka": "Дакка",
        "Dubai": "Дубай", "Riyadh": "Эр-Рияд", "Tehran": "Тегеран", "Jerusalem": "Иерусалим",
        "Cairo": "Каир", "Johannesburg": "Йоханнесбург", "Nairobi": "Найроби",
        "Lagos": "Лагос", "Casablanca": "Касабланка", "Algiers": "Алжир",
        "Sydney": "Сидней", "Melbourne": "Мельбурн", "Perth": "Перт",
        "Brisbane": "Брисбен", "Adelaide": "Аделаида", "Darwin": "Дарвин", "Hobart": "Хобарт",
        "Auckland": "Окленд", "Wellington": "Веллингтон",
        "UTC": "UTC", "GMT": "GMT"
    ]

    private static func ruCityName(_ raw: String) -> String {
        if let ru = cityRu[raw] { return ru }
        return raw
    }

    // MARK: - Face ID

    private func triggerBiometrics() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            appState.settings.faceIDEnabled = false; return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Войти в Nexus") { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.easeInOut(duration: 0.35)) { faceIDSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { faceIDSuccess = false }
                    }
                } else {
                    appState.settings.faceIDEnabled = false
                }
            }
        }
    }

    // MARK: - Notifications & Spotlight

    /// При изменении тоггла «Уведомления»:
    ///  • ON  → запрашиваем разрешение; если уже denied — отправляем в Settings.app
    ///          (тут просто сбрасываем тоггл, чтобы пользователь увидел, что системное разрешение
    ///          нужно дать вручную).
    ///  • OFF → снимаем все запланированные локальные уведомления.
    private func handleNotificationsToggle(_ enabled: Bool) {
        if enabled {
            Task { @MainActor in
                let center = UNUserNotificationCenter.current()
                let settings = await center.notificationSettings()
                switch settings.authorizationStatus {
                case .notDetermined:
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        NotificationManager.shared.enableAllScheduled()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        notifOn = false
                        authErrorMessage = "Разрешение на уведомления не выдано. Включи его в Настройках iOS."
                        showAuthError = true
                    }
                case .authorized, .provisional, .ephemeral:
                    NotificationManager.shared.enableAllScheduled()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case .denied:
                    notifOn = false
                    authErrorMessage = "Уведомления отключены в системных Настройках. Открой Настройки → Nexus → Уведомления."
                    showAuthError = true
                @unknown default:
                    notifOn = false
                }
            }
        } else {
            NotificationManager.shared.disableAll()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// При изменении Spotlight — индексируем/чистим основные экраны приложения.
    private func handleSpotlightToggle(_ enabled: Bool) {
        if enabled {
            SpotlightManager.shared.indexAppShortcuts()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            SpotlightManager.shared.removeAllShortcuts()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// При появлении экрана — синхронизируем UI со статусом системы:
    /// если пользователь отключил уведомления в iOS Settings, toggle должен это отразить.
    private func syncNotificationAuthorization() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let systemAllowed = settings.authorizationStatus == .authorized ||
                                settings.authorizationStatus == .provisional ||
                                settings.authorizationStatus == .ephemeral
            // Если система отказала, принудительно гасим локальный тоггл.
            if !systemAllowed && notifOn {
                notifOn = false
            }
        }
    }

    /// Если Spotlight включён в настройках — переиндексируем при открытии Settings,
    /// на случай если контент/тексты разделов изменились.
    private func syncSpotlightState() {
        if spotlightOn {
            SpotlightManager.shared.indexAppShortcuts()
        }
    }

    // MARK: - Cache

    private func computeCacheSize() {
        DispatchQueue.global(qos: .background).async {
            let total = scanCacheSize()
            let fmt = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
            DispatchQueue.main.async { cacheSize = fmt }
        }
    }

    private func scanCacheSize() -> Int64 {
        var total: Int64 = 0
        let fm = FileManager.default
        if let url = fm.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let f as URL in enumerator {
                total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
        }
        return total
    }

    private func prepareAndShowCacheBreakdown() {
        DispatchQueue.global(qos: .userInitiated).async {
            let items = buildCacheItems()
            DispatchQueue.main.async {
                cacheItems = items
                showCacheBreakdown = true
            }
        }
    }

    /// Динамически перечисляет все верхнеуровневые элементы в Caches и tmp,
    /// считает суммарный размер каждого, присваивает дружелюбное название и
    /// иконку. Раньше было захардкожено 5 имён → у живого приложения почти
    /// всегда оставался только пункт «Прочее». Теперь видны все категории.
    private func buildCacheItems() -> [CacheItem] {
        let fm = FileManager.default
        var items: [CacheItem] = []

        // Базы для скана: Library/Caches + tmp.
        var bases: [URL] = []
        if let cache = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            bases.append(cache)
        }
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        bases.append(tmpURL)

        // Накапливаем размер «верхнеуровневых» отдельных файлов в корне Caches/tmp
        // в один общий пункт «Корневые файлы». Папки идут отдельными пунктами.
        var rootFilesSize: Int64 = 0

        for base in bases {
            guard let entries = try? fm.contentsOfDirectory(
                at: base,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries {
                let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let size  = directorySize(at: entry, fileManager: fm)
                guard size > 0 else { continue }

                if isDir {
                    let meta = friendlyMeta(for: entry.lastPathComponent, isTmp: base == tmpURL)
                    items.append(CacheItem(name: meta.label, icon: meta.icon, size: size))
                } else {
                    rootFilesSize += size
                }
            }
        }

        if rootFilesSize > 0 {
            items.append(CacheItem(name: "Корневые файлы", icon: "doc.fill", size: rootFilesSize))
        }

        // Объединяем пункты с одинаковым названием (например, два «Логи» из
        // разных корней суммируются в один).
        var merged: [String: CacheItem] = [:]
        for it in items {
            if let cur = merged[it.name] {
                merged[it.name] = CacheItem(name: cur.name, icon: cur.icon, size: cur.size + it.size)
            } else {
                merged[it.name] = it
            }
        }
        return merged.values.sorted { $0.size > $1.size }
    }

    /// Рекурсивно считает байты внутри URL (или возвращает размер файла).
    private func directorySize(at url: URL, fileManager: FileManager) -> Int64 {
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        if !isDir {
            return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        var total: Int64 = 0
        if let en = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let f as URL in en {
                total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
        }
        return total
    }

    /// Бакетирует ЛЮБОЕ имя папки/файла кэша в один из ~8 человеческих
    /// разделов. В UI ни в каком случае не должны просачиваться сырые
    /// bundle-id'ы (com.apple.WebKit.Networking и т.п.) — они все
    /// сворачиваются в «Системный кэш».
    private func friendlyMeta(for folderName: String, isTmp: Bool) -> (label: String, icon: String) {
        let lower = folderName.lowercased()

        // 1. Изображения — image-кэши SDK (SDImage, Kingfisher, FBImage...).
        if lower.contains("image") || lower.contains("photo")
            || lower.contains("kingfisher") || lower.contains("sdwebimage") {
            return ("Изображения", "photo.fill")
        }

        // 2. Сетевые данные — URLCache / fsCachedData / HTTP-кэш.
        if lower.contains("urlcache") || lower.contains("nsurlcache")
            || lower.contains("fscacheddata") || lower.contains("httpcache")
            || lower.contains("network") {
            return ("Сетевые данные", "network")
        }

        // 3. Снимки UIKit (мульти-таскинг превью, TextKit-снэпшоты).
        if lower.contains("snapshot") {
            return ("Снимки экрана", "rectangle.on.rectangle")
        }

        // 4. Логи / краш-репорты.
        if lower.contains("log") || lower.contains("crashreport") || lower.contains("diagnostic") {
            return ("Логи", "list.bullet.rectangle")
        }

        // 5. Firebase / Firestore (всё, что начинается на firebase / firestore / fir_).
        if lower.contains("firestore") || lower.contains("firebase")
            || lower.hasPrefix("fir_") {
            return ("Firebase", "flame.fill")
        }

        // 6. Google SDK (Sign-In, GTM, AdMob и т.п.).
        if lower.hasPrefix("com.google.") || lower.contains("googleusermessagingplatform")
            || lower.contains("gtm") {
            return ("Google SDK", "g.circle.fill")
        }

        // 7. База данных — sqlite / realm / coredata.
        if lower.contains("database") || lower.hasSuffix(".sqlite") || lower.hasSuffix(".db")
            || lower.contains("realm") || lower.contains("coredata") {
            return ("База данных", "cylinder.fill")
        }

        // 8. Медиа — видео / аудио.
        if lower.contains("video") || lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") {
            return ("Видео", "play.rectangle.fill")
        }
        if lower.contains("audio") || lower.contains("sound") || lower.hasSuffix(".m4a") {
            return ("Аудио", "speaker.wave.2.fill")
        }

        // 9. Системный кэш — всё, что относится к iOS/Apple-фреймворкам:
        //    WebKit, Metal, CFNetwork, UIKit, CoreText и т.д. Эти папки
        //    раньше просачивались в UI как «com.apple.WebKit.Networking»;
        //    теперь свёрнуты в один понятный раздел.
        if lower.hasPrefix("com.apple.") || lower.contains("webkit") || lower.contains("metal")
            || lower.contains("cfnetwork") || lower.contains("coretext") || lower.contains("uikit") {
            return ("Системный кэш", "gearshape.fill")
        }

        // 10. Шрифты / документы / загрузки — на всякий случай.
        if lower.contains("font") { return ("Шрифты", "textformat") }
        if lower.contains("download") { return ("Загрузки", "arrow.down.circle.fill") }
        if lower.contains("document") { return ("Документы", "doc.text.fill") }

        // 11. tmp-подпапки → «Временные файлы».
        if isTmp || lower.contains("temp") || lower.contains("tmp") {
            return ("Временные файлы", "doc.fill")
        }

        // 12. Всё остальное — «Прочее». Никаких bundle-id'ов в UI.
        return ("Прочее", "tray.fill")
    }

    // MARK: - Auth Method Handlers

    private func handleConnect(kind: AuthMethodKind) {
        selectedAuthMethod = nil
        switch kind {
        case .email, .password:
            // Email+Password провайдер линкуется через тот же экран смены email —
            // пользователь задаёт email и пароль, Firebase делает link автоматически.
            if kind == .email { showChangeEmail = true } else { showChangePassword = true }
        case .phone:
            showLinkPhone = true
        case .apple, .google:
            // Apple/Google link-flow требует полноценного OAuth presentation —
            // пока показываем заглушку через Alert.
            authErrorMessage = "Привязка \(kind.title) через экран настроек будет добавлена в следующей версии. Сейчас — выйди и войди через \(kind.title), чтобы связать аккаунт."
            showAuthError = true
        }
    }

    private func handleChange(kind: AuthMethodKind) {
        selectedAuthMethod = nil
        switch kind {
        case .email:    showChangeEmail = true
        case .password: showChangePassword = true
        case .phone:    showLinkPhone = true
        case .apple, .google: break
        }
    }

    private func handleDisconnect(kind: AuthMethodKind) {
        selectedAuthMethod = nil
        Task {
            do {
                try await authManager.unlink(providerID: kind.providerID)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    authErrorMessage = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                    showAuthError = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }

    // MARK: - Integration State

    /// Возвращает актуальное состояние подключения. Если пользователь переключал
    /// — берём из runtime `integrationStates`, иначе — дефолт из `allIntegrations`.
    private func isConnected(_ item: IntegrationItem) -> Bool {
        integrationStates[item.name] ?? item.connected
    }

    private func toggleConnection(for item: IntegrationItem) {
        let newValue = !isConnected(item)
        integrationStates[item.name] = newValue
        saveIntegrationStates()
        let hap = UINotificationFeedbackGenerator()
        hap.notificationOccurred(newValue ? .success : .warning)
    }

    private func loadIntegrationStates() {
        guard let data = integrationStatesJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data)
        else { return }
        integrationStates = dict
    }

    private func saveIntegrationStates() {
        if let data = try? JSONEncoder().encode(integrationStates),
           let str = String(data: data, encoding: .utf8) {
            integrationStatesJSON = str
        }
    }

    private func performClearCache() {
        let fm = FileManager.default
        if let url = fm.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
            for file in contents { try? fm.removeItem(at: file) }
        }
        cacheSize = "0 Б"
        cacheItems = []
    }
}

// MARK: - Integration Card (Carousel Item)

private struct IntegrationCard: View {
    let icon: String
    var asset: String? = nil
    var assetColorful: Bool = false
    let bg: Color
    let name: String
    let connected: Bool
    @Environment(\.colorScheme) private var cs

    /// Проверяем наличие бренд-ассета: если PDF/PNG с таким именем есть
    /// в Assets.xcassets — используем его, иначе SF Symbol.
    private var hasBrandAsset: Bool {
        guard let a = asset, !a.isEmpty else { return false }
        return UIImage(named: a) != nil
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(bg)
                    .frame(width: 52, height: 52)
                    .shadow(color: bg.opacity(0.35), radius: 4, y: 2)

                iconView

                if connected {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .offset(x: 18, y: -18)
                }
            }
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(cs == .dark ? .white.opacity(0.7) : Color(red:0.11,green:0.11,blue:0.14).opacity(0.7))
                .lineLimit(1)
                .frame(width: 68)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 100)
        .glassCard(radius: 18)
    }

    @ViewBuilder
    private var iconView: some View {
        if hasBrandAsset, let asset {
            if assetColorful {
                Image(asset)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            } else {
                Image(asset)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
            }
        } else {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - NXPill

private struct NXPill: View {
    let text: String
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(fg.opacity(0.5))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(fg.opacity(0.08), in: Capsule())
    }
}

// MARK: - Cache Item Model

struct CacheItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let size: Int64
    var formattedSize: String { ByteCountFormatter.string(fromByteCount: size, countStyle: .file) }
}

// MARK: - Account Link Status

enum AccountLinkStatus { case connected, notConnected }

// MARK: - Privacy Sheet

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var closePressed = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                Text(privacyText)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
            .navigationTitle("Политика конфиденциальности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(cs == .dark ? .white : .black)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }
            }
        }
    }

    private let privacyText = """
    🔒 Твои данные — только твои.

    Nexus создаётся как приложение, которому ты доверяешь самое личное: здоровье, финансы, цели. Поэтому приватность — не формальность, а часть дизайна.

    🛡 Что мы делаем
    • Данные шифруются end-to-end и хранятся в Firebase, в Google Cloud.
    • HealthKit читается только локально — ни один байт не уходит на сторонние сервисы.
    • В аналитику летят только агрегированные, обезличенные метрики (DAU, экраны, краши).
    • Мы запрашиваем минимальный набор разрешений — ровно то, что нужно для фичи.

    🚫 Чего мы не делаем
    • Не продаём данные рекламным сетям.
    • Не передаём твои цифры третьим лицам.
    • Не храним пароли в открытом виде — Firebase Auth использует bcrypt.

    🗑 Твой контроль
    • В любой момент ты можешь удалить аккаунт — вместе с ним удаляются все связанные данные.
    • Можешь экспортировать свои записи одной кнопкой.

    ✉️ Вопросы, NDA, GDPR-запросы — qwizord@icloud.com
    """
}

// MARK: - Integration Detail Sheet

struct IntegrationDetailSheet: View {
    let integration: SettingsView.IntegrationItem
    let connected: Bool
    let onToggle: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var closePressed = false
    @State private var actionPressed = false
    @State private var confirmDisconnect = false

    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }

    /// Описание и список синхронизируемых данных по каждой интеграции.
    private static let meta: [String: (desc: String, points: [String])] = [
        "Health": ("Синхронизация со встроенным приложением Apple Health. Читает метрики локально — ни один байт не уходит на сторонние серверы.",
                   ["Шаги и активность", "Пульс и HRV", "Сон и восстановление", "Вес и состав тела"]),
        "Calendar": ("Показывает встречи в ежедневной ленте и напоминает о важных событиях.",
                     ["События календаря", "Напоминания", "Приглашения"]),
        "iCloud": ("Синхронизация данных Nexus между устройствами через твой iCloud.",
                   ["Бэкап настроек", "Общие заметки", "Синхронизация прогресса"]),
        "Apple Watch": ("Отправляет уведомления, треккинг активности и hands-free управление ИИ-агентом.",
                        ["Real-time пульс", "Треккинг тренировок", "Уведомления", "Siri-команды"]),
        "Oura Ring": ("Импортирует данные о сне, восстановлении и готовности.",
                      ["Sleep score", "Readiness score", "Температура тела", "HRV"]),
        "Garmin": ("Данные с Garmin Connect: тренировки, GPS-треки, продвинутая аналитика.",
                   ["Workouts", "VO2 Max", "Training load", "GPS-треки"]),
        "Whoop": ("Recovery, strain и sleep-аналитика от Whoop.",
                  ["Recovery", "Strain", "Sleep performance", "HRV"]),
        "Fitbit": ("Активность, сон и ЧСС с устройств Fitbit.",
                   ["Шаги и калории", "Sleep stages", "Resting HR", "SpO2"]),
        "Polar": ("Тренировки, пульс и Training Load из Polar Flow.",
                  ["Workouts", "HR zones", "Recovery Pro", "Training Load"]),
        "Withings": ("Smart-весы и устройства здоровья Withings.",
                     ["Вес и жир", "Артериальное давление", "ECG", "Температура"]),
        "Dexcom": ("Непрерывный мониторинг глюкозы.",
                   ["CGM real-time", "Тренды глюкозы", "Алерты", "History"]),
        "Samsung": ("Здоровье и активность из Samsung Health.",
                    ["Steps & Activity", "Heart Rate", "Sleep", "Stress"])
    ]

    private var meta: (desc: String, points: [String]) {
        Self.meta[integration.name] ?? ("Подключите интеграцию для синхронизации данных.", [])
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Большая иконка
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(integration.bg)
                            .frame(width: 96, height: 96)
                            .shadow(color: integration.bg.opacity(0.5), radius: 16, y: 6)
                        bigIconView
                    }
                    .padding(.top, 8)

                    VStack(spacing: 6) {
                        Text(integration.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(fg)

                        statusPill
                    }

                    // Описание
                    Text(meta.desc)
                        .font(.system(size: 15))
                        .foregroundStyle(fg.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    // Список синхронизируемых данных
                    if !meta.points.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("СИНХРОНИЗИРУЕТСЯ")
                                .font(.system(size: 11, weight: .semibold))
                                .kerning(0.5)
                                .foregroundStyle(fg.opacity(0.4))
                                .padding(.leading, 20)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(Array(meta.points.enumerated()), id: \.offset) { idx, point in
                                    HStack(spacing: 12) {
                                        Image(systemName: connected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 16))
                                            .foregroundStyle(connected ? Color.green : fg.opacity(0.3))
                                        Text(point)
                                            .font(.system(size: 15))
                                            .foregroundStyle(fg)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    if idx < meta.points.count - 1 {
                                        Divider().background(.white.opacity(0.06)).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(fg.opacity(0.08), lineWidth: 0.5))
                        }
                        .padding(.horizontal, 16)
                    }

                    // Кнопка Connect / Disconnect
                    actionButton
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(fg)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }
            }
            .alert("Отключить \(integration.name)?", isPresented: $confirmDisconnect) {
                Button("Отключить", role: .destructive) {
                    onToggle()
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Nexus перестанет синхронизировать данные с \(integration.name). Ты сможешь подключить их заново в любое время.")
            }
        }
    }

    @ViewBuilder
    private var bigIconView: some View {
        if let asset = integration.asset, UIImage(named: asset) != nil {
            if integration.assetColorful {
                Image(asset).resizable().renderingMode(.original).scaledToFit().frame(width: 56, height: 56)
            } else {
                Image(asset).resizable().renderingMode(.template).scaledToFit().frame(width: 52, height: 52).foregroundStyle(.white)
            }
        } else {
            Image(systemName: integration.icon)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connected ? Color.green : fg.opacity(0.35))
                .frame(width: 8, height: 8)
            Text(connected ? "Подключено" : "Не подключено")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(connected ? .green : fg.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Capsule().fill((connected ? Color.green : fg).opacity(0.10))
        )
    }

    private var actionButton: some View {
        Button {
            if connected {
                confirmDisconnect = true
            } else {
                onToggle()
                dismiss()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: connected ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(connected ? "Отключить" : "Подключить")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(connected ? Color.red : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(connected ? Color.red.opacity(0.10) : integration.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(connected ? Color.red.opacity(0.25) : .clear, lineWidth: 1)
            )
            .scaleEffect(actionPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { actionPressed = true } }
                .onEnded { _ in withAnimation(.easeInOut(duration: 0.15)) { actionPressed = false } }
        )
    }
}

// MARK: - Auth Method Sheet

struct AuthMethodSheet: View {
    let kind: SettingsView.AuthMethodKind
    let status: AccountLinkStatus
    let subtitle: String?
    let onConnect: () -> Void
    let onChange: () -> Void
    let onDisconnect: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var closePressed = false
    @State private var confirmDisconnect = false

    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    private var connected: Bool { status == .connected }

    private var iconBg: Color {
        switch kind {
        case .apple:    return cs == .dark ? Color(red:0.2,green:0.2,blue:0.22) : Color(red:0.85,green:0.85,blue:0.87)
        case .google:   return .white
        case .email:    return Color(red:0.0,green:0.35,blue:0.9)
        case .password: return Color(red:0.4,green:0.4,blue:0.45)
        case .phone:    return Color(red:0.1,green:0.7,blue:0.3)
        }
    }

    private var iconName: String {
        switch kind {
        case .apple:    return "apple.logo"
        case .google:   return "Google-icon"
        case .email:    return "envelope.fill"
        case .password: return "lock.fill"
        case .phone:    return "phone.fill"
        }
    }

    private var description: String {
        switch kind {
        case .apple:
            return "Sign in with Apple — приватный способ входа, который не передаёт твой email рекламным сетям."
        case .google:
            return "Вход через Google-аккаунт. Быстро и без паролей."
        case .email:
            return "Классический вход по email и паролю. Работает на любом устройстве без внешних провайдеров."
        case .password:
            return "Пароль используется при входе по email. Можно поменять в любой момент."
        case .phone:
            return "Вход или восстановление доступа через SMS-код на твой номер."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Иконка
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(iconBg)
                            .frame(width: 88, height: 88)
                            .shadow(color: iconBg.opacity(0.35), radius: 12, y: 6)
                        iconView
                    }
                    .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text(kind.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(fg)
                        statusPill
                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(fg.opacity(0.5))
                                .padding(.top, 2)
                        }
                    }

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(fg.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    // Действия
                    VStack(spacing: 10) {
                        if connected {
                            if kind == .email || kind == .password || kind == .phone {
                                actionButton(title: "Изменить",
                                             icon: "pencil",
                                             tint: Color(red: 0.0, green: 0.48, blue: 1.0),
                                             filled: false,
                                             action: onChange)
                            }
                            actionButton(title: "Отключить",
                                         icon: "link.badge.minus",
                                         tint: .red,
                                         filled: false,
                                         destructive: true,
                                         action: { confirmDisconnect = true })
                        } else {
                            actionButton(title: "Подключить",
                                         icon: "link",
                                         tint: Color(red: 0.0, green: 0.48, blue: 1.0),
                                         filled: true,
                                         action: onConnect)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(fg)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }
            }
            .alert("Отключить \(kind.title)?", isPresented: $confirmDisconnect) {
                Button("Отключить", role: .destructive) { onDisconnect() }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Ты сможешь привязать \(kind.title) обратно в любой момент. Важно оставить минимум один способ входа, иначе ты не сможешь войти в аккаунт.")
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if kind == .google {
            Image("Google-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
        } else {
            Image(systemName: iconName)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(kind == .apple ? (cs == .dark ? Color.white : Color.black) : .white)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connected ? Color.green : fg.opacity(0.35))
                .frame(width: 8, height: 8)
            Text(connected ? "Подключено" : "Не подключено")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(connected ? .green : fg.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill((connected ? Color.green : fg).opacity(0.10)))
    }

    private func actionButton(title: String, icon: String, tint: Color,
                              filled: Bool, destructive: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(filled ? .white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(filled ? tint : tint.opacity(destructive ? 0.08 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(filled ? .clear : tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Detail View

struct StatsDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    private var bg: Color { cs == .dark ? .white.opacity(0.05) : .black.opacity(0.04) }
    private let weekDays = ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
    private let aiValues = [5, 12, 8, 15, 7, 11, 9]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("Активность").font(.system(size: 15, weight: .semibold)).foregroundStyle(fg)
                            Spacer()
                            Text("14 дней подряд").font(.system(size: 12, weight: .medium)).foregroundStyle(.orange)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                            ForEach(weekDays, id: \.self) { day in
                                Text(day).font(.system(size: 10)).foregroundStyle(fg.opacity(0.4)).frame(maxWidth: .infinity)
                            }
                            ForEach(0..<28, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(i < 14 ? fg.opacity(0.08) : Color.orange).frame(height: 28)
                            }
                        }
                    }
                    .padding(16).background(bg, in: RoundedRectangle(cornerRadius: 16))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        SStatCard(icon: "heart.fill", iconColor: Color(red:0.85,green:0.1,blue:0.2), value: "28", label: "Записей о здоровье", subtitle: "шаги, сон, ЧСС", subtitleColor: Color(red:1,green:0.2,blue:0.2))
                        SStatCard(icon: "creditcard.fill", iconColor: .green, value: "—", label: "Транзакций", subtitle: "доходы и расходы", subtitleColor: .green)
                        SStatCard(icon: "flame.fill", iconColor: .orange, value: "2", label: "Дней в приложении", subtitle: "с регистрации", subtitleColor: .orange)
                        SStatCard(icon: "bubble.left.fill", iconColor: .purple, value: "—", label: "Сессий AI", subtitle: "создано всего", subtitleColor: .purple)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Статистика").navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(fg.opacity(0.6)).frame(width: 32, height: 32)
                            .background(fg.opacity(0.1), in: Circle())
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Shared Sub-Components (kept for backward compat)

struct SSettingsGroup<Content: View>: View {
    let title: String
    let content: () -> Content
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    private var stroke: Color { cs == .dark ? .white.opacity(0.1) : .black.opacity(0.07) }
    init(title: String, @ViewBuilder content: @escaping () -> Content) { self.title = title; self.content = content }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .semibold)).kerning(0.5).textCase(.uppercase)
                .foregroundStyle(fg.opacity(0.35)).padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 0.5))
        }
    }
}

struct SDivider: View {
    @Environment(\.colorScheme) private var cs
    var body: some View {
        Divider()
            .background(cs == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06))
            .padding(.leading, 62)
    }
}

struct SStatCard: View {
    let icon: String; let iconColor: Color
    let value: String; let label: String
    let subtitle: String; let subtitleColor: Color
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    private var bg: Color { cs == .dark ? .white.opacity(0.05) : .black.opacity(0.04) }
    private var stroke: Color { cs == .dark ? .white.opacity(0.08) : .black.opacity(0.06) }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.2)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(iconColor)
            }
            Text(value).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(fg).padding(.top, 14)
            Text(label).font(.system(size: 12)).foregroundStyle(fg.opacity(0.4)).lineLimit(2).padding(.top, 4)
            Spacer(minLength: 6)
            Text(subtitle).font(.system(size: 11)).foregroundStyle(subtitleColor)
        }
        .padding(14).frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(bg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(stroke, lineWidth: 0.5))
    }
}

struct SStatPill: View {
    let label: String
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    var body: some View {
        Text(label).font(.system(size: 11)).foregroundStyle(fg.opacity(0.5))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(fg.opacity(0.08), in: Capsule())
    }
}

// MARK: - Sign Out Button (стиль как на экране входа + блокировка скролла)

private struct SignOutButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var cs
    @State private var pressed = false

    var body: some View {
        // Полупрозрачная капсула: тонкий красный оттенок + material blur.
        // Благодаря .glassEffect(.interactive()) «жидкое стекло» следует за
        // пальцем — текст внутри визуально смещается к точке касания.
        Capsule()
            .fill(Color.red.opacity(0.06))
            .overlay {
                Capsule().strokeBorder(Color.red.opacity(0.25), lineWidth: 0.7)
            }
            .overlay {
                Text("Выйти из аккаунта")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.red)
            }
            .frame(width: 220, height: 50)
            .glassEffect(.regular.interactive(), in: Capsule())
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
            .contentShape(Capsule())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { g in
                        pressed = false
                        if abs(g.translation.width) < 18 && abs(g.translation.height) < 18 {
                            action()
                        }
                    }
            )
    }
}

struct SBottomIcon: View {
    let icon: String; let label: String; let action: () -> Void
    @Environment(\.colorScheme) private var cs
    @State private var pressed = false
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(fg)
                .frame(width: 44, height: 44)
                .applyGlassCircle()
                // Скейл только на иконке — подпись внизу не дёргается.
                .scaleEffect(pressed ? 0.90 : 1.0)
                .animation(.easeInOut(duration: 0.18), value: pressed)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(fg.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(width: 56, height: 66)
        .contentShape(Rectangle())
        // highPriorityGesture блокирует вертикальный скролл ScrollView,
        // пока палец на иконке — экран не едет при нажатии.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { g in
                    pressed = false
                    if abs(g.translation.width) < 18 && abs(g.translation.height) < 18 {
                        action()
                    }
                }
        )
    }
}

// Backward-compat aliases
typealias StatCard         = SStatCard
typealias StatPill         = SStatPill
typealias SettingsGroup    = SSettingsGroup
typealias SettingsDivider  = SDivider
typealias BottomIconButton = SBottomIcon

struct SettingsCard<Content: View>: View {
    let content: () -> Content
    @Environment(\.colorScheme) private var cs
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(
                cs == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.07), lineWidth: 0.5))
    }
}

struct SettingsRow: View {
    let icon: String; let iconColor: Color; let title: String; let value: String
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    var body: some View {
        HStack(spacing: 14) {
            ZStack { RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.18)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(iconColor) }
            Text(title).font(.system(size: 15)).foregroundStyle(fg)
            Spacer()
            if !value.isEmpty { Text(value).font(.system(size: 13)).foregroundStyle(fg.opacity(0.35)) }
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(fg.opacity(0.2))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct SettingsTappableRow: View {
    let icon: String; let iconColor: Color; let title: String; let value: String; let action: () -> Void
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack { RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.18)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundStyle(iconColor) }
                Text(title).font(.system(size: 15)).foregroundStyle(fg)
                Spacer()
                if !value.isEmpty { Text(value).font(.system(size: 13)).foregroundStyle(fg.opacity(0.35)) }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(fg.opacity(0.2))
            }
            .padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggle: View {
    let icon: String; let iconColor: Color; let title: String; @Binding var isOn: Bool
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    var body: some View {
        HStack(spacing: 14) {
            ZStack { RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.18)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(iconColor) }
            Text(title).font(.system(size: 15)).foregroundStyle(fg)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.blue)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Account Method Row (standalone, kept for compat)

struct AccountMethodRow: View {
    let icon: String
    let iconBg: Color
    let iconColor: Color
    let title: String
    var status: AccountLinkStatus = .notConnected
    var onConnect: () -> Void = {}
    var onChange: () -> Void = {}
    var onRemove: () -> Void = {}
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(iconBg).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 17)).foregroundStyle(iconColor)
            }
            Text(title).font(.system(size: 15)).foregroundStyle(fg)
            Spacer()
            switch status {
            case .connected:
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("Подключён").font(.system(size: 12)).foregroundStyle(.green)
                }
            case .notConnected:
                Text("Подключить").font(.system(size: 12)).foregroundStyle(fg.opacity(0.35))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .contextMenu {
            if status == .notConnected {
                Button { onConnect() } label: { Label("Подключить", systemImage: "link") }
            } else {
                Button { onChange() } label: { Label("Изменить", systemImage: "pencil") }
                Button(role: .destructive) { onRemove() } label: { Label("Отключить", systemImage: "link.badge.minus") }
            }
        }
    }
}

// MARK: - Pure Gaussian Blur (UIKit-backed)
///
/// Настоящий Gaussian-блюр с регулируемым радиусом через CABackdropLayer +
/// CAFilter (приватное API, но стабильно работает во всех текущих iOS).
/// В отличие от `.ultraThinMaterial` или UIBlurEffect не добавляет vibrancy/тинт —
/// только чистое размытие подложки.
private struct GaussianBlurView: UIViewRepresentable {
    var radius: CGFloat

    final class BackdropView: UIView {
        override class var layerClass: AnyClass {
            NSClassFromString("CABackdropLayer") ?? CALayer.self
        }
    }

    func makeUIView(context: Context) -> BackdropView {
        let v = BackdropView()
        applyFilter(to: v)
        return v
    }

    func updateUIView(_ uiView: BackdropView, context: Context) {
        applyFilter(to: uiView)
    }

    private func applyFilter(to view: BackdropView) {
        guard
            let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
            let filter = filterClass
                .perform(NSSelectorFromString("filterWithName:"), with: "gaussianBlur")?
                .takeUnretainedValue()
        else { return }
        (filter as AnyObject).setValue(radius, forKey: "inputRadius")
        view.layer.filters = [filter]
    }
}

// MARK: - Sheets

struct ChangeEmailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newEmail = ""; @State private var password = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Новый email", text: $newEmail).keyboardType(.emailAddress).autocapitalization(.none)
                    .padding(14).background(.ultraThinMaterial, in: Capsule())
                SecureField("Текущий пароль", text: $password)
                    .padding(14).background(.ultraThinMaterial, in: Capsule())
                Button("Сохранить") { dismiss() }.foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(red:0,green:0.48,blue:1), in: Capsule())
                Spacer()
            }
            .padding(20)
            .navigationTitle("Изменить email").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }.foregroundStyle(Color(red:0,green:0.48,blue:1))
            }}
        }
    }
}

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""; @State private var newPwd = ""; @State private var confirm = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SecureField("Текущий пароль", text: $current).padding(14).background(.ultraThinMaterial, in: Capsule())
                SecureField("Новый пароль", text: $newPwd).padding(14).background(.ultraThinMaterial, in: Capsule())
                SecureField("Повторите", text: $confirm).padding(14).background(.ultraThinMaterial, in: Capsule())
                Button("Сохранить") { dismiss() }.foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(red:0,green:0.48,blue:1), in: Capsule())
                Spacer()
            }
            .padding(20)
            .navigationTitle("Сменить пароль").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }.foregroundStyle(Color(red:0,green:0.48,blue:1))
            }}
        }
    }
}

struct LinkPhoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phone = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("+7 (___) ___-__-__", text: $phone).keyboardType(.phonePad)
                    .padding(14).background(.ultraThinMaterial, in: Capsule())
                Button("Продолжить") { dismiss() }.foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(red:0,green:0.48,blue:1), in: Capsule())
                Spacer()
            }
            .padding(20)
            .navigationTitle("Привязать телефон").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }.foregroundStyle(Color(red:0,green:0.48,blue:1))
            }}
        }
    }
}

struct InfoSheet: View {
    let kind: SettingsView.InfoSheetKind
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var closePressed = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                Text(infoText)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(cs == .dark ? .white : .black)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }
            }
        }
    }

    var infoText: String {
        switch kind {
        case .faq:
            return """
            💡 Часто задаваемые вопросы

            🔄 Как синхронизировать данные?
            Открой Настройки → Интеграции и включи нужные источники. Health Kit, банки, календари — всё тянется автоматически.

            🗄 Где хранятся данные?
            Шифруются end-to-end и лежат в Firebase (Google Cloud). На наших серверах — только агрегированная статистика.

            🧠 AI не отвечает — что делать?
            Проверь интернет. AI работает через наш сервер n8n; если он на паузе — попробуй через 1–2 минуты.

            🎨 Как сменить тему?
            Настройки → Внешний вид → Тема. Светлая, тёмная или авто (по системе).

            🔐 Как включить Face ID?
            Настройки → Аккаунт → Face ID. После включения приложение запрашивает биометрию при запуске.

            🗑 Как удалить аккаунт?
            Напиши в поддержку: qwizord@icloud.com. Удалим профиль и все данные в течение 24 часов.

            🧾 Можно ли экспортировать данные?
            Да — напиши в поддержку, пришлём CSV/JSON-архив по запросу.
            """
        case .changelog:
            return """
            📝 Журнал изменений

            🚀 Версия 1.0 · Апрель 2026
            • 🎉 Запуск MVP
            • 🔐 Auth: Email, Google, Apple Sign In
            • ❤️ Health: синхронизация с HealthKit, 30-дневный график
            • 💰 Finance: 18 категорий, правило 50/30/20, графики
            • 🎓 Learning: курсы, прогресс, категории
            • 🤖 AI: чат с агентами через n8n
            • 👤 Profile: фото, био, все поля профиля
            • ⚙️ Settings: Face ID, управление кэшем, 12 языков

            🛠 Версия 0.9 · Март 2026
            • 🧪 Закрытая бета для 50 пользователей
            • 🐞 Первые багфиксы и отладка

            💌 Нашёл баг или есть идея? Пиши: qwizord@icloud.com
            """
        case .terms:
            return """
            📜 Условия использования

            👋 Что это
            Nexus — персональный помощник для здоровья, финансов и обучения. Используя приложение, ты соглашаешься с условиями ниже.

            ⚖️ «Как есть»
            Приложение предоставляется as-is. Мы стараемся, чтобы всё работало, но не гарантируем отсутствие багов и перерывов в работе сервера.

            🛡 Твоя ответственность
            • Хранить данные для входа в безопасности.
            • Не использовать Nexus для незаконных целей.
            • Не пытаться получить доступ к чужим аккаунтам.

            💎 Подписка
            Премиум-функции доступны по подписке через App Store. Автопродление можно отключить в настройках Apple ID.

            🚫 Мы имеем право
            Ограничить или приостановить доступ при нарушении условий.

            📬 Связь
            По всем вопросам: qwizord@icloud.com
            """
        }
    }
}

// MARK: - Cache Breakdown Sheet (glassmorphism)

struct CacheBreakdownSheet: View {
    let items: [CacheItem]
    let totalSize: String
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var confirmClear = false
    @State private var closePressed = false
    @State private var clearPressed = false

    private var rowBg: Color { cs == .dark ? Color(white: 0.13) : Color(white: 0.96) }
    private var rowStroke: Color { cs == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if items.isEmpty {
                    Spacer()
                    Text("Кэш пуст")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.blue.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: item.icon)
                                            .font(.system(size: 15))
                                            .foregroundStyle(.blue)
                                    }
                                    Text(item.name).font(.system(size: 15))
                                    Spacer()
                                    Text(item.formattedSize)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(rowStroke, lineWidth: 0.6)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .scrollIndicators(.hidden)
                }

                // Кнопка в том же стиле, что и «Выйти из аккаунта»:
                // полупрозрачная red-капсула, interactive glass, блок скролла.
                Capsule()
                    .fill(Color.red.opacity(0.06))
                    .overlay { Capsule().strokeBorder(Color.red.opacity(0.25), lineWidth: 0.7) }
                    .overlay {
                        Text("Очистить кэш")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    .frame(width: 220, height: 50)
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .scaleEffect(clearPressed ? 0.97 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: clearPressed)
                    .contentShape(Capsule())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in clearPressed = true }
                            .onEnded { g in
                                clearPressed = false
                                if abs(g.translation.width) < 18 && abs(g.translation.height) < 18 {
                                    confirmClear = true
                                }
                            }
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Кэш · \(totalSize)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Системный glass-круг уже даёт фон — просто кладём крестик.
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(cs == .dark ? .white : .black)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }
            }
        }
        .alert("Очистить кэш?", isPresented: $confirmClear) {
            Button("Очистить", role: .destructive) { onClear(); dismiss() }
            Button("Отмена", role: .cancel) {}
        } message: { Text("Данные загрузятся заново при следующем использовании.") }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - TooltipPopupView (kept for compatibility)

struct TooltipPopupView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { onDismiss() }
            VStack(spacing: 20) {
                Text(message).font(.system(size: 15)).foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Button { onDismiss() } label: {
                    Text("OK").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(red:0,green:0.48,blue:1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - App Passcode Store
//
// Хранилище 4-значного код-пароля приложения. Telegram-style flow:
//   1. Пользователь устанавливает 4 цифры → SHA256-хэш в UserDefaults.
//   2. На следующем входе хэш-сравнение разблокирует app.
//   3. Face ID — это надстройка ПОВЕРХ кода (fallback на ввод цифр).
//
// Plain UserDefaults тут осознанный компромисс: Keychain дал бы +security,
// но добавил бы 70+ строк boilerplate. SHA256-хэш делает brute force всё
// равно нерациональным при 4 цифрах + локальной попытке.

enum AppPasscodeStore {
    private static let key = "nx.appPasscode.sha256"

    static var isSet: Bool {
        guard let str = UserDefaults.standard.string(forKey: key) else { return false }
        return !str.isEmpty
    }

    /// Сохраняет SHA256-хэш кода. Перезаписывает существующий.
    static func save(_ code: String) {
        UserDefaults.standard.set(hash(code), forKey: key)
    }

    /// Сравнивает введённый код с сохранённым хэшем.
    static func verify(_ code: String) -> Bool {
        guard let stored = UserDefaults.standard.string(forKey: key) else { return false }
        return stored == hash(code)
    }

    /// Полностью удаляет код-пароль (после disable-flow).
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func hash(_ s: String) -> String {
        let data = Data(s.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Passcode Setup / Change / Disable Sheet
//
// Один универсальный шит для трёх операций:
//   • setup   — два шага: «новый код» → «повторите».
//   • change  — три шага: «текущий» → «новый» → «повторите».
//   • disable — один шаг: «текущий», после успеха onSuccess стирает код.
//
// 4-значный pin без подтверждающих кнопок: вводишь 4 цифры — шаг едет
// сам. Ошибка → встряска + красная подпись + сброс.

struct PasscodeSetupSheet: View {
    enum Mode { case setup, change, disable }

    let mode: Mode
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs

    /// Текущий шаг внутри flow.
    private enum Step { case verifyOld, enterNew, confirmNew }
    @State private var step: Step = .verifyOld

    @State private var input: String = ""
    @State private var firstEntry: String = ""
    @State private var errorText: String? = nil
    @State private var shake: Bool = false
    @FocusState private var focused: Bool

    private var fg: Color {
        cs == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
    }

    private var title: String {
        switch (mode, step) {
        case (.setup, .enterNew):       return "Установите код-пароль"
        case (.setup, .confirmNew):     return "Повторите код-пароль"
        case (.change, .verifyOld):     return "Текущий код-пароль"
        case (.change, .enterNew):      return "Новый код-пароль"
        case (.change, .confirmNew):    return "Повторите новый код"
        case (.disable, _):             return "Введите код-пароль"
        default:                        return "Введите код-пароль"
        }
    }

    private var subtitle: String {
        switch (mode, step) {
        case (.setup, .enterNew):       return "Придумайте 4 цифры. Они потребуются при запуске Nexus."
        case (.setup, .confirmNew):     return "Введите те же 4 цифры ещё раз."
        case (.change, .verifyOld):     return "Подтвердите текущий код, чтобы изменить его."
        case (.change, .enterNew):      return "Придумайте новые 4 цифры."
        case (.change, .confirmNew):    return "Введите новые 4 цифры ещё раз."
        case (.disable, _):             return "Подтвердите текущий код, чтобы отключить защиту."
        default:                        return ""
        }
    }

    var body: some View {
        VStack(spacing: 22) {
            // Заголовок
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(fg)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(fg.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)

            // Точки-индикатор ввода
            HStack(spacing: 18) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < input.count ? Color(red: 0.0, green: 0.48, blue: 1.0) : fg.opacity(0.12))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().strokeBorder(fg.opacity(0.18), lineWidth: 0.5)
                        )
                }
            }
            .offset(x: shake ? -8 : 0)
            .animation(.default, value: shake)

            if let err = errorText {
                Text(err)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.85))
                    .transition(.opacity)
            }

            // Скрытое текстовое поле — берёт цифровую клавиатуру.
            // Подключённое через .focused, обеспечивает автопоявление клавы.
            TextField("", text: $input)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.001)
                .frame(height: 1)
                .onChange(of: input) { _, new in
                    handleInput(new)
                }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            cs == .dark
                ? Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea()
                : Color(red: 0.96, green: 0.97, blue: 0.99).ignoresSafeArea()
        )
        .onAppear {
            // Стартовый шаг зависит от режима.
            step = (mode == .setup) ? .enterNew : .verifyOld
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { focused = true }
        }
    }

    private func handleInput(_ value: String) {
        // Только цифры, максимум 4.
        let filtered = String(value.prefix(4).filter { $0.isNumber })
        if filtered != value { input = filtered; return }
        guard filtered.count == 4 else { return }

        switch step {
        case .verifyOld:
            if AppPasscodeStore.verify(filtered) {
                if mode == .disable {
                    onSuccess()
                    dismiss()
                } else {
                    advance(to: .enterNew)
                }
            } else {
                fail("Неверный код-пароль")
            }

        case .enterNew:
            firstEntry = filtered
            advance(to: .confirmNew)

        case .confirmNew:
            if filtered == firstEntry {
                AppPasscodeStore.save(filtered)
                onSuccess()
                dismiss()
            } else {
                firstEntry = ""
                fail("Коды не совпадают")
                advance(to: .enterNew)
            }
        }
    }

    private func advance(to next: Step) {
        withAnimation(.easeInOut(duration: 0.2)) {
            step = next
            input = ""
            errorText = nil
        }
    }

    private func fail(_ msg: String) {
        errorText = msg
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        withAnimation(.default) { shake.toggle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.default) { shake.toggle() }
            input = ""
        }
    }
}

// MARK: - Passcode Lock (полноэкранная страница как в Telegram)
//
// Push'ится из Settings → «Код-пароль и Face ID». Один экран, glass-фон во
// всю высоту, два сгруппированных «карточных» блока (как в iOS Settings):
//   1. Кнопки «Включить/Изменить/Отключить» + поясняющий текст под ними.
//   2. «Auto-Lock» picker + toggle «Unlock with Face ID».
//
// Sheet-ы для setup/change/disable — те же самые PasscodeSetupSheet, что
// уже использовал в первой версии экрана; повторно их не описываю.

struct PasscodeLockView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var cs
    @Binding var passcodeTick: Int

    @State private var showSetup   = false
    @State private var showChange  = false
    @State private var showDisable = false

    private var fg: Color {
        cs == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
    }
    private var bg: Color {
        cs == .dark
            ? Color(red: 0.07, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.97, blue: 0.99)
    }

    /// Опции auto-lock. -1 = «Никогда».
    private let autoLockOptions: [(label: String, sec: Int)] = [
        ("Сразу",            0),
        ("Через 1 минуту",   60),
        ("Через 5 минут",    300),
        ("Через 1 час",      3600),
        ("Через 5 часов",    18000),
        ("Никогда",          -1)
    ]

    private func autoLockLabel(for sec: Int) -> String {
        autoLockOptions.first(where: { $0.sec == sec })?.label ?? "Через 1 час"
    }

    var body: some View {
        // passcodeTick — для force-refresh после save/clear хэша.
        let _ = passcodeTick
        let passcodeIsSet = AppPasscodeStore.isSet

        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // ────────── Карточка 1: основные действия + note ──────────
                VStack(alignment: .leading, spacing: 0) {
                    actionsCard(passcodeIsSet: passcodeIsSet)

                    Text(noteText(passcodeIsSet: passcodeIsSet))
                        .font(.system(size: 12))
                        .foregroundStyle(fg.opacity(0.50))
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // ────────── Карточка 2: auto-lock + Face ID ──────────
                if passcodeIsSet {
                    autoLockCard
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bg.ignoresSafeArea())
        .navigationTitle("Код-пароль и Face ID")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.automatic, for: .navigationBar)
        .sheet(isPresented: $showSetup) {
            PasscodeSetupSheet(mode: .setup) {
                appState.settings.appPasscodeEnabled = true
                passcodeTick &+= 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showChange) {
            PasscodeSetupSheet(mode: .change) {
                passcodeTick &+= 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDisable) {
            PasscodeSetupSheet(mode: .disable) {
                AppPasscodeStore.clear()
                appState.settings.appPasscodeEnabled = false
                appState.settings.faceIDEnabled = false
                passcodeTick &+= 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: Cards

    @ViewBuilder
    private func actionsCard(passcodeIsSet: Bool) -> some View {
        VStack(spacing: 0) {
            if passcodeIsSet {
                actionRow(label: "Изменить код-пароль", color: DS.accent1) {
                    showChange = true
                }
                divider
                actionRow(label: "Отключить код-пароль",
                          color: Color(red: 0.95, green: 0.30, blue: 0.30)) {
                    showDisable = true
                }
            } else {
                actionRow(label: "Включить код-пароль", color: DS.accent1) {
                    showSetup = true
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(fg.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var autoLockCard: some View {
        VStack(spacing: 0) {
            // Auto-Lock picker (Menu)
            Menu {
                ForEach(autoLockOptions, id: \.sec) { opt in
                    Button {
                        appState.settings.appAutoLockSec = opt.sec
                    } label: {
                        if appState.settings.appAutoLockSec == opt.sec {
                            Label(opt.label, systemImage: "checkmark")
                        } else {
                            Text(opt.label)
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Auto-Lock")
                        .font(.system(size: 15))
                        .foregroundStyle(fg)
                    Spacer()
                    Text(autoLockLabel(for: appState.settings.appAutoLockSec))
                        .font(.system(size: 14))
                        .foregroundStyle(fg.opacity(0.55))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(fg.opacity(0.30))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            divider

            // Unlock with Face ID
            HStack {
                Text("Разблокировка по Face ID")
                    .font(.system(size: 15))
                    .foregroundStyle(fg)
                Spacer()
                Toggle("", isOn: $appState.settings.faceIDEnabled)
                    .labelsHidden()
                    .tint(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(fg.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: Helpers

    private func actionRow(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(color)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(fg.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private func noteText(passcodeIsSet: Bool) -> String {
        if passcodeIsSet {
            return "Когда код-пароль включён, при запуске Nexus будет запрашивать его. Если вы забудете код, потребуется переустановить приложение — все локальные данные будут потеряны."
        } else {
            return "Установите 4-значный код-пароль для дополнительной защиты приложения. Вместе с Face ID код-пароль работает как резервный способ входа, если биометрия не сработает."
        }
    }
}
