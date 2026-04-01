import SwiftUI
import UIKit

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            HealthView()
                .tabItem {
                    VStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Здоровье")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            FinanceView()
                .tabItem {
                    VStack(spacing: 3) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Финансы")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            LearningView()
                .tabItem {
                    VStack(spacing: 3) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Обучение")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            AIAssistantView()
                .tabItem {
                    VStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                        Text("AI")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            SettingsView()
                .tabItem {
                    VStack(spacing: 3) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Настройки")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
        }
        .tabViewStyle(.automatic)
        .background(Color.clear)
        .toolbarBackground(tabBarSurfaceColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.dynamicTypeSize, .small)
        .onAppear { configureTabBarAppearance(for: colorScheme) }
        .onChange(of: colorScheme) { _, new in configureTabBarAppearance(for: new) }
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
