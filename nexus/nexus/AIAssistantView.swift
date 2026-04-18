import SwiftUI
import Combine

struct AIAssistantView: View {
    @StateObject private var vm = AIViewModel()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var showInfoSheet = false
    @State private var infoButtonPressed = false
    @State private var historyButtonPressed = false
    @State private var sendButtonPressed = false
    @State private var clearButtonPressed = false
    @State private var sparkleTap = false
    @State private var showHistorySheet = false
    

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 16)
                .padding(.top, verticalSizeClass == .compact ? 25 : 25)
                .padding(.bottom, 12)

            // Agent mode banner
            if vm.isAgentMode {
                agentModeBanner
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        if let first = vm.messages.first {
                            DateHeader(date: first.timestamp)
                                .padding(.top, 12)
                        }
                        if vm.isLoadingSessions {
                            VStack(spacing: 16) {
                                ForEach(0..<3, id: \.self) { i in
                                    HStack(alignment: .bottom, spacing: 8) {
                                        if i % 2 == 0 {
                                            Circle().fill(.white.opacity(0.07)).frame(width: 28, height: 28)
                                        } else {
                                            Spacer(minLength: 60)
                                        }
                                        SkeletonBlock(width: CGFloat([160,200,140][i]), height: 44, cornerRadius: 18)
                                        if i % 2 != 0 {
                                            EmptyView()
                                        } else {
                                            Spacer(minLength: 60)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 40)
                        } else if vm.isSessionsError {
                            NetworkErrorView { vm.loadSessions(force: true) }
                                .padding(.top, 40)
                                .padding(.horizontal, 4)
                        } else if vm.messages.isEmpty {
                            emptyState
                                .padding(.top, 40)
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        ForEach(vm.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if vm.isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: vm.messages.isEmpty)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .dismissKeyboardOnTap()
                .onChange(of: vm.messages.count) { _, _ in
                    withAnimation { proxy.scrollTo(vm.messages.last?.id ?? "typing", anchor: .bottom) }
                }
                .onChange(of: vm.isTyping) { _, _ in
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }

            // Input bar
            inputBar
        }
        .onAppear {
            guard AuthenticationManager.shared.currentUserId != nil else { return }
            vm.loadSessions()   // внутри guard hasLoadedSessions — грузит только один раз
        }
        .refreshable { vm.loadSessions(force: true) }
        .animation(.spring(response: 0.4), value: vm.isAgentMode)
        .sheet(isPresented: $showInfoSheet) {
            infoSheet
        }
        .sheet(isPresented: $showHistorySheet) {
            historySheet
        }
    }

    // MARK: - Header

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("ai.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if vm.isAgentMode, let agent = vm.detectedAgent {
                    Text("\(L("ai.agent")) \(agent.rawValue)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .transition(.opacity)
                }
            }
            Spacer()
            headerButtons
        }
    }

    @ViewBuilder
    var headerButtons: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                headerButtonsContent
            }
        } else {
            headerButtonsContent
        }
    }

    @ViewBuilder
    var headerButtonsContent: some View {
        HStack(spacing: 10) {
            Button {
                showHistorySheet = true
            } label: {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .applyGlassCircle()
                    .scaleEffect(historyButtonPressed ? 0.95 : 1.0)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { historyButtonPressed = true } }
                    .onEnded { _ in withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { historyButtonPressed = false } }
            )

            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .applyGlassCircle()
                    .scaleEffect(infoButtonPressed ? 0.95 : 1.0)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { infoButtonPressed = true } }
                    .onEnded { _ in withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { infoButtonPressed = false } }
            )
        }
    }

    // MARK: - Agent Mode Banner

    var agentModeBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AgentType.allCases, id: \.self) { agent in
                    AgentChip(agent: agent, isDetected: vm.detectedAgent == agent)
                }
            }
        }
    }

    var infoSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("• Внутри есть агенты с разными профилями: медицина, финансы, обучение и общий.")
                    Text("• Агент выбирается автоматически по контексту твоего запроса и твоих данных.")
                    Text("• Чем точнее запрос, тем лучше подбор агента и качество ответа.")
                    Text("• В платной подписке уже учтена стоимость токенов для рассуждения и анализа.")
                    Text("• Мы не сохраняем твой контент в чате без необходимости — только метаданные для качества.")
                    Text("• Можно задавать вопросы о привычках, целях и прогрессе — ответы будут учитывать историю.")
                    Text("• Вопросы о здоровье, финансах и обучении автоматически маршрутизируются к нужному агенту.")
                    Text("• Ответы строятся с учетом твоих данных, но ты всегда контролируешь, что сохраняется.")
                    Text("• Если контекст неполный, AI задаст уточняющие вопросы, чтобы не ошибаться.")
                    Text("• Мы постоянно улучшаем модели, но решения остаются на твоей стороне.")
                }
                .font(.system(size: 15))
                .foregroundStyle(.primary.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle(L("ai.info.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular, in: Circle())
                        .contentShape(Circle())
                        .onTapGesture { showInfoSheet = false }
                        .simultaneousGesture(DragGesture(minimumDistance: 0))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    var historySheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if vm.sessions.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Text(L("ai.history.empty"))
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else {
                        List(vm.sessions) { session in
                            Button {
                                vm.selectSession(session.id)
                                showHistorySheet = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(session.lastMessage)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: 12) {
                    Button {
                        vm.clearHistory()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(vm.sessions.isEmpty ? Color(white: 0.45) : .white)
                            .frame(width: 48, height: 48)
                            .background(
                                vm.sessions.isEmpty
                                    ? Color(red: 0.28, green: 0.08, blue: 0.08)
                                    : Color.red,
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(!vm.sessions.isEmpty)

                    Button {
                        vm.startNewChat()
                        showHistorySheet = false
                    } label: {
                        Text("Добавить")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .frame(height: 48)
                            .background(
                                Color(red: 0.0, green: 0.48, blue: 1.0),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle(L("ai.history.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular, in: Circle())
                        .contentShape(Circle())
                        .onTapGesture { showHistorySheet = false }
                        .simultaneousGesture(DragGesture(minimumDistance: 0))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 24) {
            CircularStarsView()
                .frame(width: 80, height: 80)
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    sparkleTap.toggle()
                }
            }

            VStack(spacing: 8) {
                Text("Привет! Я Nexus AI")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Спроси меня о своём здоровье,\nфинансах или планах обучения")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            // Quick suggestions
            VStack(spacing: 8) {
                ForEach(vm.suggestions, id: \.self) { suggestion in
                    Button {
                        inputText = suggestion
                        sendMessage()
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Input Bar

    var inputBar: some View {
        return Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer {
                    inputBarContent
                }
            } else {
                inputBarContent
            }
        }
    }

    @ViewBuilder
    var inputBarContent: some View {
        let hasText = !inputText.trimmingCharacters(in: .whitespaces).isEmpty

        HStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField(L("ai.placeholder"), text: $inputText, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .submitLabel(.send)

                if !inputText.isEmpty {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            inputText = ""
                        }
                        inputFocused = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black.opacity(0.9))
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.8))
                            )
                            .scaleEffect(clearButtonPressed ? 0.92 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { clearButtonPressed = true } }
                            .onEnded { _ in withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { clearButtonPressed = false } }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .applyGlassCapsule()
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                sendMessage()
            } label: {
                ZStack {
                    if hasText {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.8)
                            .blendMode(.plusLighter)
                    }
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 38, height: 38)
                .applyGlassCircle()
                .compositingGroup()
                .scaleEffect(sendButtonPressed ? 0.95 : 1.0)
            }
            .disabled(!hasText)
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { sendButtonPressed = true } }
                    .onEnded { _ in withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { sendButtonPressed = false } }
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(1))
                .blur(radius: 15) // ← вот gaussian blur
        )
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        vm.send(text)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessageItem

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 28, height: 28)
                    Image(systemName: "sparkles").font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser && message.isAgentMode, let agent = message.agentType {
                    Text(agent)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.leading, 4)
                }

                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        : AnyShapeStyle(Material.ultraThin),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(isUser ? .clear : .white.opacity(0.1), lineWidth: 0.5)
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label("Копировать всё", systemImage: "doc.on.doc")
                        }
                    }

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 28, height: 28)
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .scaleEffect(animating ? 1.3 : 0.7)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15), value: animating)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
            Spacer(minLength: 60)
        }
        .onAppear { animating = true }
    }
}

// MARK: - Glass Fusion Helpers

extension View {
    @ViewBuilder
    func applyGlassCircle() -> some View {
        self.glassEffect(.regular.interactive(), in: Circle())
    }

    @ViewBuilder
    func applyGlassCapsule() -> some View {
        self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Date Header

struct DateHeader: View {
    let date: Date

    var body: some View {
        Text(dateHeaderFormatter.string(from: date))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
    }
}

// MARK: - Interactive Sheen


private let dateHeaderFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateFormat = "dd.MM.yyyy 'г.'"
    return formatter
}()

// MARK: - Agent Chip

struct AgentChip: View {
    let agent: AgentType
    let isDetected: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: agent.icon)
                .font(.system(size: 12))
            Text(agent.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(isDetected ? .white : .white.opacity(0.5))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isDetected
            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.3, green: 0.4, blue: 1.0).opacity(0.5), Color(red: 0.5, green: 0.1, blue: 0.9).opacity(0.4)], startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(Material.ultraThin),
            in: Capsule()
        )
        .overlay(Capsule().strokeBorder(isDetected ? .white.opacity(0.25) : .white.opacity(0.08), lineWidth: 0.5))
    }
}

// MARK: - ViewModel

@MainActor
class AIViewModel: ObservableObject {
    @Published var messages: [ChatMessageItem] = []
    @Published var isTyping = false
    @Published var isLoadingSessions = false
    @Published var isSessionsError = false
    @Published var isAgentMode = false
    @Published var detectedAgent: AgentType?
    @Published var sessions: [ChatSession] = []
    @Published var activeSessionId: String?
    private var hasLoadedSessions = false

    private let firebase = FirebaseService.shared
    private let authManager = AuthenticationManager.shared
    private let agentDetection = AIAgentDetectionService.shared
    private var messageListenerTask: Task<Void, Never>?

    let suggestions = [
        "Как я сплю последнюю неделю?",
        "Проанализируй мои расходы за месяц",
        "Составь план обучения на месяц"
    ]

    // MARK: - Load Sessions from Firestore

    func loadSessions(force: Bool = false) {
        guard let userId = authManager.currentUserId else { return }
        // Skip repeat loads unless explicit refresh — экран и данные уже в памяти
        if hasLoadedSessions && !force { return }
        // Показываем лоадер только при первой загрузке
        if !hasLoadedSessions { isLoadingSessions = true }
        isSessionsError = false
        Task {
            do {
                let fetched = try await firebase.chatRepo.fetchSessions(userId: userId)
                sessions = fetched
                isSessionsError = false
                hasLoadedSessions = true
                let savedId = UserDefaults.standard.string(forKey: "lastActiveChatSessionId_\(userId)")
                if let id = savedId, sessions.contains(where: { $0.id == id }) {
                    selectSession(id)
                } else if let first = sessions.first, activeSessionId == nil {
                    selectSession(first.id)
                }
            } catch {
                print("[AI] Failed to load sessions: \(error)")
            }
            isLoadingSessions = false
        }
    }

    // MARK: - Send Message

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let needsNewSession = activeSessionId == nil

        if needsNewSession {
            createSessionLocally(with: trimmed)
        }

        let userMsg = ChatMessageItem(
            id: UUID().uuidString, role: "user", content: text,
            timestamp: Date(), isAgentMode: isAgentMode, agentType: nil
        )
        messages.append(userMsg)
        appendToActiveSession(userMsg)
        isTyping = true

        Task {
            // Если новая сессия — дождаться создания в Firestore перед сохранением сообщений
            if needsNewSession {
                await createSessionInFirestore()
            }
            saveMessageToFirestore(userMsg)

            if isAgentMode {
                detectedAgent = await agentDetection.detectAgent(for: text)
            }

            let reply = await fetchReply(for: text)

            isTyping = false

            // Typewriter — постепенное появление текста
            let msgId = UUID().uuidString
            let placeholder = ChatMessageItem(
                id: msgId, role: "assistant", content: "",
                timestamp: Date(), isAgentMode: isAgentMode,
                agentType: detectedAgent?.rawValue
            )
            messages.append(placeholder)

            let chars = Array(reply)
            var revealed = ""
            let chunkSize = max(1, chars.count / 80)
            for i in stride(from: 0, to: chars.count, by: chunkSize) {
                let end = min(i + chunkSize, chars.count)
                revealed += String(chars[i..<end])
                if let idx = messages.firstIndex(where: { $0.id == msgId }) {
                    messages[idx] = ChatMessageItem(
                        id: msgId, role: "assistant", content: revealed,
                        timestamp: placeholder.timestamp, isAgentMode: isAgentMode,
                        agentType: detectedAgent?.rawValue
                    )
                }
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms per chunk
            }

            // Финальное сообщение с полным текстом
            if let idx = messages.firstIndex(where: { $0.id == msgId }) {
                let final = ChatMessageItem(
                    id: msgId, role: "assistant", content: reply,
                    timestamp: placeholder.timestamp, isAgentMode: isAgentMode,
                    agentType: detectedAgent?.rawValue
                )
                messages[idx] = final
                appendToActiveSession(final)
                saveMessageToFirestore(final)
            }
        }
    }

    // MARK: - Session Management

    func startNewChat() {
        stopMessageListener()
        activeSessionId = nil
        messages = []
        detectedAgent = nil
        isTyping = false
    }

    func clearHistory() {
        guard let userId = authManager.currentUserId else {
            sessions = []
            startNewChat()
            return
        }
        Task {
            try? await firebase.chatRepo.clearAllSessions(userId: userId)
            sessions = []
            startNewChat()
        }
    }

    func selectSession(_ id: String) {
        guard let userId = authManager.currentUserId else {
            if let idx = sessions.firstIndex(where: { $0.id == id }) {
                activeSessionId = id
                messages = sessions[idx].messages
            }
            return
        }

        activeSessionId = id
        UserDefaults.standard.set(id, forKey: "lastActiveChatSessionId_\(userId)")

        Task {
            do {
                messages = try await firebase.chatRepo.fetchMessages(sessionId: id, userId: userId, limit: 50)
            } catch {
                if let idx = sessions.firstIndex(where: { $0.id == id }) {
                    messages = sessions[idx].messages
                }
            }
            startMessageListener(sessionId: id)
        }
    }

    // MARK: - Real-time Message Listener

    private func startMessageListener(sessionId: String) {
        stopMessageListener()
        guard let userId = authManager.currentUserId else { return }

        messageListenerTask = Task {
            for await msgs in firebase.chatRepo.listenToMessages(sessionId: sessionId, userId: userId) {
                guard !Task.isCancelled else { break }
                self.messages = msgs
            }
        }
    }

    private func stopMessageListener() {
        messageListenerTask?.cancel()
        messageListenerTask = nil
    }

    // MARK: - Firestore Persistence

    private func createSessionLocally(with firstMessage: String) {
        let title = firstMessage.isEmpty ? "Новый чат" : String(firstMessage.prefix(28))
        let new = ChatSession(
            id: UUID().uuidString,
            title: title,
            lastMessage: firstMessage,
            date: Date(),
            messages: []
        )
        activeSessionId = new.id
        sessions.insert(new, at: 0)
        if let userId = authManager.currentUserId {
            UserDefaults.standard.set(new.id, forKey: "lastActiveChatSessionId_\(userId)")
        }
    }

    private func createSessionInFirestore() async {
        guard let sessionId = activeSessionId,
              let session = sessions.first(where: { $0.id == sessionId }),
              let userId = authManager.currentUserId else { return }
        do {
            try await firebase.chatRepo.createSession(session, userId: userId)
        } catch {
            print("[AI] Failed to create session in Firestore: \(error)")
        }
    }

    private func appendToActiveSession(_ message: ChatMessageItem) {
        guard let id = activeSessionId,
              let idx = sessions.firstIndex(where: { $0.id == id })
        else { return }

        sessions[idx].messages.append(message)
        sessions[idx].lastMessage = message.content
        sessions[idx].date = message.timestamp
    }

    private func saveMessageToFirestore(_ message: ChatMessageItem) {
        guard let sessionId = activeSessionId,
              let userId = authManager.currentUserId else { return }
        Task {
            try? await firebase.chatRepo.saveMessage(message, sessionId: sessionId, userId: userId)
        }
    }

    // MARK: - Fetch Reply

    private func fetchReply(for text: String) async -> String {
        return await fetchGroqReply(for: text) ?? "Не удалось получить ответ. Попробуй ещё раз."
    }

    // MARK: - Groq LLM

    // OpenRouter — бесплатные модели, без гео-ограничений. Ключ: openrouter.ai → Keys
    private let openRouterKey = "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"

    // Fallback-список если не удалось получить актуальные модели с OpenRouter
    private let fallbackModels = [
        "meta-llama/llama-3.3-70b-instruct:free",
        "deepseek/deepseek-r1:free",
        "deepseek/deepseek-chat-v3-0324:free",
        "google/gemma-3-27b-it:free",
        "google/gemma-3-12b-it:free",
        "mistralai/mistral-small-3.1-24b-instruct:free",
        "qwen/qwen2.5-vl-72b-instruct:free"
    ]

    // Получаем актуальный список бесплатных моделей с OpenRouter
    private func fetchAvailableFreeModels() async -> [String] {
        guard let url = URL(string: "https://openrouter.ai/api/v1/models") else { return fallbackModels }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(openRouterKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 10

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["data"] as? [[String: Any]]
        else { return fallbackModels }

        let freeIds: [String] = models.compactMap { m in
            guard let id = m["id"] as? String,
                  let pricing = m["pricing"] as? [String: Any],
                  let prompt = pricing["prompt"] as? String,
                  (Double(prompt) ?? 1) == 0
            else { return nil }
            return id
        }
        return freeIds.isEmpty ? fallbackModels : freeIds
    }

    private func fetchGroqReply(for text: String) async -> String? {
        guard !openRouterKey.hasPrefix("OPENROUTER_") else { return "⚠️ Вставь ключ OpenRouter в код" }
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return nil }

        let systemPrompt = "Ты — Nexus AI, умный персональный ассистент в приложении Nexus. Помогаешь с анализом здоровья, финансов и личного развития. Отвечай кратко, по делу, на том же языке что пользователь. Не используй markdown-заголовки, пиши естественным текстом."

        var msgs: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for msg in messages.dropLast().suffix(10) where msg.role == "user" || msg.role == "assistant" {
            msgs.append(["role": msg.role, "content": msg.content])
        }
        msgs.append(["role": "user", "content": text])

        let availableModels = await fetchAvailableFreeModels()
        var lastError = "все модели недоступны"

        for model in availableModels {
            let body: [String: Any] = [
                "model": model,
                "messages": msgs,
                "temperature": 0.7,
                "max_tokens": 1024
            ]
            guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(openRouterKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("https://nexus-app.io", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Nexus", forHTTPHeaderField: "X-Title")
            request.timeoutInterval = 30
            request.httpBody = httpBody

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    lastError = "нет HTTP ответа"
                    continue
                }

                let errBody = String(data: data, encoding: .utf8) ?? "?"

                if http.statusCode == 429 || http.statusCode == 404 {
                    lastError = "\(model): \(http.statusCode)"
                    continue
                }

                guard http.statusCode == 200 else {
                    return "⚠️ HTTP \(http.statusCode): \(errBody)"
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let msg = choices.first?["message"] as? [String: Any],
                      let content = msg["content"] as? String
                else {
                    lastError = "parse error: \(errBody.prefix(100))"
                    continue
                }

                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                lastError = error.localizedDescription
                continue
            }
        }

        return "⚠️ \(lastError)"
    }


}

// MARK: - Circular Stars Animation

/// Siri-like AI orb: pulsing gradient core with orbiting particles & light ribbons.
struct CircularStarsView: View {

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                // --- Soft outer halo ---
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.35),
                                Color(red: 0.70, green: 0.45, blue: 1.0).opacity(0.12),
                                .clear
                            ],
                            center: .center, startRadius: 4, endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.0 + 0.06 * sin(t * 1.8))

                // --- Pulsing gradient core (Siri-like orb) ---
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.30, green: 0.55, blue: 1.00),
                                Color(red: 0.55, green: 0.40, blue: 1.00),
                                Color(red: 0.40, green: 0.80, blue: 1.00),
                                Color(red: 0.75, green: 0.50, blue: 1.00),
                                Color(red: 0.30, green: 0.55, blue: 1.00),
                            ]),
                            center: .center,
                            angle: .degrees(t * 55)
                        )
                    )
                    .frame(width: 38, height: 38)
                    .blur(radius: 6)
                    .scaleEffect(1.0 + 0.10 * sin(t * 2.2))

                // --- Bright moving highlight inside core ---
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 12, height: 12)
                    .blur(radius: 5)
                    .offset(
                        x: CGFloat(cos(t * 1.3) * 6),
                        y: CGFloat(sin(t * 1.7) * 6)
                    )

                // --- Outer orbit: 3 particles (clockwise) ---
                ForEach(0..<3, id: \.self) { i in
                    let angle = t * 1.1 + Double(i) * (2 * .pi / 3)
                    let r: Double = 30
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3.2, height: 3.2)
                        .shadow(color: Color(red: 0.55, green: 0.75, blue: 1.0).opacity(0.9), radius: 3)
                        .offset(x: CGFloat(cos(angle) * r), y: CGFloat(sin(angle) * r))
                }

                // --- Inner orbit: 2 tiny violet particles (counter-clockwise) ---
                ForEach(0..<2, id: \.self) { i in
                    let angle = -t * 1.9 + Double(i) * .pi
                    let r: Double = 20
                    Circle()
                        .fill(Color(red: 0.85, green: 0.75, blue: 1.0))
                        .frame(width: 2.2, height: 2.2)
                        .shadow(color: Color(red: 0.75, green: 0.55, blue: 1.0).opacity(0.9), radius: 2)
                        .offset(x: CGFloat(cos(angle) * r), y: CGFloat(sin(angle) * r))
                }
            }
            .frame(width: 80, height: 80)
        }
    }
}
