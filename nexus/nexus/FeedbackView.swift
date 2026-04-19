import SwiftUI

// MARK: - Feedback View (Support Screen)
//
// Screen (presented как `.sheet`) со списком тикетов и формой нового обращения.
// Полностью адаптивный (light/dark), использует accent-gradient и glass cards
// — визуально один к одному с остальными шагами Settings.

struct FeedbackView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs

    @State private var tickets: [FeedbackTicket] = []
    @State private var isLoading = false
    @State private var showNewTicket = false
    @State private var newMessage = ""
    @State private var isSending = false
    @State private var sendError: String?
    @State private var sendSuccess = false

    // MARK: Design tokens (локальные, чтобы не зависеть от приватного SettingsView.DS)
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
    private var bg: Color { cs == .dark ? .black : .white }
    private var stroke: Color {
        cs == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    private var userId: String? { appState.userProfile?.id }
    private var userName: String { appState.userProfile?.fullName ?? "Пользователь" }

    private var openCount: Int { tickets.filter { $0.status == .open }.count }
    private var answeredCount: Int { tickets.filter { $0.status == .answered }.count }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerCard
                        if showNewTicket { newTicketCard }
                        ticketsList
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showNewTicket)
            .navigationTitle("Поддержка")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                        .foregroundStyle(fg.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showNewTicket.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: showNewTicket ? "xmark" : "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(accentGrad, in: Circle())
                    }
                }
            }
        }
        .task { await loadTickets() }
    }

    // MARK: - Header card (summary)

    private var headerCard: some View {
        HStack(spacing: 12) {
            // Animated glowing icon
            ZStack {
                Circle().fill(accentGrad).frame(width: 46, height: 46)
                    .blur(radius: 8).opacity(0.35)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(accentGrad, in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Команда Nexus рядом")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(fg)
                Text(summaryText)
                    .font(.system(size: 12))
                    .foregroundStyle(fg.opacity(0.45))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 0.5))
    }

    private var summaryText: String {
        if tickets.isEmpty { return "Опиши проблему или идею — ответим в течение 24 ч." }
        if openCount > 0 {
            return "Открытых обращений: \(openCount). Мы уже их разбираем."
        }
        if answeredCount > 0 {
            return "Всего обращений: \(tickets.count). Все получили ответ."
        }
        return "Всего обращений: \(tickets.count)."
    }

    // MARK: - New ticket card

    private var newTicketCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Новое обращение")
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.5)
                .foregroundStyle(fg.opacity(0.45))
                .textCase(.uppercase)

            ZStack(alignment: .topLeading) {
                if newMessage.isEmpty {
                    Text("Опиши проблему или предложение…")
                        .font(.system(size: 14))
                        .foregroundStyle(fg.opacity(0.3))
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
            .background(fg.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(stroke, lineWidth: 0.5))

            if let err = sendError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.85))
                    .transition(.opacity)
            }
            if sendSuccess {
                Label("Обращение отправлено! Мы ответим в ближайшее время.",
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
            }
            .buttonStyle(.plain)
            .disabled(isSending || newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 0.5))
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
                .frame(height: 160)
        } else if tickets.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Мои обращения")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.5)
                    .foregroundStyle(fg.opacity(0.45))
                    .textCase(.uppercase)
                    .padding(.leading, 4)
                LazyVStack(spacing: 10) {
                    ForEach(tickets) { ticket in
                        TicketCard(ticket: ticket, fg: fg, stroke: stroke, accent: accent1)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(accentGrad.opacity(0.18)).frame(width: 88, height: 88)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(accent1)
            }
            Text("Нет обращений")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(fg.opacity(0.75))
            Text("Нажми «+» в верхнем углу, чтобы написать нам")
                .font(.system(size: 13))
                .foregroundStyle(fg.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 0.5))
    }

    // MARK: - Actions

    private func loadTickets() async {
        guard let uid = userId else { return }
        isLoading = true
        defer { isLoading = false }
        tickets = (try? await FeedbackRepository.shared.fetchTickets(userId: uid)) ?? []
    }

    private func sendTicket() async {
        guard let uid = userId else { return }
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        sendError = nil
        defer { isSending = false }

        let ticket = FeedbackTicket(userId: uid, userName: userName, message: trimmed)
        do {
            try await FeedbackRepository.shared.submit(ticket: ticket)
            await sendEmailNotification(ticket: ticket)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tickets.insert(ticket, at: 0)
            }
            newMessage = ""
            withAnimation { sendSuccess = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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

    /// Уведомляет на почту qwizord@icloud.com через n8n webhook
    private func sendEmailNotification(ticket: FeedbackTicket) async {
        let urlString = "https://YOUR_N8N_DOMAIN/webhook/feedback"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "ticketId": ticket.id,
            "userId": ticket.userId,
            "userName": ticket.userName,
            "message": ticket.message,
            "createdAt": ISO8601DateFormatter().string(from: ticket.createdAt),
            "to": "qwizord@icloud.com"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
}

// MARK: - Ticket Card

private struct TicketCard: View {
    let ticket: FeedbackTicket
    let fg: Color
    let stroke: Color
    let accent: Color

    var statusColor: Color {
        switch ticket.status {
        case .open:     return .orange
        case .answered: return .green
        case .closed:   return Color(white: 0.5)
        }
    }

    var statusIcon: String {
        switch ticket.status {
        case .open:     return "clock.fill"
        case .answered: return "checkmark.seal.fill"
        case .closed:   return "lock.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 8) {
                Text("#\(String(ticket.id.prefix(6)).uppercased())")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(fg.opacity(0.35))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: statusIcon).font(.system(size: 9, weight: .semibold))
                    Text(ticket.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(statusColor.opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(statusColor.opacity(0.3), lineWidth: 0.5))

                Text(ticket.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(fg.opacity(0.35))
            }

            // User message
            VStack(alignment: .leading, spacing: 4) {
                Text("Твоё обращение")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(0.3)
                    .textCase(.uppercase)
                    .foregroundStyle(fg.opacity(0.35))
                Text(ticket.message)
                    .font(.system(size: 14))
                    .foregroundStyle(fg.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Admin reply
            if let reply = ticket.adminReply, !reply.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(accent)
                        Text("Ответ команды Nexus")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accent)
                        if let at = ticket.repliedAt {
                            Spacer()
                            Text(at.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 11))
                                .foregroundStyle(fg.opacity(0.35))
                        }
                    }
                    Text(reply)
                        .font(.system(size: 14))
                        .foregroundStyle(fg.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.22), lineWidth: 0.5))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke, lineWidth: 0.5))
    }
}
