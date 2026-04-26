import SwiftUI
import UIKit

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    /// Индекс активного таба (0 = Health … 4 = Settings).
    @State private var selectedTab: Int = 0

    /// Инкрементируется каждый раз, когда пользователь тапает уже
    /// активный таб «Настройки» — сигнал для ScrollToTop в SettingsView.
    @State private var settingsScrollTrigger: Int = 0

    /// Кастомный Binding для TabView: кроме стандартной смены таба,
    /// перехватывает ретап того же таба (сеттер вызывается даже при
    /// newValue == oldValue) и генерирует scroll-to-top сигнал.
    private var tabBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab, newValue == 4 {
                    // повторный тап на Settings → прокрутить вверх
                    settingsScrollTrigger &+= 1
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        // appState.settings.language меняется → body пересчитывается → L() возвращает новый язык
        let lang = appState.settings.language

        TabView(selection: tabBinding) {
            HealthView()
                .tag(0)
                .tabItem {
                    Label(L("tab.health"), systemImage: "heart.fill")
                }
            FinanceView()
                .tag(1)
                .tabItem {
                    Label(L("tab.finance"), systemImage: "chart.line.uptrend.xyaxis")
                }
            LearningView()
                .tag(2)
                .tabItem {
                    Label(L("tab.learning"), systemImage: "brain.head.profile")
                }
            AIAssistantView()
                .tag(3)
                .tabItem {
                    Label(L("tab.ai"), systemImage: "sparkles")
                }
            SettingsView(scrollToTopTrigger: settingsScrollTrigger)
                .tag(4)
                .tabItem {
                    Label(L("tab.settings"), systemImage: "gearshape.fill")
                }
        }
        .tabViewStyle(.automatic)
        .background(Color.clear)
        .toolbarBackground(tabBarSurfaceColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.dynamicTypeSize, .small)
        .onAppear { configureTabBarAppearance(for: colorScheme) }
        .onChange(of: colorScheme) { _, new in configureTabBarAppearance(for: new) }
        .onChange(of: lang) { _, _ in configureTabBarAppearance(for: colorScheme) }
    }

    private var tabBarSurfaceColor: Color {
        colorScheme == .dark ? AppColors.background : AppColors.lightBackground
    }

    private func configureTabBarAppearance(for colorScheme: ColorScheme) {
        let bg = colorScheme == .dark ? AppColors.background : AppColors.lightBackground
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = UIColor(bg)
        let normal = appearance.stackedLayoutAppearance.normal
        let selected = appearance.stackedLayoutAppearance.selected
        let titleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        let muted = colorScheme == .dark
            ? UIColor.white.withAlphaComponent(0.55)
            : UIColor.black.withAlphaComponent(0.45)
        let accent = colorScheme == .dark ? UIColor.white : UIColor.systemBlue
        normal.titleTextAttributes = [.font: titleFont, .foregroundColor: muted]
        selected.titleTextAttributes = [.font: titleFont, .foregroundColor: accent]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = muted
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
}
