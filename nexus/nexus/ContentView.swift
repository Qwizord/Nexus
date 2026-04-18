import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLocked = false
    @State private var blurRadius: CGFloat = 0
    @State private var showSplash = true
    @State private var splashDismissWorkItem: DispatchWorkItem?

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

                if isLocked {
                    FaceIDLockView { authenticate() }
                        .transition(.opacity)
                }
            }
            .blur(radius: blurRadius)

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.currentScreen)
        .animation(.easeInOut(duration: 0.25), value: isLocked)
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .environment(\.locale, Locale(identifier: localeIdentifier(appState.settings.language)))
        .environment(\.layoutDirection, appState.settings.language.hasPrefix("ar") ? .rightToLeft : .leftToRight)
        .preferredColorScheme(appState.settings.theme.preferredColorScheme)
        .environmentObject(appState)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if appState.settings.faceIDEnabled, appState.currentScreen == .main {
                    isLocked = true
                    blurRadius = 20
                }
            case .active:
                if appState.settings.faceIDEnabled, appState.currentScreen == .main, isLocked {
                    authenticate()
                }
            default: break
            }
        }
        .onAppear {
            startSplash()
            if appState.settings.faceIDEnabled && appState.currentScreen == .main {
                isLocked = true
                blurRadius = 20
            }
        }
    }

    private func startSplash() {
        splashDismissWorkItem?.cancel()
        showSplash = true

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.35)) {
                showSplash = false
            }
            if appState.settings.faceIDEnabled, appState.currentScreen == .main, isLocked {
                authenticate()
            }
        }
        splashDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }

    /// Конвертирует внутренний language code в корректный iOS Locale identifier
    private func localeIdentifier(_ language: String) -> String {
        // AppLanguage использует en_US, ru_RU итд — это и есть нужные Locale identifiers
        // Но iOS ожидает BCP 47 формат для некоторых кейсов
        let map: [String: String] = [
            "en_US": "en-US", "ru_RU": "ru-RU", "es_ES": "es-ES",
            "fr_FR": "fr-FR", "de_DE": "de-DE", "it_IT": "it-IT",
            "pt_BR": "pt-BR", "ja_JP": "ja-JP", "ko_KR": "ko-KR",
            "zh_CN": "zh-Hans-CN", "ar_SA": "ar-SA", "hi_IN": "hi-IN",
            "tr_TR": "tr-TR", "uk_UA": "uk-UA", "pl_PL": "pl-PL"
        ]
        return map[language] ?? language
    }

    private func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isLocked = false
            blurRadius = 0
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Разблокировать Nexus") { ok, _ in
            DispatchQueue.main.async {
                if ok {
                    withAnimation { isLocked = false; blurRadius = 0 }
                }
            }
        }
    }
}

// MARK: - Face ID Lock Screen

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

private struct FaceIDLockView: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "faceid")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.7))
                Text(L("faceid.locked"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text(L("faceid.use"))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                Button(action: onUnlock) {
                    Text(L("faceid.unlock"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }
}
