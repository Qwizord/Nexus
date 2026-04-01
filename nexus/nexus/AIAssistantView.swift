import SwiftUI
import Combine

struct AIAssistantView: View {
    @StateObject private var vm = AIViewModel()
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var showInfoSheet = false
    @State private var infoButtonPressed = false
    @State private var historyButtonPressed = false
    @State private var sendButtonPressed = false
    @State private var clearButtonPressed = false
    @State private var sparklePhase = false
    @State private var sparkleTap = false
    @State private var showHistorySheet = false
    

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 16)
                .padding(.top, 60)
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
                        if vm.messages.isEmpty {
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
                Text("AI-ассистент")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if vm.isAgentMode, let agent = vm.detectedAgent {
                    Text("Агент: \(agent.rawValue)")
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
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    showInfoSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)

            Text("Как работает AI")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, -30)

            ScrollView(showsIndicators: true) {
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
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.visible)

            Button("Понятно") {
                showInfoSheet = false
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: 200)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 20)
        .background(AnimatedDarkBackground())
        .dismissKeyboardOnTap()
        .presentationDetents([.medium])
    }

    var historySheet: some View {
        let showIndicators = vm.sessions.count > 4
        return VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    showHistorySheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)

            Text("История чатов")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, -30)

            ScrollView(showsIndicators: showIndicators) {
                VStack(spacing: 10) {
                    if vm.sessions.isEmpty {
                        Text("Пока нет истории. Начни новый диалог — он появится здесь.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 4)
                            .padding(.top, 0)
                            .padding(.bottom, 4)
                    } else {
                        ForEach(vm.sessions) { session in
                            Button {
                                vm.selectSession(session.id)
                                showHistorySheet = false
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text(session.lastMessage)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(session.date.formatted(Date.FormatStyle()
                                        .day(.twoDigits).month(.twoDigits).year()))
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                .padding(14)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .scrollIndicators(showIndicators ? .visible : .hidden)

            HStack(spacing: 12) {
                Button("Очистить историю") {
                    vm.clearHistory()
                    showHistorySheet = false
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.red.opacity(0.35), lineWidth: 0.6))
                .contentShape(RoundedRectangle(cornerRadius: 14))

                Button("Новый чат") {
                    vm.startNewChat()
                    showHistorySheet = false
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 20)
        .background(AnimatedDarkBackground())
        .presentationDetents([.medium])
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.6, blue: 1.0), Color(red: 0.7, green: 0.35, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(sparklePhase ? 1.08 : 0.92)
                    .rotationEffect(.degrees(sparklePhase ? 6 : -6))
                    .opacity(sparklePhase ? 1.0 : 0.75)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: sparklePhase)
                    .symbolEffect(.pulse, value: sparkleTap)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    sparkleTap.toggle()
                }
            }
            .onAppear {
                sparklePhase = true
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
                TextField("Напиши сообщение...", text: $inputText, axis: .vertical)
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
    @Published var isAgentMode = false
    @Published var detectedAgent: AgentType?
    @Published var sessions: [ChatSession] = []
    @Published var activeSessionId: String?

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

    func loadSessions() {
        guard let userId = authManager.currentUserId else { return }
        Task {
            do {
                sessions = try await firebase.chatRepo.fetchSessions(userId: userId)
            } catch {
                print("[AI] Failed to load sessions: \(error)")
            }
        }
    }

    // MARK: - Send Message

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if activeSessionId == nil {
            createSession(with: trimmed)
        }

        let userMsg = ChatMessageItem(
            id: UUID().uuidString, role: "user", content: text,
            timestamp: Date(), isAgentMode: isAgentMode, agentType: nil
        )
        messages.append(userMsg)
        appendToActiveSession(userMsg)
        saveMessageToFirestore(userMsg)
        isTyping = true

        Task {
            // Определяем агента
            if isAgentMode {
                detectedAgent = await agentDetection.detectAgent(for: text)
            }

            // Получаем ответ
            let reply = await fetchReply(for: text)

            isTyping = false
            let assistantMsg = ChatMessageItem(
                id: UUID().uuidString, role: "assistant", content: reply,
                timestamp: Date(), isAgentMode: isAgentMode,
                agentType: detectedAgent?.rawValue
            )
            messages.append(assistantMsg)
            appendToActiveSession(assistantMsg)
            saveMessageToFirestore(assistantMsg)
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
            // Fallback: локальный
            if let idx = sessions.firstIndex(where: { $0.id == id }) {
                activeSessionId = id
                messages = sessions[idx].messages
            }
            return
        }

        activeSessionId = id
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

    private func createSession(with firstMessage: String) {
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

        // Сохраняем в Firestore
        if let userId = authManager.currentUserId {
            Task { try? await firebase.chatRepo.createSession(new, userId: userId) }
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
        let userId = authManager.currentUserId ?? "anonymous"
        do {
            let response = try await NetworkManager.shared.sendMessage(
                content: text,
                isAgentMode: isAgentMode,
                userId: userId,
                context: .empty
            )
            return response.reply
        } catch {
            return getMockReply(for: text)
        }
    }

    private func getMockReply(for text: String) -> String {
        switch detectedAgent {
        case .health:
            return "По данным Apple Health за последнюю неделю твой средний сон составил 7.2 часа — это хороший показатель. Рекомендую добавить 30 минут к времени отхода ко сну для оптимального восстановления."
        case .finance:
            return "За последний месяц основные расходы в категории 'Еда' составили 45% от бюджета. Рекомендую рассмотреть планирование питания — это может сократить расходы на 15-20%."
        case .learning:
            return "Исходя из твоего графика, оптимальное время для обучения — утро с 9 до 11. Предлагаю план: 3 дня в неделю по 45 минут с фокусом на Swift и английский."
        default:
            return "Я готов помочь тебе анализировать данные здоровья, финансы и планировать обучение. Что тебя интересует?"
        }
    }
}
