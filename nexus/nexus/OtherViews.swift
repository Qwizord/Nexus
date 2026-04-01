import SwiftUI
import Combine
import PhotosUI
import UIKit

// MARK: - Finance View

struct FinanceView: View {
    @State private var transactions: [MockTransaction] = MockTransaction.samples
    @State private var showAdd = false
    @State private var selectedPeriod = 0

    var totalIncome: Double { transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var totalExpense: Double { transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var balance: Double { totalIncome - totalExpense }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Финансы")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Март 2026")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
                    }
                }

                // Balance card
                GlassSection {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Баланс")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(balance.formatted(.currency(code: "RUB").presentation(.narrow)))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(balance >= 0 ? .white : .red)
                        }

                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.system(size: 14))
                                    Text("Доходы")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Text(totalIncome.formatted(.currency(code: "RUB").presentation(.narrow)))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle().fill(.white.opacity(0.1)).frame(width: 0.5, height: 30)

                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 14))
                                    Text("Расходы")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Text(totalExpense.formatted(.currency(code: "RUB").presentation(.narrow)))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                // Expense breakdown
                GlassSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("По категориям")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        ForEach(categoryBreakdown, id: \.0) { cat, amount in
                            let pct = totalExpense > 0 ? amount / totalExpense : 0
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 20)
                                Text(cat.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                Spacer()
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.08)).frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.9)], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * pct, height: 4)
                                    }
                                }
                                .frame(width: 80, height: 4)
                                Text(amount.formatted(.currency(code: "RUB").presentation(.narrow)))
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }

                // Transactions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Последние операции")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.leading, 2)

                    ForEach(transactions.prefix(8)) { tx in
                        TransactionRow(tx: tx)
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
    }

    var categoryBreakdown: [(FinanceCategory, Double)] {
        var dict: [FinanceCategory: Double] = [:]
        for tx in transactions where tx.type == .expense {
            dict[tx.category, default: 0] += tx.amount
        }
        return dict.sorted { $0.value > $1.value }
    }
}

struct MockTransaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let type: TransactionType
    let category: FinanceCategory
    let date: Date

    static var samples: [MockTransaction] = [
        .init(title: "Зарплата", amount: 120000, type: .income, category: .salary, date: Date()),
        .init(title: "Фриланс", amount: 35000, type: .income, category: .freelance, date: Date()),
        .init(title: "Продукты", amount: 4200, type: .expense, category: .food, date: Date()),
        .init(title: "Такси", amount: 850, type: .expense, category: .transport, date: Date()),
        .init(title: "Курс Swift", amount: 5990, type: .expense, category: .education, date: Date()),
        .init(title: "Ресторан", amount: 2400, type: .expense, category: .food, date: Date()),
        .init(title: "Одежда", amount: 6800, type: .expense, category: .shopping, date: Date()),
        .init(title: "Аптека", amount: 1200, type: .expense, category: .health, date: Date()),
    ]
}

struct TransactionRow: View {
    let tx: MockTransaction
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tx.type == .income ? Color.green.opacity(0.15) : Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: tx.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(tx.type == .income ? .green : .white.opacity(0.6))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title).font(.system(size: 15)).foregroundStyle(.white)
                Text(tx.category.rawValue).font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Text((tx.type == .income ? "+" : "-") + tx.amount.formatted(.currency(code: "RUB").presentation(.narrow)))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tx.type == .income ? .green : .white)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
        .edgeSheen(cornerRadius: 14)
    }
}

// MARK: - Learning View

struct LearningView: View {
    @State private var courses = CourseSample.samples
    @State private var dailyGoalMinutes = 45
    @State private var todayMinutes = 28

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Обучение")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Продолжай расти")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                }

                // Today goal
                GlassSection {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сегодня")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(todayMinutes)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("/ \(dailyGoalMinutes) мин")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.1)).frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(LinearGradient(colors: [Color(red: 0.5, green: 0.3, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 1.0)], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * min(Double(todayMinutes) / Double(dailyGoalMinutes), 1.0), height: 5)
                                }
                            }.frame(height: 5)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .trim(from: 0, to: min(Double(todayMinutes) / Double(dailyGoalMinutes), 1.0))
                                .stroke(LinearGradient(colors: [Color(red: 0.5, green: 0.3, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 1.0)], startPoint: .leading, endPoint: .trailing), lineWidth: 5)
                                .rotationEffect(.degrees(-90))
                                .frame(width: 60, height: 60)
                            Circle().stroke(.white.opacity(0.1), lineWidth: 5).frame(width: 60, height: 60)
                            Text("\(Int(Double(todayMinutes) / Double(dailyGoalMinutes) * 100))%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                // Courses
                VStack(alignment: .leading, spacing: 10) {
                    Text("Курсы")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.leading, 2)

                    ForEach($courses) { $course in
                        CourseCard(course: $course)
                    }
                }

                // Weekly activity
                GlassSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Активность за неделю")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        HStack(spacing: 6) {
                            ForEach(Array(zip(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], [35,45,20,50,45,28,0])), id: \.0) { day, mins in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(mins > 0
                                            ? LinearGradient(colors: [Color(red: 0.5, green: 0.3, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .frame(maxWidth: .infinity)
                                        .frame(height: max(6, CGFloat(mins) / 50.0 * 60))
                                    Text(day)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }
                        }
                        .frame(height: 80)
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
    }
}

struct CourseCard: View {
    @Binding var course: CourseSample
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(course.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: course.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(course.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Text(course.category)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.2))
                    Text("\(Int(course.progress * 100))%")
                        .font(.system(size: 12))
                        .foregroundStyle(course.color.opacity(0.8))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.08)).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2).fill(course.color.opacity(0.7)).frame(width: geo.size.width * course.progress, height: 3)
                    }
                }.frame(height: 3)
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3)) {
                    course.progress = min(course.progress + 0.05, 1.0)
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(course.color.opacity(0.3), in: Circle())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
    }
}

struct CourseSample: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let icon: String
    let color: Color
    var progress: Double

    static var samples: [CourseSample] = [
        .init(title: "iOS разработка", category: "Программирование", icon: "iphone", color: Color(red: 0.3, green: 0.5, blue: 1.0), progress: 0.65),
        .init(title: "IELTS Academic", category: "Английский", icon: "globe", color: Color(red: 0.3, green: 0.8, blue: 0.5), progress: 0.30),
        .init(title: "CS Fundamentals", category: "Computer Science", icon: "cpu", color: Color(red: 0.8, green: 0.4, blue: 1.0), progress: 0.15),
        .init(title: "Биохакинг", category: "Здоровье", icon: "brain.head.profile", color: Color(red: 1.0, green: 0.5, blue: 0.3), progress: 0.45),
    ]
}


// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var notificationsOn = true
    @State private var healthKitOn = false
    @State private var selectedTheme = AppTheme.system
    @State private var showSignOutAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var user: UserProfile? { appState.userProfile }
    var userContact: String {
        if let email = user?.email, !email.isEmpty { return email }
        if let phone = user?.phone, !phone.isEmpty { return phone }
        return "user@nexus.app"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Header
                Text("Настройки")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Profile card
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    GlassSection {
                        HStack(spacing: 14) {
                            ZStack {
                                if let data = user?.avatarData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 60, height: 60)
                                    Text(user?.initials ?? "AN")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user?.fullName ?? "Anton Nexus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(userContact)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.4))
                                HStack(spacing: 8) {
                                    if let u = user {
                                        StatPill(label: "\(u.age) лет")
                                        StatPill(label: "\(Int(u.weightKg)) кг")
                                        StatPill(label: "\(Int(u.heightCm)) см")
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                    }
                }
                .buttonStyle(.plain)

                // Stats
                GlassSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Статистика")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatCard(label: "Дней в приложении", value: "14")
                            StatCard(label: "Сообщений AI", value: "47")
                            StatCard(label: "Записей о здоровье", value: "28")
                            StatCard(label: "Транзакций", value: "32")
                        }
                    }
                }

                // Integrations
                SettingsGroup(title: "Интеграции") {
                    SettingsToggle(icon: "heart.fill", iconColor: .pink, title: "Apple Health", isOn: $healthKitOn)
                    SettingsDivider()
                    SettingsRow(icon: "circle.hexagongrid.fill", iconColor: Color(red: 0.5, green: 0.4, blue: 1.0), title: "Oura Ring", value: "Скоро")
                    SettingsDivider()
                    SettingsRow(icon: "waveform.path.ecg", iconColor: .green, title: "Garmin", value: "Скоро")
                    SettingsDivider()
                    SettingsRow(icon: "bolt.heart.fill", iconColor: .red, title: "Whoop", value: "Скоро")
                }

                // Preferences
                SettingsGroup(title: "Оформление") {
                    SettingsToggle(icon: "bell.fill", iconColor: .blue, title: "Уведомления", isOn: $notificationsOn)
                    SettingsDivider()
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Text("Тема")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                        Spacer()
                        Picker("", selection: $selectedTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                // Account
                SettingsGroup(title: "Аккаунт") {
                    SettingsRow(icon: "envelope.fill", iconColor: .cyan, title: "Email", value: user?.email ?? "—")
                    SettingsDivider()
                    SettingsRow(icon: "star.fill", iconColor: .yellow, title: "Поддержать проект", value: "")
                }

                Button {
                    showSignOutAlert = true
                } label: {
                    Text("Выйти")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.red.opacity(0.35), lineWidth: 0.6))
                }
                .frame(maxWidth: 180)
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .buttonStyle(.plain)

                Spacer(minLength: 50)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .alert("Выйти из аккаунта?", isPresented: $showSignOutAlert) {
            Button("Выйти", role: .destructive) { appState.signOut() }
            Button("Отмена", role: .cancel) {}
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    appState.updateAvatar(data)
                }
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: () -> Content
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.5)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
            .edgeSheen(cornerRadius: 20)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(.white.opacity(0.06))
            .padding(.leading, 62)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .edgeSheen(cornerRadius: 12)
    }
}

struct StatPill: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.white.opacity(0.08), in: Capsule())
    }
}
