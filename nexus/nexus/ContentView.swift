import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLocked = false
    @State private var showSplash = true
    @State private var splashDismissWorkItem: DispatchWorkItem?
    /// Время, когда приложение ушло в background. Используется для
    /// auto-lock: при возврате сравниваем с appAutoLockSec и решаем,
    /// нужно ли требовать pin/Face ID.
    @State private var lastBackgroundDate: Date?

    /// Нужна ли в принципе блокировка приложения. Telegram-style: код-пароль
    /// и/или Face ID могут быть включены независимо, но любой включённый
    /// триггерит lock-экран.
    private var lockEnabled: Bool {
        appState.settings.appPasscodeEnabled || appState.settings.faceIDEnabled
    }

    var body: some View {
        ZStack {
            ZStack {
                AdaptiveRootBackground()
                switch appState.currentScreen {
                case .auth:
                    AuthView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .onboarding:
                    OnboardingView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .main:
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // Lock overlay — полностью непрозрачный фон поверх контента.
                // Внутри: Face ID с авто-fallback на 4-значный pin + пункт
                // «обратиться в поддержку» если код забыт.
                if isLocked {
                    AppLockView(
                        passcodeEnabled: appState.settings.appPasscodeEnabled,
                        faceIDEnabled: appState.settings.faceIDEnabled,
                        onUnlock: { withAnimation(.easeInOut(duration: 0.18)) { isLocked = false } }
                    )
                    .transition(.opacity)
                }
            }

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.currentScreen)
        .animation(.easeInOut(duration: 0.18), value: isLocked)
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .environment(\.locale, Locale(identifier: localeIdentifier(appState.settings.language)))
        .environment(\.layoutDirection, appState.settings.language.hasPrefix("ar") ? .rightToLeft : .leftToRight)
        .preferredColorScheme(appState.settings.theme.preferredColorScheme)
        .environmentObject(appState)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                lastBackgroundDate = Date()
                // Превентивно ставим lock сразу — фактическая проверка
                // произойдёт при возврате в .active с учётом auto-lock.
                if lockEnabled, appState.currentScreen == .main {
                    isLocked = true
                }
            case .active:
                if lockEnabled, appState.currentScreen == .main {
                    if shouldUnlockWithoutAuth() {
                        isLocked = false
                    }
                }
            default: break
            }
        }
        .onAppear {
            startSplash()
            if lockEnabled && appState.currentScreen == .main {
                isLocked = true
            }
        }
    }

    /// Срабатывает auto-lock только если прошло больше appAutoLockSec секунд
    /// с момента ухода в background. -1 = «никогда», т.е. лочить только при
    /// перезапуске приложения. 0 = всегда (моментально).
    private func shouldUnlockWithoutAuth() -> Bool {
        let interval = appState.settings.appAutoLockSec
        guard interval > 0 else { return false }       // 0 или -1 → никогда не «отпускать»
        guard let last = lastBackgroundDate else { return false }
        return Date().timeIntervalSince(last) < TimeInterval(interval)
    }

    private func startSplash() {
        splashDismissWorkItem?.cancel()
        showSplash = true

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.35)) {
                showSplash = false
            }
        }
        splashDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }

    /// Конвертирует внутренний language code в корректный iOS Locale identifier
    private func localeIdentifier(_ language: String) -> String {
        let map: [String: String] = [
            "en_US": "en-US", "ru_RU": "ru-RU", "es_ES": "es-ES",
            "fr_FR": "fr-FR", "de_DE": "de-DE", "it_IT": "it-IT",
            "pt_BR": "pt-BR", "ja_JP": "ja-JP", "ko_KR": "ko-KR",
            "zh_CN": "zh-Hans-CN", "ar_SA": "ar-SA", "hi_IN": "hi-IN",
            "tr_TR": "tr-TR", "uk_UA": "uk-UA", "pl_PL": "pl-PL"
        ]
        return map[language] ?? language
    }
}

// MARK: - Splash

private struct SplashScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.84
    @State private var logoOpacity = 0.0

    var body: some View {
        ZStack {
            (colorScheme == .dark
             ? Color(red: 0.08, green: 0.08, blue: 0.09)
             : Color(red: 0.95, green: 0.96, blue: 0.98))
                .ignoresSafeArea()

            Image("Logo_Main")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .colorMultiply(colorScheme == .dark ? .white : Color(red: 0.10, green: 0.10, blue: 0.12))
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
                logoScale = 1
                logoOpacity = 1
            }
        }
    }
}

// MARK: - App Lock (Face ID + Passcode)
//
// Telegram-style: при включённом Face ID сразу запускаем биометрию. Если
// пользователь её отменил/она не сработала — показываем 4-значный pin-pad.
// Под pin'ом — «Не помню код-пароль» → подсказывает обратиться в поддержку.

private struct AppLockView: View {
    let passcodeEnabled: Bool
    let faceIDEnabled: Bool
    let onUnlock: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showPasscode = false
    @State private var pin: String = ""
    @State private var attempts: Int = 0
    @State private var shake: Bool = false
    @State private var showForgotAlert = false
    @FocusState private var pinFocused: Bool

    private var isDark: Bool { colorScheme == .dark }
    private var fg: Color { isDark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14) }

    private var darkStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.06, green: 0.06, blue: 0.07), location: 0.00),
            .init(color: Color(red: 0.13, green: 0.13, blue: 0.14), location: 0.55),
            .init(color: Color(red: 0.08, green: 0.08, blue: 0.09), location: 1.00)
        ]
    }
    private var lightStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.88, green: 0.88, blue: 0.90), location: 0.00),
            .init(color: Color(red: 0.93, green: 0.93, blue: 0.95), location: 0.55),
            .init(color: Color(red: 0.86, green: 0.86, blue: 0.88), location: 1.00)
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(stops: isDark ? darkStops : lightStops,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if showPasscode {
                passcodeView
            } else {
                faceIDView
            }
        }
        .onAppear {
            if faceIDEnabled {
                runBiometrics()
            } else if passcodeEnabled {
                showPasscode = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pinFocused = true }
            } else {
                // Lock включился, но ни одна защита не активна — отпускаем.
                onUnlock()
            }
        }
        .alert("Забыли код-пароль?", isPresented: $showForgotAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Если вы забыли код-пароль, обратитесь в поддержку через email support@nexus.app или Telegram-чат поддержки. Восстановить код невозможно — потребуется переустановка приложения.")
        }
    }

    // MARK: Face ID UI

    private var faceIDView: some View {
        VStack(spacing: 22) {
            Image(systemName: "faceid")
                .font(.system(size: 58, weight: .regular))
                .foregroundStyle(fg.opacity(isDark ? 0.85 : 0.70))
            VStack(spacing: 6) {
                Text("Nexus заблокирован")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(fg)
                Text("Используйте Face ID для разблокировки")
                    .font(.system(size: 14))
                    .foregroundStyle(fg.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            Button(action: runBiometrics) {
                Text("Разблокировать")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(fg)
                    .padding(.horizontal, 32).padding(.vertical, 12)
                    .background(
                        (isDark ? Color.white : Color.black).opacity(isDark ? 0.10 : 0.06),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(fg.opacity(isDark ? 0.18 : 0.12), lineWidth: 0.7))
            }
            .buttonStyle(.plain)

            if passcodeEnabled {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showPasscode = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pinFocused = true }
                } label: {
                    Text("Ввести код-пароль")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(fg.opacity(0.65))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    // MARK: Passcode UI

    private var passcodeView: some View {
        VStack(spacing: 26) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(fg.opacity(isDark ? 0.85 : 0.70))

            Text("Введите код-пароль")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(fg)

            // 4 точки-индикатор
            HStack(spacing: 18) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count
                              ? Color(red: 0.0, green: 0.48, blue: 1.0)
                              : fg.opacity(0.12))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(fg.opacity(0.18), lineWidth: 0.5))
                }
            }
            .offset(x: shake ? -8 : 0)
            .animation(.default, value: shake)

            // Скрытое цифровое поле
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($pinFocused)
                .opacity(0.001)
                .frame(height: 1)
                .onChange(of: pin) { _, new in
                    let f = String(new.prefix(4).filter { $0.isNumber })
                    if f != new { pin = f; return }
                    if f.count == 4 { verify(f) }
                }

            VStack(spacing: 10) {
                if faceIDEnabled {
                    Button(action: runBiometrics) {
                        HStack(spacing: 6) {
                            Image(systemName: "faceid").font(.system(size: 14))
                            Text("Использовать Face ID")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(fg.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                }
                Button { showForgotAlert = true } label: {
                    Text("Не помню код-пароль")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(red: 0.0, green: 0.55, blue: 1.0).opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 32)
    }

    // MARK: Actions

    private func runBiometrics() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if passcodeEnabled {
                withAnimation(.easeInOut(duration: 0.2)) { showPasscode = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pinFocused = true }
            } else {
                onUnlock()
            }
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Разблокировать Nexus") { ok, _ in
            DispatchQueue.main.async {
                if ok {
                    onUnlock()
                } else if passcodeEnabled {
                    withAnimation(.easeInOut(duration: 0.2)) { showPasscode = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pinFocused = true }
                }
                // Если passcode выключен и Face ID не сработал — остаёмся на
                // том же экране, пользователь может ткнуть «Разблокировать».
            }
        }
    }

    private func verify(_ code: String) {
        if AppPasscodeStore.verify(code) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onUnlock()
        } else {
            attempts += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shake.toggle() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.default) { shake.toggle() }
                pin = ""
            }
        }
    }
}
