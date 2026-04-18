import SwiftUI
import PhotosUI
import UIKit
import LocalAuthentication
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
    static let rowV:   CGFloat = 13
    static let radius: CGFloat = 20
    static let iconSz: CGFloat = 40

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
                TimelineView(.animation) { ctx in
                    let phase = CGFloat(
                        ctx.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: dur)
                    ) / dur
                    HStack(spacing: gap) { textLabel; textLabel }
                        .offset(x: -phase * cycle)
                }
                .clipped()
            } else {
                textLabel.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: 20)
        .background(
            textLabel.fixedSize().hidden()
                .background(GeometryReader { g in
                    Color.clear.onAppear { textWidth = g.size.width }
                })
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
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var cs

    // Integration toggles
    @State private var healthOn    = true
    @State private var calendarOn  = true
    @State private var iCloudOn    = false
    @State private var notifOn     = true
    @State private var spotlightOn = true

    // Security
    @State private var faceIDOn      = false
    @State private var faceIDSuccess = false

    // Preferences
    @State private var selectedTheme    = AppTheme.system
    @State private var selectedUnits    = "Метрическая"
    @State private var selectedTimezone = "Москва (GMT+3)"
    @State private var selectedCurrency = "🇷🇺 Рубль (₽)"

    // Cache
    @State private var cacheSize         = "—"
    @State private var showCacheBreakdown = false

    // Integrations carousel custom scroll
    @State private var carouselOffset: CGFloat = 0
    @State private var carouselDragStart: CGFloat = 0
    @State private var cacheItems: [CacheItem] = []

    // Scroll offset for top blur fade-in
    @State private var scrollY: CGFloat = 0

    // Account actions
    @State private var showChangeEmail    = false
    @State private var showChangePassword = false
    @State private var showLinkPhone      = false

    // Overlays / Sheets
    @State private var showProfileEdit    = false
    @State private var showShareSheet     = false
    @State private var showStatsDetail    = false
    @State private var showSignOutAlert   = false
    @State private var showLanguageAlert  = false
    @State private var showPrivacyOverlay = false
    @State private var showInfoSheet: InfoSheetKind? = nil
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
    struct IntegrationItem: Hashable {
        let icon: String
        let bg: Color
        let name: String
        let connected: Bool
        func hash(into hasher: inout Hasher) { hasher.combine(name) }
        static func == (l: Self, r: Self) -> Bool { l.name == r.name }
    }
    private let allIntegrations: [IntegrationItem] = [
        .init(icon: "heart.fill",             bg: Color(red:0.9,green:0.1,blue:0.2),  name: "Health",         connected: true ),
        .init(icon: "calendar",               bg: Color(red:0.6,green:0.0,blue:0.0),  name: "Calendar",       connected: true ),
        .init(icon: "icloud.fill",            bg: Color(red:0.0,green:0.35,blue:0.9), name: "iCloud",         connected: false),
        .init(icon: "applewatch",             bg: Color(red:0.3,green:0.3,blue:0.35), name: "Apple Watch",    connected: false),
        .init(icon: "circle.hexagongrid.fill",bg: Color(red:0.45,green:0.3,blue:0.9),name: "Oura Ring",      connected: false),
        .init(icon: "waveform.path.ecg",      bg: Color(red:0.0,green:0.6,blue:0.3),  name: "Garmin",         connected: false),
        .init(icon: "bolt.heart.fill",        bg: Color(red:0.85,green:0.1,blue:0.1), name: "Whoop",          connected: false),
        .init(icon: "figure.run",             bg: Color(red:0.0,green:0.5,blue:1.0),  name: "Fitbit",         connected: false),
        .init(icon: "target",                 bg: Color(red:0.7,green:0.0,blue:0.0),  name: "Polar",          connected: false),
        .init(icon: "scalemass.fill",         bg: Color(red:0.3,green:0.5,blue:0.9),  name: "Withings",       connected: false),
        .init(icon: "drop.fill",              bg: Color(red:0.0,green:0.5,blue:0.8),  name: "Dexcom",         connected: false),
        .init(icon: "s.circle.fill",          bg: Color(red:0.0,green:0.6,blue:0.3),  name: "Samsung",        connected: false),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.vGap) {
                        profileSection.slideIn(delay: 0.10)
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


                // Copy toast
                if copiedID {
                    VStack {
                        Spacer()
                        Text("ID скопирован")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(fg.opacity(0.85), in: Capsule())
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
        .sheet(isPresented: $showShareSheet) { ShareSheet(activityItems: ["Я использую Nexus!"]) }
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
                            IntegrationCard(icon: item.icon, bg: item.bg, name: item.name, connected: item.connected)
                        }
                    }
                    .padding(.horizontal, DS.hPad)
                    .frame(width: totalW + DS.hPad * 2, height: geo.size.height, alignment: .leading)
                    .offset(x: carouselOffset)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                .contentShape(Rectangle())
                .clipped()
                // Шейдер натягивает этот плоский layer на цилиндр.
                .distortionEffect(
                    ShaderLibrary.cylinderDistort(
                        .float2(Float(geo.size.width), Float(geo.size.height)),
                        .float(1.0)
                    ),
                    maxSampleOffset: CGSize(width: 60, height: 40)
                )
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,              location: 0.00),
                            .init(color: .black.opacity(0.6), location: 0.04),
                            .init(color: .black,              location: 0.10),
                            .init(color: .black,              location: 0.90),
                            .init(color: .black.opacity(0.6), location: 0.96),
                            .init(color: .clear,              location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
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
            // Theme
            prefRow(icon: "paintbrush.fill", bg: Color(red:0.55,green:0.1,blue:0.9), label: "Тема") {
                Picker("", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                }
                .pickerStyle(.menu).tint(fg.opacity(0.5))
                .onChange(of: selectedTheme) { _, t in appState.settings.theme = t }
            }
            NXDivider()
            // Language
            prefRow(icon: "globe", bg: Color(red:0.0,green:0.4,blue:0.9), label: "Язык") {
                Picker("", selection: $appState.settings.language) {
                    Text("🇺🇸 English").tag("en_US")
                    Text("🇷🇺 Русский").tag("ru_RU")
                    Text("🇪🇸 Español").tag("es_ES")
                    Text("🇫🇷 Français").tag("fr_FR")
                    Text("🇩🇪 Deutsch").tag("de_DE")
                    Text("🇮🇹 Italiano").tag("it_IT")
                    Text("🇧🇷 Português").tag("pt_BR")
                    Text("🇯🇵 日本語").tag("ja_JP")
                    Text("🇰🇷 한국어").tag("ko_KR")
                    Text("🇨🇳 中文").tag("zh_CN")
                    Text("🇸🇦 العربية").tag("ar_SA")
                    Text("🇮🇳 हिन्दी").tag("hi_IN")
                    Text("🇹🇷 Türkçe").tag("tr_TR")
                    Text("🇺🇦 Українська").tag("uk_UA")
                    Text("🇵🇱 Polski").tag("pl_PL")
                }
                .pickerStyle(.menu).tint(fg.opacity(0.5))
                .onChange(of: appState.settings.language) { _, _ in showLanguageAlert = true }
            }
            NXDivider()
            // Units
            prefRow(icon: "ruler.fill", bg: Color(red:0.3,green:0.3,blue:0.36), label: "Единицы") {
                Picker("", selection: $selectedUnits) {
                    Text("Метрическая").tag("Метрическая")
                    Text("Имперская").tag("Имперская")
                }
                .pickerStyle(.menu).tint(fg.opacity(0.5))
            }
            NXDivider()
            // Timezone
            prefRow(icon: "clock.fill", bg: Color(red:0.2,green:0.5,blue:0.85), label: "Часовой пояс") {
                Menu {
                    ForEach(["Москва (GMT+3)","Санкт-Петербург (GMT+3)","Екатеринбург (GMT+5)",
                             "Новосибирск (GMT+7)","Владивосток (GMT+10)","Лондон (GMT+0)",
                             "Берлин (GMT+1)","Дубай (GMT+4)","Нью-Йорк (GMT-5)",
                             "Лос-Анджелес (GMT-8)","Токио (GMT+9)","Пекин (GMT+8)"], id: \.self) { tz in
                        Button(tz) { selectedTimezone = tz }
                    }
                } label: {
                    HStack(spacing: 4) {
                        NXMarqueeText(text: selectedTimezone,
                                      font: .system(size: 14),
                                      color: Color(.secondaryLabel))
                            .frame(width: 130)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(fg.opacity(0.3))
                    }
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
                    HStack(spacing: 4) {
                        NXMarqueeText(text: selectedCurrency,
                                      font: .system(size: 14),
                                      color: Color(.secondaryLabel))
                            .frame(width: 130)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(fg.opacity(0.3))
                    }
                }
            }
        }
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
        NXSection(title: "Безопасность") {
            // Face ID
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.iconSz * 0.26)
                        .fill(Color.green)
                        .frame(width: DS.iconSz, height: DS.iconSz)
                    Image(systemName: "faceid")
                        .font(.system(size: faceIDOn ? 22 : 18, weight: .regular))
                        .foregroundStyle(.white)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: faceIDOn)
                }
                Text("Face ID / Touch ID")
                    .font(.system(size: DS.bodySz))
                    .foregroundStyle(fg)
                Spacer()
                Toggle("", isOn: $faceIDOn)
                    .labelsHidden()
                    .tint(.green)
                    .onChange(of: faceIDOn) { _, on in if on { triggerBiometrics() } }
            }
            .padding(.horizontal, DS.hPad)
            .padding(.vertical, DS.rowV)

            NXDivider()

            // Notifications
            toggleRow(icon: "bell.fill", bg: Color(red:0.35,green:0.35,blue:0.4),
                      label: "Уведомления", isOn: $notifOn)
            NXDivider()

            // Spotlight
            toggleRow(icon: "magnifyingglass", bg: Color(red:0.35,green:0.35,blue:0.4),
                      label: "Spotlight", isOn: $spotlightOn)
        }
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
                    NXMarqueeText(
                        text: userID,
                        font: .system(size: 11, design: .monospaced),
                        color: Color(.secondaryLabel),
                        speed: 22
                    )
                    .padding(.horizontal, 10)
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.accent1.opacity(0.7))
                        .fixedSize()
                        .layoutPriority(1)
                }
                .padding(.horizontal, DS.hPad)
                .padding(.vertical, DS.rowV)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())

            NXDivider()

            // Apple ID
            accountMethodRow(icon: "apple.logo",
                iconBg: cs == .dark ? Color(red:0.2,green:0.2,blue:0.22) : Color(red:0.85,green:0.85,blue:0.87),
                iconColor: cs == .dark ? .white : .black,
                title: "Apple ID", status: .notConnected,
                onConnect: {}, onChange: {}, onRemove: {})
            NXDivider()

            // Google
            accountMethodRow(icon: "globe",
                iconBg: Color(red:0.85,green:0.1,blue:0.1), iconColor: .white,
                title: "Google", status: .connected,
                onConnect: {}, onChange: {}, onRemove: {})
            NXDivider()

            // Email
            accountMethodRow(icon: "envelope.fill",
                iconBg: Color(red:0.0,green:0.35,blue:0.9), iconColor: .white,
                title: "Email", status: .notConnected,
                onConnect: { showChangeEmail = true },
                onChange: { showChangeEmail = true },
                onRemove: {})
            NXDivider()

            // Password
            accountMethodRow(icon: "lock.fill",
                iconBg: Color(red:0.4,green:0.4,blue:0.45), iconColor: .white,
                title: "Пароль", status: .notConnected,
                onConnect: { showChangePassword = true },
                onChange: { showChangePassword = true },
                onRemove: {})
            NXDivider()

            // Phone
            accountMethodRow(icon: "phone.fill",
                iconBg: Color(red:0.1,green:0.7,blue:0.3), iconColor: .white,
                title: "Телефон", status: .notConnected,
                onConnect: { showLinkPhone = true },
                onChange: { showLinkPhone = true },
                onRemove: {})
        }
    }

    @ViewBuilder
    private func accountMethodRow(icon: String, iconBg: Color, iconColor: Color,
                                  title: String, status: AccountLinkStatus,
                                  onConnect: @escaping () -> Void,
                                  onChange: @escaping () -> Void,
                                  onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.iconSz * 0.26)
                    .fill(iconBg)
                    .frame(width: DS.iconSz, height: DS.iconSz)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(title).font(.system(size: DS.bodySz)).foregroundStyle(fg)
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
        }
        .padding(.horizontal, DS.hPad)
        .padding(.vertical, DS.rowV)
        .contextMenu {
            if status == .notConnected {
                Button { onConnect() } label: { Label("Подключить", systemImage: "link") }
            } else {
                Button { onChange() } label: { Label("Изменить", systemImage: "pencil") }
                Button(role: .destructive) { onRemove() } label: { Label("Отключить", systemImage: "link.badge.minus") }
            }
        }
    }

    // MARK: - Support & Info

    private var supportInfoSection: some View {
        NXSection(title: "Поддержка и информация") {
            // Write to support
            actionRow(icon: "bubble.left.fill", bg: .blue.opacity(0.8), title: "Написать в поддержку") { }
            NXDivider()

            // Support the project
            Button { } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.iconSz * 0.26)
                            .fill(LinearGradient(
                                colors: [Color(red:0.1,green:0.75,blue:0.35), Color(red:0.05,green:0.55,blue:0.25)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: DS.iconSz, height: DS.iconSz)
                            .shadow(color: Color(red:0.1,green:0.7,blue:0.3).opacity(0.35), radius: 8, y: 3)
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    Text("Поддержать проект")
                        .font(.system(size: DS.bodySz, weight: .semibold))
                        .foregroundStyle(fg)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(fg.opacity(0.2))
                }
                .padding(.horizontal, DS.hPad)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())

            NXDivider()
            actionRow(icon: "star.fill", bg: Color(red:1,green:0.75,blue:0), title: "Оценить в App Store") { }
            NXDivider()

            // Mac version (disabled)
            HStack(spacing: 14) {
                NXIconBox(icon: "display", bg: .gray.opacity(0.25))
                Text("Mac версия")
                    .font(.system(size: DS.bodySz))
                    .foregroundStyle(fg.opacity(0.35))
                Spacer()
                Text("Скоро")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(.gray.opacity(0.4), in: Capsule())
            }
            .padding(.horizontal, DS.hPad)
            .padding(.vertical, DS.rowV)
            .disabled(true)

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
        Button { showSignOutAlert = true } label: {
            Text("Выйти из аккаунта")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.red)
                .padding(.horizontal, 32)
                .padding(.vertical, 13)
                .background(Color.red.opacity(0.09))
                .overlay(Capsule().strokeBorder(Color.red.opacity(0.25), lineWidth: 0.7))
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Bottom Links

    private var bottomLinks: some View {
        HStack(spacing: 14) {
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

    // MARK: - Face ID

    private func triggerBiometrics() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            faceIDOn = false; return
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
                    faceIDOn = false
                }
            }
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

    private func buildCacheItems() -> [CacheItem] {
        var items: [CacheItem] = []
        let fm = FileManager.default
        guard let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return [] }
        let knownFolders: [(String, String, String)] = [
            ("Images",   "Изображения",    "photo.fill"),
            ("URLCache", "API-данные",     "network"),
            ("Temp",     "Временные файлы","doc.fill"),
            ("Logs",     "Логи",           "list.bullet.rectangle"),
            ("Database", "База данных",    "cylinder.fill"),
        ]
        for (folder, label, icon) in knownFolders {
            let url = base.appendingPathComponent(folder)
            var size: Int64 = 0
            if let en = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let f as URL in en {
                    size += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                }
            }
            if size > 0 { items.append(CacheItem(name: label, icon: icon, size: size)) }
        }
        let accounted = Set(knownFolders.map { base.appendingPathComponent($0.0).path })
        var other: Int64 = 0
        if let en = fm.enumerator(at: base, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let f as URL in en {
                if !accounted.contains(where: { f.path.hasPrefix($0) }) {
                    other += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                }
            }
        }
        if other > 0 { items.append(CacheItem(name: "Прочее", icon: "folder.fill", size: other)) }
        return items.sorted { $0.size > $1.size }
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
    let bg: Color
    let name: String
    let connected: Bool
    @Environment(\.colorScheme) private var cs

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(bg)
                    .frame(width: 52, height: 52)
                    .shadow(color: bg.opacity(0.4), radius: 6, y: 3)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)

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
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.28), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private let privacyText = """
    Мы уважаем вашу приватность.

    • Данные не продаются третьим лицам.
    • Все данные хранятся зашифрованно на серверах Firebase.
    • Данные HealthKit используются только внутри приложения.
    • Вы можете удалить аккаунт и все данные в любое время.
    • Мы используем минимально необходимый набор разрешений.
    • Аналитика ограничена агрегированными, обезличенными данными.

    По всем вопросам: qwizord@icloud.com
    """
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

struct SBottomIcon: View {
    let icon: String; let label: String; let action: () -> Void
    @Environment(\.colorScheme) private var cs
    private var fg: Color { cs == .dark ? .white : Color(red:0.11,green:0.11,blue:0.14) }
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(fg)
                    .frame(width: 44, height: 44)
                    .applyGlassCircle()
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(fg.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 70)
        }
        .buttonStyle(PressableButtonStyle())
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
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.28), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var infoText: String {
        switch kind {
        case .faq:
            return "1. Как синхронизировать данные?\nОткройте Настройки → Интеграции и включите нужные источники.\n\n2. Где хранятся данные?\nВсё зашифровано на серверах Firebase.\n\n3. Как удалить аккаунт?\nНапишите в поддержку по адресу qwizord@icloud.com.\n\n4. AI не работает — что делать?\nПроверь интернет-соединение. AI работает через сервер n8n.\n\n5. Как изменить тему?\nНастройки → Внешний вид → Тема."
        case .changelog:
            return "Версия 1.0 (Апрель 2026)\n• Запуск MVP\n• Auth: Email, Google, Apple Sign In\n• Health: HealthKit интеграция\n• Finance: учёт доходов и расходов\n• Learning: курсы и прогресс\n• AI: чат с агентами\n• Settings: полный профиль"
        case .terms:
            return "Используя приложение Nexus, вы соглашаетесь с условиями обслуживания.\n\nПриложение предоставляется «как есть». Мы не несём ответственности за любые убытки от использования приложения.\n\nВы несёте ответственность за сохранность данных вашего аккаунта.\n\nПо всем вопросам: qwizord@icloud.com"
        }
    }
}

// MARK: - Cache Breakdown Sheet (glassmorphism)

struct CacheBreakdownSheet: View {
    let items: [CacheItem]
    let totalSize: String
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if items.isEmpty {
                    Spacer()
                    Text("Кэш пуст")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
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
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }

                Button { confirmClear = true } label: {
                    Text("Очистить кэш")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.red, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle("Кэш · \(totalSize)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.28), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
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
