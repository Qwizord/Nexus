import SwiftUI
import UIKit
import PhotosUI

// MARK: - Feedback View (Support Screen)
//
// Sheet на .medium-детент с прозрачным системным фоном (как FAQ / Политика
// конфиденциальности). Заголовок — «● Поддержка» с мигающим зелёным онлайн-
// индикатором слева (принципиально заметная пульсация). Под заголовком —
// подсказка «Опишите проблему или вашу идею».
//
// Хранение обращений: локально в UserDefaults (через FeedbackRepository).
// Это решает обе проблемы: (а) ошибка Firestore permission-denied при отправке
// ушла; (б) обращения сохраняются между перезапусками приложения.
//
// Отправка уведомления на qwizord@icloud.com — через mailto://: открывается
// почтовый клиент с предзаполненными темой и телом, пользователь жмёт «Send».
// Тикет при этом сохраняется локально даже если письмо не было отправлено.

struct FeedbackView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var cs
    @Environment(\.dismiss) private var dismiss

    @State private var tickets: [FeedbackTicket] = []
    @State private var isLoading = false
    @State private var showNewTicket = false
    @State private var newMessage = ""
    @State private var isSending = false
    @State private var sendError: String?
    @State private var sendSuccess = false
    /// Номер, который будет присвоен следующему обращению — показываем пользователю
    /// заранее в заголовке формы «Обращение №N». Обновляется при открытии sheet'а
    /// и после каждой отправки.
    @State private var peekedTicketNumber: Int = 1

    // MARK: Design tokens
    private let accent1 = Color(red: 0.0, green: 0.48, blue: 1.0)   // #0077FF
    private let accent2 = Color(red: 0.0, green: 0.90, blue: 1.0)   // #00E5FF
    private var accentGrad: LinearGradient {
        LinearGradient(colors: [accent1, accent2],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private let hPad: CGFloat = 16

    private var fg: Color {
        cs == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14)
    }
    private var stroke: Color {
        cs == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }
    /// Непрозрачный фон для блока формы обращения — пользователь попросил
    /// убрать прозрачности с «опишите проблему».
    private var solidCardBg: Color {
        cs == .dark ? Color(white: 0.12) : Color(white: 0.95)
    }
    /// Непрозрачный фон для поля ввода.
    private var solidInputBg: Color {
        cs == .dark ? Color(white: 0.18) : Color(white: 0.905)
    }

    private var userId: String? { appState.userProfile?.id }
    private var userName: String { appState.userProfile?.fullName ?? "Пользователь" }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // Подзаголовок прижат вплотную под nav-title'ом «Поддержка»
                    // (как system navigation subtitle). Никакого top-отступа —
                    // между nav-bar и этой строкой только дефолтный paddingScrollView'а.
                    Text("Опишите проблему или вашу идею")
                        .font(.system(size: 13))
                        .foregroundStyle(fg.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, -14)

                    if showNewTicket { newTicketCard }
                    ticketsList
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, hPad)
                .padding(.top, 0)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showNewTicket)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Слева — кнопка закрыть sheet.
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(cs == .dark ? .white : .black)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }

                // В центре — кастомный title: зелёный онлайн-индикатор
                // чуть-чуть левее заголовка «Поддержка» (увеличенный gap).
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 12) {
                        OnlineDot()
                        Text("Поддержка")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(fg)
                    }
                }

                // Справа — кнопка «+» добавить обращение.
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showNewTicket.toggle()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(accent1)
                    }
                    .buttonStyle(ToolbarCloseStyle())
                }
            }
        }
        .task { await loadTickets() }
    }

    // MARK: - New ticket card
    //
    // Заголовок «Обращение №N» вынесен ЗА плашку с отступом 4pt слева — так же,
    // как секционные заголовки в Settings (начинается от конца скругления).
    // Номер — превью следующего номера из FeedbackRepository; при отправке
    // реально инкрементится и записывается в тикет.
    //
    // Плашка и поле ввода — непрозрачные (solidCardBg / solidInputBg). Кнопка
    // отправки — плотный синий градиент без прозрачности.

    private var newTicketCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Обращение №\(peekedTicketNumber)")
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.5)
                .foregroundStyle(fg.opacity(0.45))
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if newMessage.isEmpty {
                        Text("Опиши проблему или предложение…")
                            .font(.system(size: 14))
                            .foregroundStyle(fg.opacity(0.35))
                            .padding(.horizontal, 14)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $newMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(fg)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .frame(minHeight: 110, maxHeight: 160)
                }
                .background(solidInputBg, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(stroke, lineWidth: 0.5))

                if let err = sendError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.85))
                        .transition(.opacity)
                }
                if sendSuccess {
                    Label("Обращение отправлено!",
                          systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }

                Button {
                    Task { await sendTicket() }
                } label: {
                    Group {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Отправить обращение")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(accentGrad, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSending || newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
            .padding(14)
            .background(solidCardBg, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 0.5))
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
    }

    // MARK: - Tickets list

    @ViewBuilder
    private var ticketsList: some View {
        if isLoading {
            HStack { Spacer(); ProgressView().tint(fg.opacity(0.4)); Spacer() }
                .frame(height: 120)
        } else if tickets.isEmpty {
            // Empty state показываем ТОЛЬКО когда действительно нет обращений.
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Мои обращения")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.5)
                    .foregroundStyle(fg.opacity(0.45))
                    .textCase(.uppercase)
                    .padding(.leading, 12)
                    .padding(.top, 8)
                LazyVStack(spacing: 10) {
                    ForEach(tickets) { ticket in
                        // Тап по карточке → пуш на TicketDetailView (чат
                        // с администратором). Закрытие/переоткрытие/удаление
                        // теперь живут там, а не на самой карточке.
                        NavigationLink {
                            TicketDetailView(
                                ticketId: ticket.id,
                                fg: fg,
                                stroke: stroke,
                                accent: accent1,
                                solidCardBg: solidCardBg,
                                solidInputBg: solidInputBg,
                                onClose:  { Task { await closeTicket(ticket) } },
                                onReopen: { Task { await reopenTicket(ticket) } },
                                onDelete: {
                                    Task { await deleteTicket(ticket) }
                                }
                            )
                            .environmentObject(appState)
                        } label: {
                            TicketCard(
                                ticket: ticket,
                                fg: fg,
                                stroke: stroke,
                                accent: accent1,
                                solidCardBg: solidCardBg
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(accentGrad.opacity(0.16)).frame(width: 72, height: 72)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(accent1)
            }
            Text("Нет обращений")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(fg.opacity(0.75))
            Text("Нажми «+» в правом углу, чтобы написать нам")
                .font(.system(size: 12))
                .foregroundStyle(fg.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func loadTickets() async {
        guard let uid = userId else { return }
        isLoading = true
        defer { isLoading = false }
        tickets = (try? await FeedbackRepository.shared.fetchTickets(userId: uid)) ?? []
        peekedTicketNumber = FeedbackRepository.shared.peekNextTicketNumber()
    }

    private func sendTicket() async {
        guard let uid = userId else {
            sendError = "Не удалось определить пользователя"
            return
        }
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        sendError = nil
        defer { isSending = false }

        let number = FeedbackRepository.shared.nextTicketNumber()
        let ticket = FeedbackTicket(
            number: number,
            userId: uid,
            userName: userName,
            message: trimmed
        )

        do {
            try await FeedbackRepository.shared.submit(ticket: ticket)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tickets.insert(ticket, at: 0)
            }
            newMessage = ""
            withAnimation { sendSuccess = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Фоновой POST на серверный webhook — сервер сам отправит письмо
            // на qwizord@icloud.com. Никакого открытия Mail.app из приложения.
            Task.detached { await FeedbackView.postToBackend(ticket: ticket) }

            // Обновляем превью следующего номера (он уже инкрементился).
            peekedTicketNumber = FeedbackRepository.shared.peekNextTicketNumber()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    sendSuccess = false
                    showNewTicket = false
                }
            }
        } catch {
            sendError = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func closeTicket(_ ticket: FeedbackTicket) async {
        try? await FeedbackRepository.shared.closeTicket(id: ticket.id)
        if let idx = tickets.firstIndex(where: { $0.id == ticket.id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                tickets[idx].status = .closed
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func reopenTicket(_ ticket: FeedbackTicket) async {
        try? await FeedbackRepository.shared.reopenTicket(id: ticket.id)
        if let idx = tickets.firstIndex(where: { $0.id == ticket.id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                tickets[idx].status = .open
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deleteTicket(_ ticket: FeedbackTicket) async {
        try? await FeedbackRepository.shared.deleteTicket(id: ticket.id)
        withAnimation(.easeInOut(duration: 0.25)) {
            tickets.removeAll { $0.id == ticket.id }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Передаёт обращение на backend (n8n / REST-webhook). Сервер сам отправит
    /// письмо на qwizord@icloud.com. Вызов fire-and-forget: если сеть/бэкенд
    /// недоступны — тикет всё равно сохранён локально, UI обновился.
    ///
    /// `static` + `Task.detached`, чтобы не ловить `@MainActor` self в background
    /// и не передавать SwiftUI-state через границу актёра.
    static func postToBackend(ticket: FeedbackTicket) async {
        // TODO: заменить на реальный URL n8n-вебхука, когда бэкенд будет готов.
        // Сейчас placeholder — запрос молча зафейлится, локальный тикет цел.
        let urlString = "https://api.nexus.app/v1/feedback"
        guard let url = URL(string: urlString) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10

        let iso = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "ticketNumber": ticket.number,
            "userId":       ticket.userId,
            "userName":     ticket.userName,
            "message":      ticket.message,
            "createdAt":    iso.string(from: ticket.createdAt),
            "deliverTo":    "qwizord@icloud.com"
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        _ = try? await URLSession.shared.data(for: req)
    }
}

// MARK: - Ticket Card (превью строка в списке)
//
// Лёгкая тапабельная карточка: номер, статус, дата + сокращённый текст.
// Если есть ответ администратора — под текстом появляется маленькая подсказка
// «• есть ответ». Полный чат с админом — в TicketDetailView, куда переходим
// по NavigationLink из родителя.

fileprivate struct TicketCard: View {
    let ticket: FeedbackTicket
    let fg: Color
    let stroke: Color
    let accent: Color
    let solidCardBg: Color

    private var statusColor: Color {
        switch ticket.status {
        case .open:     return .orange
        case .answered: return .green
        case .closed:   return Color(white: 0.5)
        }
    }

    private var statusIcon: String {
        switch ticket.status {
        case .open:     return "clock.fill"
        case .answered: return "checkmark.seal.fill"
        case .closed:   return "lock.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("№\(ticket.number)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon).font(.system(size: 9, weight: .semibold))
                        Text(ticket.status.displayName)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor.opacity(0.14), in: Capsule())
                    .overlay(Capsule().strokeBorder(statusColor.opacity(0.3), lineWidth: 0.5))
                    Spacer(minLength: 4)
                    Text(ticket.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(fg.opacity(0.35))
                }

                Text(ticket.message)
                    .font(.system(size: 14))
                    .foregroundStyle(fg.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let reply = ticket.adminReply, !reply.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(accent)
                        Text("Есть ответ от команды Nexus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(accent)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(fg.opacity(0.3))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(solidCardBg, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke, lineWidth: 0.5))
    }
}

// MARK: - Ticket Detail View (чат с администратором)
//
// Вид чата: сверху — шапка (№N, статус, дата); в центре — прокручиваемая
// переписка: сообщение пользователя справа синим bubble'ом, ответ администратора
// слева серым bubble'ом с маленькой аватаркой «Nexus». Снизу — действия
// (Закрыть / Открыть заново / Удалить).
//
// Сейчас модель FeedbackTicket хранит только один user message + один
// adminReply — так что чат по сути двухсообщенческий. Когда бэкенд поддержит
// треды, здесь появится `[FeedbackMessage]`-массив без изменения API вью.

fileprivate struct TicketDetailView: View {
    let ticketId: String
    let fg: Color
    let stroke: Color
    let accent: Color
    let solidCardBg: Color
    let solidInputBg: Color
    let onClose: () -> Void
    let onReopen: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var cs
    @Environment(\.dismiss) private var dismiss

    @State private var ticket: FeedbackTicket?
    @State private var confirmDelete = false
    @State private var replyText = ""
    @State private var isSendingReply = false

    // MARK: Attachment state
    /// Список выбранных в PhotosPicker элементов (множественный выбор).
    @State private var pickedPhotoItems: [PhotosPickerItem] = []
    /// Финальные вложения, готовые к отправке (фото или файл, можно листать,
    /// тапать → preview).
    @State private var attachments: [PendingAttachment] = []
    /// Раскрывает confirmation-dialog «Фото / Файл».
    @State private var showAttachOptions = false
    /// Триггер для PhotosPicker.
    @State private var showPhotoPicker = false
    /// Триггер для системного file-importer (любой документ).
    @State private var showFileImporter = false
    /// Текущее вложение, открытое в полноэкранном preview.
    @State private var previewAttachment: PendingAttachment?

    private var statusColor: Color {
        guard let t = ticket else { return .gray }
        switch t.status {
        case .open:     return .orange
        case .answered: return .green
        case .closed:   return Color(white: 0.5)
        }
    }

    private var statusText: String {
        guard let t = ticket else { return "" }
        return t.status == .closed ? "Закрыто" : "Открыто"
    }

    /// Базовый solid-цвет фона чата. Используется И в `detailBackground`
    /// (как нижний слой), И как «floor» под bottom bar'ом — чтобы glass
    /// у bar'а всегда видел один и тот же backdrop.
    private var detailBgColor: Color {
        cs == .dark
            ? Color(red: 0.07, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.97, blue: 0.99)
    }

    /// Фон чата обращения. SOLID dark surface — match'ит то, что
    /// пользователь видит при поднятой клавиатуре (когда parent-Settings
    /// перекрыт клавой и сквозь sheet ничего не просвечивает). Blur и
    /// «уход» сообщений за края делаются ОТДЕЛЬНЫМИ слоями
    /// (.ultraThinMaterial strip-ы + natural nav-bar glass).
    private var detailBackground: some View {
        ZStack {
            // Solid base — тот же `detailBgColor`, что используется как
            // floor под bottom bar'ом. Один источник истины.
            detailBgColor

            LinearGradient(
                colors: cs == .dark
                    ? [
                        Color(red: 0.09, green: 0.10, blue: 0.13),
                        Color(red: 0.06, green: 0.07, blue: 0.10)
                    ]
                    : [
                        Color(red: 0.94, green: 0.96, blue: 0.99),
                        Color(red: 0.90, green: 0.93, blue: 0.97)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [accent.opacity(cs == .dark ? 0.22 : 0.12), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 260
            )

            RadialGradient(
                colors: [Color.white.opacity(cs == .dark ? 0.06 : 0.12), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 280
            )
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            detailBackground
                .ignoresSafeArea()

            if let t = ticket {
                let messages = threadMessages(for: t)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            if shouldShowSeparator(before: message, at: index, in: messages) {
                                dateSeparator(message.createdAt)
                            }

                            if message.fromAdmin {
                                adminBubble(message.text, at: message.createdAt)
                            } else {
                                userBubble(message.text, at: message.createdAt)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    // Запас снизу под bottomBar (composer ~80-140 + чипы ~48
                    // + paddings 12·2 + safe area). Выставлен с запасом, чтобы
                    // последние сообщения не «прилипали» к bar'у при скролле.
                    .padding(.bottom, 230)
                }
                // Дроп-клавиатуры по interactive-скроллу (тянешь вниз → прячется).
                .scrollDismissesKeyboard(.interactively)
                // Плавный alpha-fade нижнего края сообщений. Ничего не
                // красит — просто делает пиксели прозрачными → сквозь них
                // видно нативный detailBackground (со всеми градиентами).
                // Никакого «просто серого» под bar'ом.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.00),
                            .init(color: .black, location: 0.70),
                            .init(color: .clear, location: 0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Тап по пустой области чата → клавиатура уходит, sheet
                // возвращается к своему детенту. Не ломает скролл — это
                // simultaneous gesture.
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                )

                // Floating bottom bar — без strip'а сверху и без floor'а
                // снизу. Лежит прямо над натуральным detailBackground
                // (градиенты + accent radial'ы), стекло сэмплит их.
                bottomBar(t)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                ProgressView().tint(fg.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Тот же паттерн, что closeButton в ProfileView: голый Image
                // в нативном toolbar-Button → iOS сам рисует glass-капсулу,
                // тап-таргет 44pt и press-feedback. Просто стрелка вместо ×.
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(cs == .dark ? .white : .black)
                }
                .buttonStyle(ToolbarCloseStyle())
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Обращение \(ticket.map { "№\($0.number)" } ?? "")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(fg)
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(statusColor)
                }
            }
        }
        // Не скрываем background nav-bar'а — нативный iOS 26 glass даёт
        // тот самый блюр, что на экране Settings: контент скроллится под
        // капсулой кнопок и плавно размывается, без резкого обрезания.
        .task { await loadTicket() }
        .alert("Удалить обращение?", isPresented: $confirmDelete) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Удалённое обращение нельзя будет восстановить.")
        }
        // Меню «Фото или видео / Файл» теперь привязано к самой скрепке
        // (нативный Menu — поп-ап рисуется ровно над кнопкой, не из края
        // экрана). См. реализацию attachChip.
        // PhotosPicker — множественный выбор; PhotosPickerItem'ы превращаем
        // в PendingAttachment c data + расширением.
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickedPhotoItems,
            maxSelectionCount: 5,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: pickedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await ingestPhotos(newItems) }
        }
        // Системный file-importer — любой документ.
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                ingestFiles(urls)
            case .failure:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        // Полноэкранный preview одного вложения по тапу на чип.
        .sheet(item: $previewAttachment) { item in
            AttachmentPreviewSheet(item: item)
        }
    }

    // MARK: - Attachment ingestion

    /// Вытягивает Data из выбранных PhotosPickerItem'ов и добавляет каждое
    /// фото/видео в `attachments`. Запуск в Task, чтобы не блокировать UI.
    private func ingestPhotos(_ items: [PhotosPickerItem]) async {
        var newOnes: [PendingAttachment] = []
        for item in items {
            let typeLabel = item.supportedContentTypes.first?.preferredFilenameExtension?.uppercased()
                ?? "FILE"
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            let data = try? await item.loadTransferable(type: Data.self)
            let kind: PendingAttachment.Kind = isVideo ? .file : .photo
            let baseName = isVideo ? "Видео" : "Фото"
            newOnes.append(PendingAttachment(
                kind: kind,
                name: "\(baseName) (\(typeLabel))",
                typeLabel: typeLabel,
                data: data,
                fileURL: nil
            ))
        }
        await MainActor.run {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                attachments.append(contentsOf: newOnes)
            }
            pickedPhotoItems = []
        }
    }

    /// Импортирует выбранные через .fileImporter URL'ы. Безопасно открываем
    /// security-scoped resource → читаем bytes (для preview / в будущем —
    /// для отправки) → закрываем.
    private func ingestFiles(_ urls: [URL]) {
        var newOnes: [PendingAttachment] = []
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            let typeLabel = url.pathExtension.uppercased().isEmpty
                ? "FILE" : url.pathExtension.uppercased()
            let data = try? Data(contentsOf: url)
            // Копируем во временную директорию, чтобы preview мог открыть
            // файл даже после закрытия security-scope'а.
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
            if let data { try? data.write(to: tmp) }
            newOnes.append(PendingAttachment(
                kind: .file,
                name: url.lastPathComponent,
                typeLabel: typeLabel,
                data: data,
                fileURL: (data != nil) ? tmp : url
            ))
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            attachments.append(contentsOf: newOnes)
        }
    }

    // MARK: - Subviews
    private func statusIconFor(_ t: FeedbackTicket) -> String {
        switch t.status {
        case .open:     return "clock.fill"
        case .answered: return "checkmark.seal.fill"
        case .closed:   return "lock.fill"
        }
    }

    private func dateSeparator(_ date: Date) -> some View {
        HStack {
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(fg.opacity(0.4))
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(solidCardBg, in: Capsule())
                .overlay(Capsule().strokeBorder(stroke, lineWidth: 0.5))
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func userBubble(_ text: String, at date: Date) -> some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 4) {
                Text("Вы")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.48, blue: 1.0),
                                     Color(red: 0.0, green: 0.62, blue: 1.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(fg.opacity(0.35))
                    .padding(.trailing, 6)
            }
        }
    }

    private func adminBubble(_ text: String, at date: Date) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            adminAvatar(size: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ответ поддержки")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent.opacity(0.92))
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(fg)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(solidInputBg, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke, lineWidth: 0.5))
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(fg.opacity(0.35))
                    .padding(.leading, 6)
            }
            Spacer(minLength: 40)
        }
    }

    private func adminAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0),
                             Color(red: 0.0, green: 0.90, blue: 1.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    /// Нижняя панель: ряд прикреплённых файлов (если есть) → input → ряд
    /// чипов «Закрыть · Скрепка · Удалить». Фон — супер-прозрачный liquid
    /// glass (iOS 26 `.glassEffect`) с тинт-подложкой для стабильности.
    private func bottomBar(_ t: FeedbackTicket) -> some View {
        // Оборачиваем в GlassEffectContainer — это нативный iOS 26 контейнер,
        // в котором .glassEffect рендерится корректно вне зависимости от
        // того, что лежит ПОД view (клавиатура / scroll-content / просто фон).
        // Без compositingGroup: он флэтит контент в offscreen-буфер до того,
        // как наносится refraction, и стекло превращается в блюр. Внутри
        // контейнера glass всегда сэмплит реальный pixel-stream под собой.
        GlassEffectContainer {
            VStack(spacing: 10) {
                // Горизонтальная лента вложений: каждый элемент тапабельный →
                // открывает полноэкранный preview.
                if !attachments.isEmpty {
                    attachmentsRow
                }

                replyComposer(isClosed: t.status == .closed)

                HStack(spacing: 8) {
                    if t.status == .closed {
                        actionChip(label: "Открыть заново", icon: "arrow.counterclockwise",
                                   color: accent) {
                            onReopen()
                            Task { await loadTicket() }
                        }
                    } else {
                        actionChip(label: "Закрыть", icon: "lock.fill",
                                   color: Color(white: 0.5)) {
                            onClose()
                            Task { await loadTicket() }
                        }
                    }

                    // Скрепка-чип СРАЗУ за «Закрыть» / «Открыть заново».
                    attachChip(isClosed: t.status == .closed)

                    Spacer()
                    actionChip(label: "Удалить", icon: "trash",
                               color: .red) { confirmDelete = true }
                }
            }
            .padding(12)
            // Один-единственный нативный liquid-glass слой. Тинт почти
            // нулевой — пусть iOS сам решает, как отрефлектить то, что
            // под bar'ом (chat-content / клавиатура / sheet-фон).
            .glassEffect(
                .regular.tint(
                    cs == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.10)
                ),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.white.opacity(cs == .dark ? 0.10 : 0.20),
                                  lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(cs == .dark ? 0.18 : 0.06),
                    radius: 10, y: 4)
        }
    }

    /// Горизонтальная лента превью прикреплённых файлов. Каждый item —
    /// тапабельный (открывает full-screen preview), на нём крестик для
    /// удаления из очереди до отправки.
    private var attachmentsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { item in
                    attachmentChip(item)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 64)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    /// Один чип-превью. Для фото показывает миниатюру, для файла —
    /// крупную иконку + расширение в углу.
    @ViewBuilder
    private func attachmentChip(_ item: PendingAttachment) -> some View {
        Button {
            previewAttachment = item
        } label: {
            ZStack(alignment: .topTrailing) {
                Group {
                    if item.kind == .photo,
                       let data = item.data,
                       let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable().scaledToFill()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [accent.opacity(0.40), accent.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            VStack(spacing: 3) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(item.typeLabel)
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(stroke, lineWidth: 0.5)
                )

                // Крестик «убрать из очереди»
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        attachments.removeAll { $0.id == item.id }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.black.opacity(0.65), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
        .buttonStyle(.plain)
    }

    /// Чип-кнопка «скрепка» в нижнем ряду. Тап → confirmation-dialog
    /// «Фото или видео» / «Файл», нужный пикер открывается дальше.
    private func attachChip(isClosed: Bool) -> some View {
        // Menu вместо confirmationDialog — поп-ап рисуется ровно над кнопкой
        // (как нативное контекстное меню), а не из нижнего края экрана.
        // Без primaryAction — обычный тап сразу раскрывает меню.
        Menu {
            Button {
                pickedPhotoItems = []
                showPhotoPicker = true
            } label: {
                Label("Фото или видео", systemImage: "photo.on.rectangle")
            }
            Button {
                showFileImporter = true
            } label: {
                Label("Файл", systemImage: "doc")
            }
        } label: {
            // Только иконка-скрепка (без текста). По высоте совпадает с
            // соседними actionChip-капсулами (~32pt visually).
            Image(systemName: "paperclip")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.12), in: Circle())
                .overlay(Circle().strokeBorder(accent.opacity(0.25), lineWidth: 0.5))
                // Тап по всему кругу, а не только по пиксельной форме скрепки.
                .contentShape(Circle())
        }
        .menuOrder(.fixed)
        .disabled(isClosed)
        .opacity(isClosed ? 0.45 : 1)
    }

    /// Composer: только поле ввода + send-кнопка. Скрепка теперь — отдельный
    /// чип в нижнем ряду рядом с «Закрыть/Открыть заново», а не внутри
    /// инпута. Высота поля увеличена (min 80, max 140) — комфортнее для
    /// длинных сообщений.
    private func replyComposer(isClosed: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .topLeading) {
                if replyText.isEmpty {
                    Text(isClosed ? "Обращение закрыто" : "Написать сообщение...")
                        .font(.system(size: 15))
                        .foregroundStyle(fg.opacity(0.35))
                        .padding(.horizontal, 14)
                        .padding(.top, 13)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $replyText)
                    .font(.system(size: 15))
                    .foregroundStyle(fg)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .padding(.trailing, 44)
                    .frame(minHeight: 80, maxHeight: 140)
                    .disabled(isClosed || isSendingReply)
                    .opacity(isClosed ? 0.6 : 1)
            }
            .background(solidInputBg, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke, lineWidth: 0.5))
            .frame(maxWidth: .infinity)

            Button {
                Task { await sendReply() }
            } label: {
                ZStack {
                    Circle()
                        .fill(isClosed || (trimmedReplyText.isEmpty && attachments.isEmpty)
                              ? Color.gray.opacity(0.18) : accent)
                        .frame(width: 32, height: 32)

                    if isSendingReply {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isClosed || isSendingReply ||
                      (trimmedReplyText.isEmpty && attachments.isEmpty))
            .opacity(isClosed ? 0.6 : 1)
            .padding(.trailing, 12)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func actionChip(label: String, icon: String,
                            color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(color.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 0.5))
            // Делает тапабельной всю капсулу, а не только пиксели иконки/текста.
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func loadTicket() async {
        guard let uid = appState.userProfile?.id else { return }
        let all = (try? await FeedbackRepository.shared.fetchTickets(userId: uid)) ?? []
        if let t = all.first(where: { $0.id == ticketId }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                ticket = t
            }
        }
    }

    private var trimmedReplyText: String {
        replyText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendReply() async {
        guard let currentTicket = ticket else { return }
        let text = trimmedReplyText
        let hasAttachments = !attachments.isEmpty
        // Разрешаем отправку либо с текстом, либо если есть хоть один файл.
        guard !text.isEmpty || hasAttachments else { return }

        isSendingReply = true
        defer { isSendingReply = false }

        // Сейчас бэкенд не принимает файлы — кладём в текст список вложений
        // как заглушку. Когда n8n-вебхук научится файлам, сюда подключим
        // multipart-upload. UI готов: attachments.kind/name/data/fileURL.
        //
        // Формат: ОДНА скрепка + label («Вложение»/«Вложения») + имена файлов.
        // Без второй скрепки в начале строки, чтобы в чате не было двух
        // эмодзи подряд.
        let payloadText: String = {
            if attachments.isEmpty { return text }
            let names = attachments.map { $0.name }.joined(separator: ", ")
            let label = attachments.count == 1 ? "Вложение" : "Вложения"
            let attachLine = "📎 \(label): \(names)"
            return text.isEmpty ? attachLine : "\(text)\n\(attachLine)"
        }()

        do {
            try await FeedbackRepository.shared.appendMessage(
                ticketId: currentTicket.id,
                message: FeedbackMessage(text: payloadText, fromAdmin: false)
            )
            replyText = ""
            attachments = []
            pickedPhotoItems = []
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            await loadTicket()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func threadMessages(for ticket: FeedbackTicket) -> [FeedbackMessage] {
        var items = [
            FeedbackMessage(
                id: "root-\(ticket.id)",
                text: ticket.message,
                fromAdmin: false,
                createdAt: ticket.createdAt
            )
        ]

        items.append(contentsOf: ticket.messages)

        if let adminReply = ticket.adminReply, !adminReply.isEmpty {
            let alreadyIncluded = ticket.messages.contains {
                $0.fromAdmin && $0.text == adminReply
            }
            if !alreadyIncluded {
                items.append(
                    FeedbackMessage(
                        id: "legacy-admin-\(ticket.id)",
                        text: adminReply,
                        fromAdmin: true,
                        createdAt: ticket.repliedAt ?? ticket.createdAt
                    )
                )
            }
        }

        return items.sorted { $0.createdAt < $1.createdAt }
    }

    private func shouldShowSeparator(
        before message: FeedbackMessage,
        at index: Int,
        in messages: [FeedbackMessage]
    ) -> Bool {
        guard index > 0 else { return true }
        let previous = messages[index - 1]
        return !Calendar.current.isDate(previous.createdAt, inSameDayAs: message.createdAt)
    }
}

// MARK: - Pending Attachment Model
//
// Локальная модель файла-в-очереди (ещё не отправлен серверу). Хранит либо
// data (для фото из PhotosPicker), либо fileURL (для документов из
// .fileImporter, скопированных в tmp). Сейчас бэкенд не принимает файлы —
// вложения уходят как текст-плейсхолдер; модель готова к будущему upload'у.

fileprivate struct PendingAttachment: Identifiable, Equatable {
    enum Kind: String, Equatable { case photo, file }
    let id: UUID = UUID()
    let kind: Kind
    let name: String
    let typeLabel: String
    let data: Data?
    let fileURL: URL?
}

// MARK: - Attachment Preview Sheet
//
// Полноэкранный preview одного вложения. Для фото — Image с pinch-to-zoom
// (через scaleEffect + magnificationGesture); для файла — крупная иконка,
// расширение, размер и кнопка «Открыть в…» (UIDocumentInteractionController
// через ShareLink).

fileprivate struct AttachmentPreviewSheet: View {
    let item: PendingAttachment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var zoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0

    private var fg: Color { cs == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.14) }

    var body: some View {
        NavigationStack {
            ZStack {
                (cs == .dark ? Color.black : Color(white: 0.97))
                    .ignoresSafeArea()

                if item.kind == .photo, let data = item.data, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoom)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoom = max(1, min(5, lastZoom * value))
                                }
                                .onEnded { _ in lastZoom = zoom }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                zoom = zoom > 1 ? 1 : 2.5
                                lastZoom = zoom
                            }
                        }
                        .padding()
                } else {
                    fileInfoView
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(fg)
                    }
                }
                if let fileURL = item.fileURL {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: fileURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
        }
    }

    private var fileInfoView: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.48, blue: 1.0),
                                Color(red: 0.0, green: 0.90, blue: 1.0)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 170)
                VStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(.white)
                    Text(item.typeLabel)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            Text(item.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(fg)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let bytes = item.data?.count {
                Text(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))
                    .font(.system(size: 13))
                    .foregroundStyle(fg.opacity(0.5))
            }
        }
        .padding()
    }
}

// MARK: - Online Dot (pulsing, noticeably)
//
// Два пульсирующих слоя: расширяющийся ореол (scale 1 → 2.4, opacity 0.6 → 0)
// + центральный кружок, который синхронно мерцает по яркости (1.0 → 0.55).
// Период 1.2 с, циклично — чтобы «онлайн» бросалось в глаза.

private struct OnlineDot: View {
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.7
    @State private var coreBright: Bool = true

    var body: some View {
        ZStack {
            // Внешний расширяющийся ореол — он делает пульсацию явной.
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Центральный кружок + свечение по яркости. Без белого блика —
            // пользователь попросил убрать мельчайший светлый подсвет.
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .opacity(coreBright ? 1.0 : 0.55)
                .shadow(color: Color.green.opacity(coreBright ? 0.45 : 0.12),
                        radius: coreBright ? 2.5 : 0.8)
        }
        .frame(width: 10, height: 10)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                ringScale = 2.4
                ringOpacity = 0
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                coreBright = false
            }
        }
    }
}
