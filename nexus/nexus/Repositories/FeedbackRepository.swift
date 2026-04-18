import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Feedback Repository

final class FeedbackRepository {
    static let shared = FeedbackRepository()
    private init() {}

    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    private let iso = ISO8601DateFormatter()

    // MARK: - Submit new ticket

    func submit(ticket: FeedbackTicket) async throws {
        let data = ticketToFirestore(ticket)
        try await db.collection("feedback")
            .document(ticket.id)
            .setData(data)
    }

    // MARK: - Fetch tickets for user

    func fetchTickets(userId: String) async throws -> [FeedbackTicket] {
        let snapshot = try await db.collection("feedback")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            mapToTicket(doc.data(), id: doc.documentID)
        }
    }

    // MARK: - Serialization

    private func ticketToFirestore(_ t: FeedbackTicket) -> [String: Any] {
        var data: [String: Any] = [
            "id": t.id,
            "userId": t.userId,
            "userName": t.userName,
            "message": t.message,
            "status": t.status.rawValue,
            "createdAt": iso.string(from: t.createdAt)
        ]
        if let reply = t.adminReply { data["adminReply"] = reply }
        if let at = t.repliedAt { data["repliedAt"] = iso.string(from: at) }
        return data
    }

    private func mapToTicket(_ data: [String: Any], id: String) -> FeedbackTicket? {
        guard let userId = data["userId"] as? String,
              let message = data["message"] as? String else { return nil }
        var ticket = FeedbackTicket(
            id: id,
            userId: userId,
            userName: data["userName"] as? String ?? "",
            message: message
        )
        if let s = data["status"] as? String {
            ticket.status = FeedbackStatus(rawValue: s) ?? .open
        }
        if let dateStr = data["createdAt"] as? String {
            ticket.createdAt = ISO8601DateFormatter().date(from: dateStr) ?? Date()
        }
        ticket.adminReply = data["adminReply"] as? String
        if let replyStr = data["repliedAt"] as? String {
            ticket.repliedAt = ISO8601DateFormatter().date(from: replyStr)
        }
        return ticket
    }
    #else
    func submit(ticket: FeedbackTicket) async throws {}
    func fetchTickets(userId: String) async throws -> [FeedbackTicket] { [] }
    #endif
}
