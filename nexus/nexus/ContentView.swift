import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
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
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.currentScreen)
        .environment(\.locale, Locale(identifier: appState.settings.language))
        .environment(\.layoutDirection, appState.settings.language.hasPrefix("ar") ? .rightToLeft : .leftToRight)
        .preferredColorScheme(appState.settings.theme.preferredColorScheme)
        .environmentObject(appState)
    }
}
