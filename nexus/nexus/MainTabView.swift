import SwiftUI
import UIKit

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // appState.settings.language меняется → body пересчитывается → L() возвращает новый язык
        let lang = appState.settings.language

        TabView {
            HealthView()
                .tabItem {
                    Label(L("tab.health"), systemImage: "heart.fill")
                }
            FinanceView()
                .tabItem {
                    Label(L("tab.finance"), systemImage: "chart.line.uptrend.xyaxis")
                }
            LearningView()
                .tabItem {
                    Label(L("tab.learning"), systemImage: "brain.head.profile")
                }
            AIAssistantView()
                .tabItem {
                    Label(L("tab.ai"), systemImage: "sparkles")
                }
            SettingsView()
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
