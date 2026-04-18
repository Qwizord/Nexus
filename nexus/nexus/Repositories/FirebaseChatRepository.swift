import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Firebase Chat Repository

class FirebaseChatRepository: ChatRepository {
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif

    // MARK: - Sessions

    func fetchSessions(userId: String) async throws -> [ChatSession] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await db.collection("chat").document(userId).collection("sessions")
            .order(by: "updatedAt", descending: true)
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { mapToSession($0) }
        #else
        throw RepositoryError.fetchFailed("Firebase not available")
        #endif
    }

    func createSession(_ session: ChatSession, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let data: [String: Any] = [
            "title": session.title,
            "lastMessage": session.lastMessage,
            "createdAt": ISO8601DateFormatter().string(from: session.date),
            "updatedAt": ISO8601DateFormatter().string(from: session.date)
        ]
        try await db.collection("chat").document(userId).collection("sessions")
            .document(session.id).setData(data)
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    func deleteSession(id: String, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        try await db.collection("chat").document(userId).collection("sessions")
            .document(id).delete()
        #else
        throw RepositoryError.deleteFailed("Firebase not available")
        #endif
    }

    func clearAllSessions(userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let snapshot = try await db.collection("chat").document(userId).collection("sessions")
            .getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        #else
        throw RepositoryError.deleteFailed("Firebase not available")
        #endif
    }

    // MARK: - Messages

    func fetchMessages(sessionId: String, userId: String, limit: Int) async throws -> [ChatMessageItem] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await db.collection("chat").document(userId).collection("sessions")
            .document(sessionId).collection("messages")
            .order(by: "timestamp")
            .limit(toLast: limit)
            .getDocuments()

        return snapshot.documents.compactMap { mapToMessage($0) }
        #else
        throw RepositoryError.fetchFailed("Firebase not available")
        #endif
    }

    func saveMessage(_ message: ChatMessageItem, sessionId: String, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let data: [String: Any] = [
            "role": message.role,
            "content": message.content,
            "timestamp": ISO8601DateFormatter().string(from: message.timestamp),
            "isAgentMode": message.isAgentMode,
            "agentType": message.agentType as Any
        ]

        let batch = db.batch()

        let msgRef = db.collection("chat").document(userId).collection("sessions")
            .document(sessionId).collection("messages").document(message.id)
        batch.setData(data, forDocument: msgRef)

        let sessionRef = db.collection("chat").document(userId).collection("sessions")
            .document(sessionId)
        // merge:true — создаёт документ если его нет, обновляет поля если есть
        batch.setData([
            "lastMessage": message.content,
            "updatedAt": ISO8601DateFormatter().string(from: message.timestamp)
        ], forDocument: sessionRef, merge: true)

        try await batch.commit()
        #else
        throw RepositoryError.saveFailed("Firebase not available")
        #endif
    }

    // MARK: - Real-time Listener

    func listenToMessages(sessionId: String, userId: String) -> AsyncStream<[ChatMessageItem]> {
        AsyncStream { continuation in
            #if canImport(FirebaseFirestore)
            let listener = self.db.collection("chat").document(userId).collection("sessions")
                .document(sessionId).collection("messages")
                .order(by: "timestamp")
                .addSnapshotListener { snapshot, error in
                    guard let docs = snapshot?.documents, error == nil else { return }
                    let messages = docs.compactMap { self.mapToMessage($0) }
                    continuation.yield(messages)
                }
            continuation.onTermination = { _ in listener.remove() }
            #else
            continuation.finish()
            #endif
        }
    }

    // MARK: - Mapping

    #if canImport(FirebaseFirestore)
    private func mapToSession(_ doc: QueryDocumentSnapshot) -> ChatSession? {
        let data = doc.data()
        let date = parseDate(data["updatedAt"] as? String) ?? Date()
        return ChatSession(
            id: doc.documentID,
            title: data["title"] as? String ?? "Чат",
            lastMessage: data["lastMessage"] as? String ?? "",
            date: date,
            messages: []
        )
    }

    private func mapToMessage(_ doc: QueryDocumentSnapshot) -> ChatMessageItem? {
        let data = doc.data()
        guard let timestamp = parseDate(data["timestamp"] as? String) else { return nil }
        return ChatMessageItem(
            id: doc.documentID,
            role: data["role"] as? String ?? "user",
            content: data["content"] as? String ?? "",
            timestamp: timestamp,
            isAgentMode: data["isAgentMode"] as? Bool ?? false,
            agentType: data["agentType"] as? String
        )
    }
    #endif

    private func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
}
