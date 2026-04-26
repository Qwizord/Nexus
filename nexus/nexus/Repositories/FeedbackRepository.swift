import Foundation

// MARK: - Feedback Repository
//
// Локальное хранилище обращений в UserDefaults + монотонный счётчик номеров.
// Firestore намеренно отключён: правила безопасности Firebase ещё не прописаны,
// из-за чего продакшн падал с permission-denied. Когда бэкенд будет готов —
// здесь появится сетевой слой поверх локального кэша. А пока:
//
//   • `submit`  — сохраняет тикет в UserDefaults и присваивает ему следующий №.
//   • `fetch`   — читает все тикеты пользователя из UserDefaults.
//   • `close`   — переводит тикет в статус `.closed` (видимо, но не редактируется).
//   • `reopen`  — возвращает `.closed` тикет в `.open`.
//   • `delete`  — физически удаляет тикет из локального хранилища.
//
// Все операции отмечены `async throws` — чтобы позже можно было бесшовно
// подложить Firestore/REST без изменения вью.

final class FeedbackRepository {
    static let shared = FeedbackRepository()
    private init() {}

    private let storageKey = "nexus.feedback.tickets.v1"
    private let counterKey = "nexus.feedback.counter.v1"
    private let queue = DispatchQueue(label: "nexus.feedback.repo", qos: .userInitiated)

    // MARK: - Counter (sequential ticket numbers)

    /// Возвращает следующий номер обращения и инкрементит счётчик.
    /// Первый вызов вернёт 1.
    func nextTicketNumber() -> Int {
        queue.sync {
            let ud = UserDefaults.standard
            let next = ud.integer(forKey: counterKey) + 1
            ud.set(next, forKey: counterKey)
            return next
        }
    }

    /// Показать какой номер будет присвоен *следующему* обращению, не инкрементя
    /// счётчик. Нужно, чтобы заранее нарисовать «Обращение №N» в форме до того,
    /// как пользователь реально нажал «Отправить».
    func peekNextTicketNumber() -> Int {
        UserDefaults.standard.integer(forKey: counterKey) + 1
    }

    // MARK: - Read

    func fetchTickets(userId: String) async throws -> [FeedbackTicket] {
        loadAll()
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Write

    func submit(ticket: FeedbackTicket) async throws {
        var all = loadAll()
        all.append(ticket)
        saveAll(all)
    }

    func closeTicket(id: String) async throws {
        var all = loadAll()
        guard let idx = all.firstIndex(where: { $0.id == id }) else { return }
        all[idx].status = .closed
        saveAll(all)
    }

    func reopenTicket(id: String) async throws {
        var all = loadAll()
        guard let idx = all.firstIndex(where: { $0.id == id }) else { return }
        all[idx].status = .open
        saveAll(all)
    }

    func deleteTicket(id: String) async throws {
        var all = loadAll()
        all.removeAll { $0.id == id }
        saveAll(all)
    }

    /// Добавляет новое сообщение в тред обращения (реплика пользователя
    /// или администратора). Используется чатом внутри TicketDetailView.
    func appendMessage(ticketId: String, message: FeedbackMessage) async throws {
        var all = loadAll()
        guard let idx = all.firstIndex(where: { $0.id == ticketId }) else { return }
        all[idx].messages.append(message)
        saveAll(all)
    }

    // MARK: - Private storage

    private func loadAll() -> [FeedbackTicket] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([FeedbackTicket].self, from: data)) ?? []
    }

    private func saveAll(_ tickets: [FeedbackTicket]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(tickets) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
