import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SubscriptionManager.shared
    @State private var selectedProductID: String = SubscriptionManager.semiAnnualID
    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.1),
                    Color(red: 0.1, green: 0.05, blue: 0.18)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Close
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue, .cyan],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                        Text("Nexus Pro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Раскройте весь потенциал приложения")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "brain.head.profile", color: .purple, text: "Безлимитный AI-ассистент")
                        FeatureRow(icon: "waveform.path.ecg", color: .pink, text: "Загрузка анализов и сканирование")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", color: .green, text: "Расширенная финансовая аналитика")
                        FeatureRow(icon: "globe", color: .blue, text: "Синхронизация на всех устройствах")
                        FeatureRow(icon: "bell.badge", color: .orange, text: "Умные персональные уведомления")
                        FeatureRow(icon: "lock.open", color: .cyan, text: "Все функции без ограничений")
                    }
                    .padding(.horizontal, 24)

                    // Plans
                    VStack(spacing: 10) {
                        if let monthly = store.monthlyProduct {
                            PlanCard(
                                product: monthly,
                                title: "Ежемесячно",
                                subtitle: pricePerMonth(monthly),
                                badge: nil,
                                isSelected: selectedProductID == monthly.id
                            ) { selectedProductID = monthly.id }
                        }

                        if let semi = store.semiAnnualProduct {
                            PlanCard(
                                product: semi,
                                title: "Полгода",
                                subtitle: pricePerMonth(semi) + " / мес",
                                badge: "Популярный",
                                isSelected: selectedProductID == semi.id
                            ) { selectedProductID = semi.id }
                        }

                        if let lifetime = store.lifetimeProduct {
                            PlanCard(
                                product: lifetime,
                                title: "Навсегда",
                                subtitle: "Одноразовый платёж",
                                badge: "Лучшая цена",
                                isSelected: selectedProductID == lifetime.id
                            ) { selectedProductID = lifetime.id }
                        }

                        // Fallback: если продукты не загрузились
                        if store.products.isEmpty && !store.isLoading {
                            VStack(spacing: 8) {
                                Text("Не удалось загрузить планы")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.4))
                                Button("Повторить") { Task { await store.loadProducts() } }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Purchase button
                    Button {
                        Task { await purchaseSelected() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Продолжить")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.2, blue: 1.0), Color(red: 0.6, green: 0.1, blue: 0.9)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || store.products.isEmpty)
                    .padding(.horizontal, 20)

                    // Restore + Legal
                    VStack(spacing: 8) {
                        Button("Восстановить покупки") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))

                        HStack(spacing: 16) {
                            Link("Условия", destination: URL(string: "https://nexus-app.com/terms")!)
                            Link("Конфиденциальность", destination: URL(string: "https://nexus-app.com/privacy")!)
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func purchaseSelected() async {
        guard let product = store.product(for: selectedProductID) else { return }
        isPurchasing = true
        let success = await store.purchase(product)
        isPurchasing = false
        if success { dismiss() }
    }

    private func pricePerMonth(_ product: Product) -> String {
        product.displayPrice
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let title: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? .white.opacity(0.1) : .white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
