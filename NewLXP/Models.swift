import Foundation
import SwiftUI

// MARK: - Models

enum AttendanceStatus: Hashable {
    case present
    case online
    case absent
    case noMark
    case scheduled

    var label: String {
        switch self {
        case .present: "Был"
        case .online: "Был онлайн"
        case .absent: "Не был"
        case .noMark: "Нет отметки"
        case .scheduled: "Запланировано"
        }
    }

    /// Подпись-причина под основным статусом. Сейчас не используется, оставлено
    /// для совместимости.
    var reason: String? { nil }

    var shortLabel: String {
        switch self {
        case .present: "Был"
        case .online: "Онлайн"
        case .absent: "Не был"
        case .noMark: "—"
        case .scheduled: ""
        }
    }

    var tint: Color {
        switch self {
        case .present, .online: .green
        case .absent: .red
        case .noMark: .secondary
        case .scheduled: .secondary
        }
    }

    var symbol: String {
        switch self {
        case .present: "checkmark.circle.fill"
        case .online: "wifi.circle.fill"
        case .absent: "xmark.circle.fill"
        case .noMark: "minus.circle"
        case .scheduled: "circle.dotted"
        }
    }

    /// Counts toward attendance metric (i.e. lesson actually had a verdict)
    var hasVerdict: Bool {
        switch self {
        case .present, .online, .absent: true
        case .noMark, .scheduled: false
        }
    }
}

struct Discipline: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let title: String
    let code: String?
    let totalHours: Int
}

enum TopicProgress: Hashable {
    case notStarted
    case inProgress
    case passed
    case failed
    case checkpoint

    var label: String {
        switch self {
        case .notStarted: "Не начата"
        case .inProgress: "В процессе"
        case .passed: "Сдано"
        case .failed: "Не сдано"
        case .checkpoint: "Контрольная точка"
        }
    }

    var tint: Color {
        switch self {
        case .notStarted: .secondary
        case .inProgress: .orange
        case .passed: .green
        case .failed: .red
        case .checkpoint: .blue
        }
    }
}

struct Topic: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let number: String
    let title: String
    let isCheckpoint: Bool
    var status: TopicProgress = .notStarted
    var score: Double? = nil
    var maxScore: Double? = nil
    var hours: Double = 0
}

struct DisciplineDetail: Hashable {
    let discipline: Discipline
    let topics: [Topic]
    let learningGroupId: String?
}

enum ContentBlockKind: Hashable {
    case info
    case task
    case test
}

struct TopicContentBlock: Identifiable, Hashable {
    var id: String
    let kind: ContentBlockKind
    let name: String
    let body: String
    let maxScore: Double?
    let score: Double?
    let deadline: Date?
    let passDate: Date?
}

struct TopicDetail: Hashable {
    let topic: Topic
    let howToStudy: String?
    let blocks: [TopicContentBlock]
}

struct Lesson: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let order: Int
    let discipline: String
    let disciplineId: String?
    let topic: String
    let topicId: String?
    let teacher: String
    let location: String
    let start: Date
    let end: Date
    let attendance: AttendanceStatus
    var lateMinutes: Int? = nil
    var meetingLink: URL? = nil
    var isOnline: Bool = false

    var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: start))–\(f.string(from: end))"
    }

    var isPast: Bool { end < Date() }
}

enum AssignmentStatus: Hashable {
    case open
    case submitted
    case overdue

    var label: String {
        switch self {
        case .open: "Открыто"
        case .submitted: "Сдано"
        case .overdue: "Просрочено"
        }
    }
}

struct Assignment: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let title: String
    let discipline: String
    let topic: String
    let topicId: String?
    let deadline: Date
    let status: AssignmentStatus
}

struct DigestEvent: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let symbol: String
    let tint: Color
    let title: String
    let detail: String
    var topicId: String? = nil
    var disciplineId: String? = nil
    var lessonId: String? = nil
    var assignmentId: String? = nil
}

struct Digest: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let date: Date
    let oneLine: String
    let events: [DigestEvent]
}

struct DiaryEntry: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let discipline: String
    let topic: String
    let topicId: String?
    let date: Date
    let attendance: AttendanceStatus
}

struct GroupMate: Identifiable, Hashable {
    var id: String
    let firstName: String
    let lastName: String
    let middleName: String?
    let email: String?
    let avatar: String?

    var fullName: String {
        [lastName, firstName, middleName ?? ""]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let l = lastName.first.map { String($0) } ?? ""
        let f = firstName.first.map { String($0) } ?? ""
        return l + f
    }
}

struct Profile: Hashable {
    let lastName: String
    let firstName: String
    let middleName: String
    let email: String
    let organization: String
    let department: String
    let group: String
    let speciality: String
    let learningGroupId: String?
    let groupMates: [GroupMate]
}
