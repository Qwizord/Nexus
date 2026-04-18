import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore

// MARK: - Firebase Learning Repository

final class FirebaseLearningRepository: LearningRepository {

    private let db = Firestore.firestore()

    private func col(userId: String) -> CollectionReference {
        db.collection("learning").document(userId).collection("courses")
    }

    // MARK: - Fetch

    func fetchCourses(userId: String) async throws -> [Course] {
        let snapshot = try await col(userId: userId)
            .order(by: "title")
            .getDocuments()
        return snapshot.documents.compactMap { CourseMapper.from($0) }
    }

    // MARK: - Save

    func saveCourse(_ course: Course, userId: String) async throws {
        try await col(userId: userId)
            .document(course.id)
            .setData(CourseMapper.toFirestore(course), merge: true)
    }

    // MARK: - Update Progress

    func updateProgress(courseId: String, completedLessons: Int, userId: String) async throws {
        try await col(userId: userId).document(courseId).updateData([
            "completedLessons": completedLessons
        ])
    }

    // MARK: - Delete

    func deleteCourse(id: String, userId: String) async throws {
        try await col(userId: userId).document(id).delete()
    }
}

// MARK: - Mapper

private enum CourseMapper {

    static func from(_ doc: QueryDocumentSnapshot) -> Course? {
        let data = doc.data()
        guard
            let title      = data["title"]      as? String,
            let category   = data["category"]   as? String,
            let total      = data["totalLessons"] as? Int
        else { return nil }

        let course = Course(title: title, category: category, totalLessons: total)
        course.id               = doc.documentID
        course.completedLessons = data["completedLessons"] as? Int ?? 0
        course.status           = data["status"] as? String ?? LearningStatus.notStarted.rawValue
        course.notes            = data["notes"] as? String ?? ""

        if let ts = data["startDate"] as? Timestamp  { course.startDate  = ts.dateValue() }
        if let ts = data["targetDate"] as? Timestamp { course.targetDate = ts.dateValue() }

        return course
    }

    static func toFirestore(_ course: Course) -> [String: Any] {
        var data: [String: Any] = [
            "title":            course.title,
            "category":         course.category,
            "totalLessons":     course.totalLessons,
            "completedLessons": course.completedLessons,
            "status":           course.status,
            "notes":            course.notes
        ]
        if let start  = course.startDate  { data["startDate"]  = Timestamp(date: start)  }
        if let target = course.targetDate { data["targetDate"] = Timestamp(date: target) }
        return data
    }
}

#else

// MARK: - Stub (no Firebase)

final class FirebaseLearningRepository: LearningRepository {
    func fetchCourses(userId: String) async throws -> [Course] { [] }
    func saveCourse(_ course: Course, userId: String) async throws {}
    func updateProgress(courseId: String, completedLessons: Int, userId: String) async throws {}
    func deleteCourse(id: String, userId: String) async throws {}
}

#endif
