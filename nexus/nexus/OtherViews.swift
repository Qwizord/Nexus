import SwiftUI
import Combine

// MARK: - Network Error View

struct NetworkErrorView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Нет подключения")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text("Проверьте интернет и попробуйте снова")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text("Повторить")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0), in: Capsule())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Skeleton Loading

struct SkeletonBlock: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isLoading = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white.opacity(0.08))
            .frame(width: width, height: height)
            .shimmer(isActive: isLoading)
            .onAppear { isLoading = true }
    }
}

struct SkeletonCard: View {
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonBlock(width: 120, height: 14, cornerRadius: 6)
            HStack {
                SkeletonBlock(width: 80, height: 20, cornerRadius: 8)
                Spacer()
            }
            SkeletonBlock(width: 140, height: 12, cornerRadius: 4)
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .shimmer(isActive: isLoading)
        .onAppear { isLoading = true }
    }
}

struct SkeletonTransactionRow: View {
    @State private var isLoading = false

    var body: some View {
        HStack(spacing: 12) {
            SkeletonBlock(width: 40, height: 40, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(width: 100, height: 12, cornerRadius: 4)
                SkeletonBlock(width: 140, height: 10, cornerRadius: 4)
            }
            Spacer()
            SkeletonBlock(width: 60, height: 14, cornerRadius: 6)
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .shimmer(isActive: isLoading)
        .onAppear { isLoading = true }
    }
}

// MARK: - Shimmer Extension

extension View {
    func shimmer(isActive: Bool) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var startPoint: UnitPoint = .init(x: -1, y: 0.5)
    @State private var endPoint: UnitPoint = .init(x: 0, y: 0.5)

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.1), location: 0.5),
                        .init(color: .white.opacity(0), location: 1),
                    ]),
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    startAnimation()
                }
            }
    }

    private func startAnimation() {
        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            startPoint = .init(x: 1, y: 0.5)
            endPoint = .init(x: 2, y: 0.5)
        }
    }
}

