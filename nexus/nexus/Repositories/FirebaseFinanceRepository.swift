import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore

// MARK: - Firebase Finance Repository

final class FirebaseFinanceRepository: FinanceRepository {

    private let db = Firestore.firestore()

    private func col(userId: String) -> CollectionReference {
        db.collection("finance").document(userId).collection("transactions")
    }

    // MARK: - Fetch

    func fetchTransactions(userId: String, month: String?) async throws -> [Transaction] {
        var query: Query = col(userId: userId)
            .order(by: "date", descending: true)
            .limit(to: 500)

        // month format expected: "YYYY-MM" — filter by stored monthKey field
        if let month {
            query = col(userId: userId)
                .whereField("monthKey", isEqualTo: month)
                .order(by: "date", descending: true)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { TransactionMapper.from($0) }
    }

    // MARK: - Save

    func saveTransaction(_ transaction: Transaction, userId: String) async throws {
        let ref = col(userId: userId).document(transaction.id)
        try await ref.setData(TransactionMapper.toFirestore(transaction), merge: true)
    }

    // MARK: - Delete

    func deleteTransaction(id: String, userId: String) async throws {
        try await col(userId: userId).document(id).delete()
    }

    // MARK: - Balance

    func fetchBalance(userId: String) async throws -> Double {
        let txs = try await fetchTransactions(userId: userId, month: nil)
        let income   = txs.filter { $0.type == TransactionType.income.rawValue  }.reduce(0) { $0 + $1.amount }
        let expenses = txs.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
        return income - expenses
    }
}

// MARK: - Mapper

private enum TransactionMapper {

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func from(_ doc: QueryDocumentSnapshot) -> Transaction? {
        let data = doc.data()
        guard
            let title    = data["title"]    as? String,
            let amount   = data["amount"]   as? Double,
            let typeStr  = data["type"]     as? String,
            let catStr   = data["category"] as? String
        else { return nil }

        let txType = typeStr == TransactionType.income.rawValue ? TransactionType.income : .expense
        let cat    = FinanceCategory(rawValue: catStr) ?? .other

        let tx = Transaction(title: title, amount: amount, type: txType, category: cat)
        tx.id         = doc.documentID
        tx.note       = data["note"]       as? String ?? ""
        tx.isBusiness = data["isBusiness"] as? Bool   ?? false

        if let ts = data["date"] as? Timestamp {
            tx.date = ts.dateValue()
        } else if let s = data["date"] as? String, let d = isoFormatter.date(from: s) {
            tx.date = d
        }

        return tx
    }

    /// Returns a Firestore-ready dictionary for the given Transaction.
    static func toFirestore(_ tx: Transaction) -> [String: Any] {
        let calendar   = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: tx.date)
        let monthKey   = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)

        return [
            "title":      tx.title,
            "amount":     tx.amount,
            "type":       tx.type,
            "category":   tx.category,
            "note":       tx.note,
            "isBusiness": tx.isBusiness,
            "date":       Timestamp(date: tx.date),
            "monthKey":   monthKey
        ]
    }
}

#else

// MARK: - Stub (no Firebase)

final class FirebaseFinanceRepository: FinanceRepository {
    func fetchTransactions(userId: String, month: String?) async throws -> [Transaction] { [] }
    func saveTransaction(_ transaction: Transaction, userId: String) async throws {}
    func deleteTransaction(id: String, userId: String) async throws {}
    func fetchBalance(userId: String) async throws -> Double { 0 }
}

#endif
