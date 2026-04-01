import SwiftUI
import CoreGraphics

struct AnimatedDarkBackground: View {
    var body: some View {
        TimelineView(.animation) { _ in
            AppColors.background
                .ignoresSafeArea()
        }
    }
}

/// Matches `AppState.settings.theme` and system appearance for `.system`.
struct AdaptiveRootBackground: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        rootColor.ignoresSafeArea()
    }

    private var rootColor: Color {
        switch appState.settings.theme {
        case .light:
            return AppColors.lightBackground
        case .dark:
            return AppColors.background
        case .system:
            return colorScheme == .dark ? AppColors.background : AppColors.lightBackground
        }
    }
}
