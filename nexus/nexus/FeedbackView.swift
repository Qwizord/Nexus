import SwiftUI

// MARK: - Feedback View (Sheet)

struct FeedbackView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var tickets: [FeedbackTicket] = []
    @State private var isLoading = false
    @State private var showNewTicket = false
    @State private var newMessage = ""
    @State private var isSending = false
    @State private var sendError: String?
    @State private var sendSuccess = false

    private var userId: String? { appState.userProfile?.id }
    private var userName: String { appState.userProfile?.fullName ?? "Пользователь" }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
            VStack(spacing: 0) {
                // Handle
                Capsule().fill(.white.opacity(0.15)).frame(width: 36, height: 4).padding(.top, 12)

                // Header
                HStack {
                    Text("Обратная связь")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showNewTicket.toggle()
                    } label: {
                        Image(systemName: showNewTicket ? "xmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(showNewTicket ? .white.opacity(0.4) : Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // New ticket form
                if showNewTicket {
                    newTicketForm
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider().background(.white.opacity(0.08))

                // Tickets list
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white.opacity(0.4))
                    Spacer()
                } else if tickets.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(tickets) { ticket in
                                TicketCard(ticket: ticket)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .animation(.spring(response: 0.35), value: showNewTicket)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .task { await loadTickets() }
    }

    // MARK: - New Ticket Form

    var newTicketForm: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if newMessage.isEmpty {
                    Text("Опишите проблему или предложение...")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $newMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(minHeight: 100, maxHeight: 150)
            }
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))

            if let err = sendError {
                Text(err).font(.system(size: 12)).foregroundStyle(.red.opacity(0.8))
            }
            if sendSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Обращение отправлено! Мы ответим в ближайшее время.")
                        .font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
                }
                .transition(.opacity)
            }

            Button {
                Task { await sendTicket() }
            } label: {
                Group {
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Text("Отправить обращение")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(
                    LinearGradient(colors: [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.9)],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(isSending || newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.15))
            Text("Нет обращений")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
            Text("Нажми + чтобы написать нам")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.25))
            Spacer()
        }
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
            tickets.insert(ticket, at: 0)
            newMessage = ""
            sendSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                sendSuccess = false
                showNewTicket = false
            }
        } catch {
            sendError = error.localizedDescription
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

    var statusColor: Color {
        switch ticket.status {
        case .open:     return .orange
        case .answered: return .green
        case .closed:   return Color(white: 0.5)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 8) {
                Text("#\(String(ticket.id.prefix(6)).uppercased())")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text(ticket.status.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor.opacity(0.15), in: Capsule())
                Text(ticket.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.25))
            }

            // User message
            VStack(alignment: .leading, spacing: 4) {
                Text("Ваше обращение")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
                Text(ticket.message)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Admin reply
            if let reply = ticket.adminReply, !reply.isEmpty {
                Divider().background(.white.opacity(0.07))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.4, green: 0.6, blue: 1.0))
                        Text("Ответ команды Nexus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(red: 0.4, green: 0.6, blue: 1.0))
                        if let at = ticket.repliedAt {
                            Spacer()
                            Text(at.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                    }
                    Text(reply)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.2), lineWidth: 0.5))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.07), lineWidth: 0.5))
    }
}
