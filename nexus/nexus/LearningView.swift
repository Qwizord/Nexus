import SwiftUI
import Combine

// MARK: - Data Models

struct NewsItem: Identifiable {
    let id: String
    let title: String
    let preview: String
    let source: String
    let topic: String
    let date: Date
    let url: URL?
    var isSaved: Bool

    static let samples: [NewsItem] = [
        .init(id: "1", title: "Apple выпускает iOS 18.4 с новыми функциями AI", preview: "Обновление включает улучшенный Siri и интеграцию с ChatGPT напрямую из системы.", source: "TechCrunch", topic: "tech", date: Date(), url: nil, isSaved: false),
        .init(id: "2", title: "Исследование: сон улучшает долгосрочную память на 40%", preview: "Учёные Гарварда доказали, что 8 часов сна критически важны для консолидации воспоминаний.", source: "Nature", topic: "health", date: Date(), url: nil, isSaved: false),
        .init(id: "3", title: "Bitcoin достиг $95,000 на фоне роста ETF", preview: "Приток средств в биткоин-ETF превысил $2 млрд за неделю, подтолкнув цену к новым максимумам.", source: "CoinDesk", topic: "finance", date: Date(), url: nil, isSaved: false),
        .init(id: "4", title: "ИИ-модель решила задачу синтеза белков", preview: "DeepMind представила AlphaFold 3 с возможностью предсказывать структуры ДНК и РНК.", source: "Science", topic: "science", date: Date(), url: nil, isSaved: false),
        .init(id: "5", title: "Рынок онлайн-образования вырос до $400 млрд", preview: "Coursera и edX сообщают о рекордном числе пользователей в 2026 году.", source: "Forbes", topic: "education", date: Date(), url: nil, isSaved: false),
        .init(id: "6", title: "OpenAI запускает GPT-5 с мультимодальностью", preview: "Новая модель понимает видео, аудио и 3D-объекты в реальном времени.", source: "The Verge", topic: "tech", date: Date(), url: nil, isSaved: false),
    ]
}

struct NewsTopic: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    var isSelected: Bool
    var isCustom: Bool

    static let defaults: [NewsTopic] = [
        .init(id: "tech", name: "Технологии", emoji: "💻", isSelected: true, isCustom: false),
        .init(id: "health", name: "Здоровье", emoji: "❤️", isSelected: true, isCustom: false),
        .init(id: "finance", name: "Финансы", emoji: "💰", isSelected: false, isCustom: false),
        .init(id: "science", name: "Наука", emoji: "🔬", isSelected: false, isCustom: false),
        .init(id: "education", name: "Образование", emoji: "📚", isSelected: false, isCustom: false),
        .init(id: "ai", name: "ИИ", emoji: "🤖", isSelected: true, isCustom: false),
        .init(id: "space", name: "Космос", emoji: "🚀", isSelected: false, isCustom: false),
        .init(id: "crypto", name: "Крипто", emoji: "🪙", isSelected: false, isCustom: false),
    ]
}

struct TaskGroup: Identifiable {
    let id: String
    var name: String
    var tasks: [LearningTask]

    static let samples: [TaskGroup] = [
        .init(id: "1", name: "iOS Разработка", tasks: [
            .init(id: "t1", title: "Изучить SwiftUI анимации", dueDate: Date(), startTime: Date(), endTime: Date().addingTimeInterval(3600), isCompleted: false, recurring: .once, priority: .high),
            .init(id: "t2", title: "Прочитать главу по Combine", dueDate: Date(), startTime: Date().addingTimeInterval(3600), endTime: Date().addingTimeInterval(7200), isCompleted: true, recurring: .once, priority: .medium),
        ]),
        .init(id: "2", name: "Английский", tasks: [
            .init(id: "t3", title: "Словарный запас — 20 слов", dueDate: Date(), startTime: Date(), endTime: Date().addingTimeInterval(1800), isCompleted: false, recurring: .daily, priority: .medium),
        ]),
    ]
}

struct LearningTask: Identifiable {
    let id: String
    var title: String
    var dueDate: Date
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool
    var recurring: RecurrenceType
    var priority: TaskPriority
}

enum RecurrenceType: String, CaseIterable {
    case once = "Однократно"
    case daily = "Ежедневно"
    case weekly = "Еженедельно"
    case monthly = "Ежемесячно"
}

enum TaskPriority: String, CaseIterable {
    case high = "Высокий"
    case medium = "Средний"
    case low = "Низкий"

    var color: Color {
        switch self {
        case .high:   return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .medium: return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .low:    return Color(red: 0.35, green: 0.85, blue: 0.5)
        }
    }
}

struct KnowledgeTopic: Identifiable {
    let id: String
    var name: String
    var emoji: String
    var notes: [KnowledgeNote]

    static let samples: [KnowledgeTopic] = [
        .init(id: "1", name: "iOS разработка", emoji: "📱", notes: [
            .init(id: "n1", title: "SwiftUI Basics", content: "# SwiftUI Basics\n\nSwiftUI — декларативный фреймворк для построения UI.\n\n## Ключевые концепции\n- View Protocol\n- State Management\n- [[Combine Integration]]\n\n## Модификаторы\nКаждый view имеет цепочку модификаторов.", topicId: "1", tags: ["swift", "ui"], linkedNoteIds: ["n2"], createdAt: Date(), updatedAt: Date()),
            .init(id: "n2", title: "Combine Integration", content: "# Combine\n\nФреймворк для реактивного программирования.\n\n## Publishers & Subscribers\n- `@Published` — объявляет publisher\n- `sink` — подписывается на события\n\nСвязано с: [[SwiftUI Basics]]", topicId: "1", tags: ["combine", "reactive"], linkedNoteIds: ["n1"], createdAt: Date(), updatedAt: Date()),
        ]),
        .init(id: "2", name: "Математика", emoji: "📐", notes: [
            .init(id: "n3", title: "Линейная алгебра", content: "# Линейная алгебра\n\n## Матрицы\nМатрица — прямоугольный массив чисел.\n\n### Умножение матриц\nA × B возможно когда столбцы A = строкам B.", topicId: "2", tags: ["math", "algebra"], linkedNoteIds: [], createdAt: Date(), updatedAt: Date()),
        ]),
        .init(id: "3", name: "Крипто", emoji: "🪙", notes: []),
    ]
}

struct KnowledgeNote: Identifiable {
    let id: String
    var title: String
    var content: String
    let topicId: String
    var tags: [String]
    var linkedNoteIds: [String]
    let createdAt: Date
    var updatedAt: Date
}

// MARK: - LearningView (Main)

struct LearningView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var vm = LearningViewModel()
    @State private var selectedTab: LearningTab = .news

    enum LearningTab: String, CaseIterable {
        case news = "Новости"
        case tasks = "Задачи"
        case knowledge = "База знаний"

        var icon: String {
            switch self {
            case .news: return "newspaper.fill"
            case .tasks: return "checklist"
            case .knowledge: return "brain.filled.head.profile"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Обучение")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(selectedTab.rawValue)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .opacity(0.6)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, verticalSizeClass == .compact ? 25 : 25)
            .padding(.bottom, 12)

            // Tab Selector
            learningTabPicker
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Content
            TabView(selection: $selectedTab) {
                NewsSection(vm: vm)
                    .tag(LearningTab.news)
                TasksSection(vm: vm)
                    .tag(LearningTab.tasks)
                KnowledgeSection(vm: vm)
                    .tag(LearningTab.knowledge)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
        }
    }

    private var learningTabPicker: some View {
        HStack(spacing: 8) {
            ForEach(LearningTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        : AnyShapeStyle(Color.primary.opacity(0.08)),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

// MARK: - News Section

struct NewsSection: View {
    @ObservedObject var vm: LearningViewModel
    @State private var showTopicsSheet = false
    @State private var showAllNews = false

    var filteredNews: [NewsItem] {
        let selectedTopicIds = vm.topics.filter { $0.isSelected }.map { $0.id }
        if selectedTopicIds.isEmpty { return vm.newsItems }
        return vm.newsItems.filter { selectedTopicIds.contains($0.topic) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Topics row
                topicsRow

                // News list
                if filteredNews.isEmpty {
                    emptyNewsPlaceholder
                } else {
                    VStack(spacing: 10) {
                        ForEach(filteredNews.prefix(showAllNews ? 99 : 4)) { item in
                            NewsCard(item: item) {
                                vm.toggleSaved(newsId: item.id)
                            }
                        }
                    }
                }

                // Show all button
                if filteredNews.count > 4 {
                    Button {
                        withAnimation { showAllNews.toggle() }
                    } label: {
                        Text(showAllNews ? "Свернуть" : "Смотреть все новости (\(filteredNews.count))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showTopicsSheet) {
            TopicsSheet(topics: $vm.topics)
        }
    }

    private var topicsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Темы")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    showTopicsSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Все")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach($vm.topics) { $topic in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                topic.isSelected.toggle()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(topic.emoji)
                                    .font(.system(size: 13))
                                Text(topic.name)
                                    .font(.system(size: 13, weight: topic.isSelected ? .semibold : .regular))
                            }
                            .foregroundStyle(topic.isSelected ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                topic.isSelected
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                : AnyShapeStyle(Color.primary.opacity(0.08)),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
    }

    private var emptyNewsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("Выбери темы выше,\nчтобы видеть новости")
                .font(.system(size: 15))
                .foregroundStyle(.secondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct NewsCard: View {
    let item: NewsItem
    let onSave: () -> Void

    private let blueGradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Topic color dot
            Circle()
                .fill(blueGradient)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(item.preview)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(item.source)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                    Text("•")
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Spacer()
                    Button(action: onSave) {
                        Image(systemName: item.isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13))
                            .foregroundStyle(item.isSaved ? Color(red: 0.0, green: 0.48, blue: 1.0) : .secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
    }
}

// MARK: - Topics Sheet

struct TopicsSheet: View {
    @Binding var topics: [NewsTopic]
    @Environment(\.dismiss) private var dismiss
    @State private var newTopicName = ""
    @State private var showAIHint = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Built-in topics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Встроенные темы")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ForEach($topics.filter { !$0.isCustom.wrappedValue }) { $topic in
                            HStack {
                                Text(topic.emoji)
                                Text(topic.name)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: topic.isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(topic.isSelected ? Color(red: 0.0, green: 0.48, blue: 1.0) : .secondary.opacity(0.3))
                            }
                            .padding(14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    topic.isSelected.toggle()
                                }
                            }
                        }
                    }

                    // Custom topics
                    if !topics.filter({ $0.isCustom }).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Мои темы")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            ForEach($topics.filter { $0.isCustom.wrappedValue }) { $topic in
                                HStack {
                                    Text(topic.emoji)
                                    Text(topic.name)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Button {
                                        topics.removeAll { $0.id == topic.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(14)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }

                    // Add custom topic
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Добавить свою тему")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        HStack(spacing: 10) {
                            TextField("Например: Архитектура", text: $newTopicName)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())

                            Button {
                                guard !newTopicName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                let newTopic = NewsTopic(
                                    id: UUID().uuidString,
                                    name: newTopicName.trimmingCharacters(in: .whitespaces),
                                    emoji: "📌",
                                    isSelected: true,
                                    isCustom: true
                                )
                                withAnimation { topics.append(newTopic) }
                                newTopicName = ""
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                            startPoint: .leading, endPoint: .trailing
                                        ),
                                        in: Circle()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // AI hint banner
                    Button {
                        withAnimation { showAIHint.toggle() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Спроси AI")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Помогу выбрать и назвать темы")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary.opacity(0.4))
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .navigationTitle("Темы новостей")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
        }
    }
}

// MARK: - Tasks Section

struct TasksSection: View {
    @ObservedObject var vm: LearningViewModel
    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var showAllTasks = false
    @State private var editingGroupId: String? = nil

    private let calendar = Calendar.current

    // Фильтруем задачи по выбранной дате
    var filteredTaskGroups: [TaskGroup] {
        vm.taskGroups.compactMap { group in
            let tasksForDate = group.tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }
            guard !tasksForDate.isEmpty else { return nil }
            var filtered = group
            filtered.tasks = tasksForDate
            return filtered
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Date strip
                dateStrip

                // Task groups
                if filteredTaskGroups.isEmpty {
                    emptyTasksPlaceholder
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredTaskGroups.prefix(showAllTasks ? 99 : 2)) { group in
                            TaskGroupCard(
                                group: group,
                                onToggle: { taskId in vm.toggleTask(groupId: group.id, taskId: taskId) },
                                onDelete: { taskId in vm.deleteTask(groupId: group.id, taskId: taskId) }
                            )
                        }
                    }
                }

                // Show all / Add buttons
                HStack(spacing: 10) {
                    if filteredTaskGroups.count > 2 {
                        Button {
                            withAnimation { showAllTasks.toggle() }
                        } label: {
                            Text(showAllTasks ? "Свернуть" : "Все задачи (\(filteredTaskGroups.count))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showAddTask = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Новая группа")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskGroupSheet { groupName, taskTitle, date, start, end, recurrence, priority in
                vm.addTaskGroup(name: groupName, taskTitle: taskTitle, date: date, start: start, end: end, recurrence: recurrence, priority: priority)
            }
        }
    }

    private var dateStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Big date display
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(selectedDate.formatted(.dateTime.day()))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Today button
                if !calendar.isDateInToday(selectedDate) {
                    Button("Сегодня") {
                        withAnimation(.spring(response: 0.3)) { selectedDate = Date() }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.12), in: Capsule())
                }
            }

            // 7-day strip
            HStack(spacing: 6) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(date)

                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedDate = date }
                    } label: {
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 11))
                                .foregroundStyle(isSelected ? .white : .secondary.opacity(0.6))
                            Text(date.formatted(.dateTime.day()))
                                .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : (isToday ? Color(red: 0.0, green: 0.48, blue: 1.0) : .primary))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            : AnyShapeStyle(Color.primary.opacity(0.06)),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
    }

    private var emptyTasksPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("Нет задач на этот день.\nДобавь первую группу задач!")
                .font(.system(size: 15))
                .foregroundStyle(.secondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct TaskGroupCard: View {
    let group: TaskGroup
    let onToggle: (String) -> Void
    let onDelete: (String) -> Void
    @State private var isExpanded = true

    var completedCount: Int { group.tasks.filter { $0.isCompleted }.count }

    var body: some View {
        VStack(spacing: 0) {
            // Group header
            Button {
                withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("\(completedCount)/\(group.tasks.count) выполнено")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(.primary.opacity(0.1), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: group.tasks.isEmpty ? 0 : CGFloat(completedCount) / CGFloat(group.tasks.count))
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 28, height: 28)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .padding(.leading, 4)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().opacity(0.3)

                VStack(spacing: 0) {
                    ForEach(group.tasks) { task in
                        TaskRow(task: task,
                                onToggle: { onToggle(task.id) },
                                onDelete: { onDelete(task.id) })
                        if task.id != group.tasks.last?.id {
                            Divider().padding(.leading, 46).opacity(0.3)
                        }
                    }
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
    }
}

struct TaskRow: View {
    let task: LearningTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted
                        ? Color(red: 0.0, green: 0.48, blue: 1.0)
                        : .secondary.opacity(0.35))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(task.isCompleted ? Color.secondary.opacity(0.5) : Color.primary)
                    .strikethrough(task.isCompleted)
                HStack(spacing: 6) {
                    Text(task.startTime.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary.opacity(0.5))
                    if task.recurring != .once {
                        Text("• \(task.recurring.rawValue)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.7))
                    }
                }
            }
            Spacer()
            // Priority dot
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Task Group Sheet

struct AddTaskGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String, Date, Date, Date, RecurrenceType, TaskPriority) -> Void

    @State private var groupName = ""
    @State private var taskTitle = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var recurrence: RecurrenceType = .once
    @State private var priority: TaskPriority = .medium

    var canSave: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Group name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название группы")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("Например: Английский язык", text: $groupName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    // First task
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Первая задача")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("Что нужно сделать?", text: $taskTitle)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дата и время")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            HStack {
                                Text("Дата")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Spacer()
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .padding(14)

                            Divider().opacity(0.3)

                            HStack {
                                Text("Начало")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Spacer()
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .padding(14)

                            Divider().opacity(0.3)

                            HStack {
                                Text("Конец")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Spacer()
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .padding(14)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
                    }

                    // Recurrence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Повторение")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(RecurrenceType.allCases, id: \.self) { type in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { recurrence = type }
                                    } label: {
                                        Text(type.rawValue)
                                            .font(.system(size: 13, weight: recurrence == type ? .semibold : .regular))
                                            .foregroundStyle(recurrence == type ? .white : .secondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                recurrence == type
                                                ? AnyShapeStyle(LinearGradient(
                                                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                                    startPoint: .leading, endPoint: .trailing
                                                ))
                                                : AnyShapeStyle(Color.primary.opacity(0.08)),
                                                in: Capsule()
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Приоритет")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { priority = p }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(p.color)
                                            .frame(width: 8, height: 8)
                                        Text(p.rawValue)
                                            .font(.system(size: 13, weight: priority == p ? .semibold : .regular))
                                            .foregroundStyle(priority == p ? .white : .secondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        priority == p
                                        ? AnyShapeStyle(p.color.opacity(0.8))
                                        : AnyShapeStyle(Color.primary.opacity(0.08)),
                                        in: Capsule()
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                    }

                    // Save
                    Button {
                        onAdd(groupName, taskTitle, date, startTime, endTime, recurrence, priority)
                        dismiss()
                    } label: {
                        Text("Создать")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(canSave ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canSave
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                : AnyShapeStyle(Color.primary.opacity(0.1)),
                                in: Capsule()
                            )
                    }
                    .disabled(!canSave)
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .navigationTitle("Новая группа задач")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Knowledge Base Section

struct KnowledgeSection: View {
    @ObservedObject var vm: LearningViewModel
    @State private var selectedTopicId: String? = nil
    @State private var selectedNoteId: String? = nil
    @State private var showAddTopic = false
    @State private var showAddNote = false
    @State private var showGraphView = false
    @State private var searchText = ""

    var selectedTopic: KnowledgeTopic? {
        vm.knowledgeTopics.first { $0.id == selectedTopicId }
    }
    var selectedNote: KnowledgeNote? {
        selectedTopic?.notes.first { $0.id == selectedNoteId }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Search + Graph toggle
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    TextField("Поиск по заметкам...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())

                Button {
                    showGraphView = true
                } label: {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            if selectedTopicId == nil {
                // Topics grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(vm.knowledgeTopics) { topic in
                                KnowledgeTopicCard(topic: topic) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTopicId = topic.id
                                    }
                                }
                            }

                            // Add topic card
                            Button {
                                showAddTopic = true
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "plus.circle.dashed")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.6))
                                    Text("Новая тема")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 110)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), lineWidth: 1, antialiased: true)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            } else if selectedNoteId == nil, let topic = selectedTopic {
                // Notes list
                knowledgeNotesList(topic: topic)
            } else if let note = selectedNote {
                // Note editor
                NoteEditorView(note: note) { updatedNote in
                    vm.updateNote(updatedNote)
                }
            }
        }
        .sheet(isPresented: $showAddTopic) {
            AddTopicSheet { name, emoji in
                vm.addKnowledgeTopic(name: name, emoji: emoji)
            }
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet { title, content in
                if let topicId = selectedTopicId {
                    vm.addNote(topicId: topicId, title: title, content: content)
                }
            }
        }
        .sheet(isPresented: $showGraphView) {
            KnowledgeGraphView(topics: vm.knowledgeTopics)
        }
    }

    private func knowledgeNotesList(topic: KnowledgeTopic) -> some View {
        VStack(spacing: 0) {
            // Topic header with back button
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTopicId = nil }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Темы")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(topic.emoji) \(topic.name)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    showAddNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            if topic.notes.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("Нет заметок.\nСоздай первую заметку!")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(topic.notes) { note in
                            NoteCard(note: note) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedNoteId = note.id
                                }
                            }
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct KnowledgeTopicCard: View {
    let topic: KnowledgeTopic
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Text(topic.emoji)
                    .font(.system(size: 32))
                Spacer()
                VStack(alignment: .leading, spacing: 3) {
                    Text(topic.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(topic.notes.count) заметок")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 110)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

struct NoteCard: View {
    let note: KnowledgeNote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(note.content.replacingOccurrences(of: "#", with: "").prefix(80))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if !note.tags.isEmpty {
                        ForEach(note.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.1), in: Capsule())
                        }
                    }
                    Spacer()
                    if !note.linkedNoteIds.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text("\(note.linkedNoteIds.count)")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Note Editor

struct NoteEditorView: View {
    let note: KnowledgeNote
    let onSave: (KnowledgeNote) -> Void
    @State private var editedContent: String
    @State private var isEditing = false

    init(note: KnowledgeNote, onSave: @escaping (KnowledgeNote) -> Void) {
        self.note = note
        self.onSave = onSave
        _editedContent = State(initialValue: note.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Note header
            HStack {
                Text(note.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    if isEditing {
                        var updated = note
                        updated.content = editedContent
                        onSave(updated)
                    }
                    withAnimation { isEditing.toggle() }
                } label: {
                    Text(isEditing ? "Готово" : "Изменить")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            ScrollView {
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(minHeight: 400)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                } else {
                    // Simple markdown-like render
                    Text(renderMarkdown(editedContent))
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                }

                // Linked notes section
                if !note.linkedNoteIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Связанные заметки")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        ForEach(note.linkedNoteIds, id: \.self) { id in
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                                Text(id)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                Spacer(minLength: 60)
            }
        }
    }

    private func renderMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

// MARK: - Knowledge Graph View (2D network)

struct KnowledgeGraphView: View {
    let topics: [KnowledgeTopic]
    @Environment(\.dismiss) private var dismiss

    var allNotes: [(note: KnowledgeNote, topic: KnowledgeTopic)] {
        topics.flatMap { topic in topic.notes.map { ($0, topic) } }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()

                Canvas { ctx, size in
                    let notes = allNotes
                    guard !notes.isEmpty else { return }

                    let positions = nodePositions(count: notes.count, size: size)

                    // Draw edges
                    for (i, item) in notes.enumerated() {
                        for linkedId in item.note.linkedNoteIds {
                            if let j = notes.firstIndex(where: { $0.note.id == linkedId }) {
                                var path = Path()
                                path.move(to: positions[i])
                                path.addLine(to: positions[j])
                                ctx.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 1)
                            }
                        }
                    }

                    // Draw nodes
                    for (i, item) in notes.enumerated() {
                        let pos = positions[i]
                        let radius: CGFloat = 18

                        // Node circle
                        let rect = CGRect(x: pos.x - radius, y: pos.y - radius, width: radius * 2, height: radius * 2)
                        ctx.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.8)))

                        // Label
                        ctx.draw(
                            Text(item.note.title.prefix(10))
                                .font(.system(size: 10))
                                .foregroundStyle(.white),
                            at: CGPoint(x: pos.x, y: pos.y + radius + 10)
                        )
                    }
                }

                // Topic legend
                VStack {
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(topics) { topic in
                                HStack(spacing: 6) {
                                    Text(topic.emoji)
                                    Text(topic.name)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.1), in: Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Граф знаний")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Закрыть") { dismiss() }
                        .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
        }
    }

    private func nodePositions(count: Int, size: CGSize) -> [CGPoint] {
        guard count > 0 else { return [] }
        let cx = size.width / 2
        let cy = size.height / 2
        let radius = min(size.width, size.height) * 0.35

        return (0..<count).map { i in
            let angle = (Double(i) / Double(count)) * 2 * .pi - .pi / 2
            return CGPoint(
                x: cx + radius * cos(angle),
                y: cy + radius * sin(angle)
            )
        }
    }
}

// MARK: - Add Topic / Note Sheets

struct AddTopicSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String) -> Void
    @State private var name = ""
    @State private var emoji = "📁"
    let emojis = ["📁","📚","💡","🔬","💻","🎨","🎵","🏋️","💰","🌍","🚀","🪙","🧬","📐","🎯"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Emoji picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojis, id: \.self) { e in
                            Button {
                                withAnimation { emoji = e }
                            } label: {
                                Text(e)
                                    .font(.system(size: 26))
                                    .frame(width: 50, height: 50)
                                    .background(emoji == e ? Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.2) : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Selected display
                Text(emoji)
                    .font(.system(size: 60))

                // Name
                TextField("Название темы", text: $name)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Button {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAdd(name.trimmingCharacters(in: .whitespaces), emoji)
                    dismiss()
                } label: {
                    Text("Создать тему")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
            .navigationTitle("Новая тема")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String) -> Void
    @State private var title = ""
    @State private var content = "# Заголовок\n\n"

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextField("Название заметки", text: $title)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())

                TextEditor(text: $content)
                    .font(.system(size: 15, design: .monospaced))
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .frame(minHeight: 300)

                Button {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAdd(title.trimmingCharacters(in: .whitespaces), content)
                    dismiss()
                } label: {
                    Text("Создать заметку")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .navigationTitle("Новая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class LearningViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = NewsItem.samples
    @Published var topics: [NewsTopic] = NewsTopic.defaults
    @Published var taskGroups: [TaskGroup] = TaskGroup.samples
    @Published var knowledgeTopics: [KnowledgeTopic] = KnowledgeTopic.samples
    @Published var isLoading = false
    private var hasLoaded = false

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
    }

    // MARK: News
    func toggleSaved(newsId: String) {
        if let i = newsItems.firstIndex(where: { $0.id == newsId }) {
            newsItems[i].isSaved.toggle()
        }
    }

    // MARK: Tasks
    func toggleTask(groupId: String, taskId: String) {
        guard let gi = taskGroups.firstIndex(where: { $0.id == groupId }),
              let ti = taskGroups[gi].tasks.firstIndex(where: { $0.id == taskId })
        else { return }
        withAnimation(.spring(response: 0.3)) {
            taskGroups[gi].tasks[ti].isCompleted.toggle()
        }
    }

    func deleteTask(groupId: String, taskId: String) {
        guard let gi = taskGroups.firstIndex(where: { $0.id == groupId }) else { return }
        taskGroups[gi].tasks.removeAll { $0.id == taskId }
        if taskGroups[gi].tasks.isEmpty { taskGroups.remove(at: gi) }
    }

    func addTaskGroup(name: String, taskTitle: String, date: Date, start: Date, end: Date, recurrence: RecurrenceType, priority: TaskPriority) {
        let task = LearningTask(id: UUID().uuidString, title: taskTitle, dueDate: date, startTime: start, endTime: end, isCompleted: false, recurring: recurrence, priority: priority)
        let group = TaskGroup(id: UUID().uuidString, name: name, tasks: [task])
        withAnimation { taskGroups.append(group) }
    }

    // MARK: Knowledge
    func addKnowledgeTopic(name: String, emoji: String) {
        let topic = KnowledgeTopic(id: UUID().uuidString, name: name, emoji: emoji, notes: [])
        withAnimation { knowledgeTopics.append(topic) }
    }

    func addNote(topicId: String, title: String, content: String) {
        guard let i = knowledgeTopics.firstIndex(where: { $0.id == topicId }) else { return }
        let note = KnowledgeNote(id: UUID().uuidString, title: title, content: content, topicId: topicId, tags: [], linkedNoteIds: [], createdAt: Date(), updatedAt: Date())
        withAnimation { knowledgeTopics[i].notes.append(note) }
    }

    func updateNote(_ note: KnowledgeNote) {
        guard let ti = knowledgeTopics.firstIndex(where: { $0.id == note.topicId }),
              let ni = knowledgeTopics[ti].notes.firstIndex(where: { $0.id == note.id })
        else { return }
        knowledgeTopics[ti].notes[ni] = note
    }

}
