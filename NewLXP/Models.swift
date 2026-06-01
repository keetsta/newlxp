import Foundation
import SwiftUI

// MARK: - Models

enum AttendanceStatus: String, Hashable, Codable {
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

struct Discipline: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    let title: String
    let code: String?
    let totalHours: Int
    /// Полный максимум баллов за дисциплину (нормировка от сервера). Обычно 100,
    /// но для коротких курсов бывает 80, 70 и т.д.
    var maxScore: Double = 0

    init(id: String = UUID().uuidString, title: String, code: String?, totalHours: Int, maxScore: Double = 0) {
        self.id = id
        self.title = title
        self.code = code
        self.totalHours = totalHours
        self.maxScore = maxScore
    }

    enum CodingKeys: String, CodingKey {
        case id, title, code, totalHours, maxScore
    }

    /// Кастомный декодер — `maxScore` появилось позже, в старых JSON-кэшах
    /// его нет. Если поля не хватает, подставляем 0, чтобы кэш не выкидывался
    /// целиком.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.code = try c.decodeIfPresent(String.self, forKey: .code)
        self.totalHours = try c.decode(Int.self, forKey: .totalHours)
        self.maxScore = try c.decodeIfPresent(Double.self, forKey: .maxScore) ?? 0
    }
}

enum TopicProgress: String, Hashable, Codable {
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

struct Topic: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    let number: String
    let title: String
    let isCheckpoint: Bool
    var status: TopicProgress = .notStarted
    var score: Double? = nil
    var maxScore: Double? = nil
    var hours: Double = 0
    /// Раздел дисциплины, к которому относится тема. ITHub группирует темы по
    /// разделам в UI («Разделы и темы»). `nil` — если сервер не вернул главу
    /// или это старый кэш.
    var chapterId: String? = nil
    var chapterName: String? = nil
    var chapterOrder: Double? = nil

    init(id: String = UUID().uuidString, number: String, title: String, isCheckpoint: Bool, status: TopicProgress = .notStarted, score: Double? = nil, maxScore: Double? = nil, hours: Double = 0, chapterId: String? = nil, chapterName: String? = nil, chapterOrder: Double? = nil) {
        self.id = id
        self.number = number
        self.title = title
        self.isCheckpoint = isCheckpoint
        self.status = status
        self.score = score
        self.maxScore = maxScore
        self.hours = hours
        self.chapterId = chapterId
        self.chapterName = chapterName
        self.chapterOrder = chapterOrder
    }

    enum CodingKeys: String, CodingKey {
        case id, number, title, isCheckpoint, status, score, maxScore, hours
        case chapterId, chapterName, chapterOrder
    }

    /// Кастомный декодер — поля раздела появились позже, в старом кэше их нет.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.number = try c.decode(String.self, forKey: .number)
        self.title = try c.decode(String.self, forKey: .title)
        self.isCheckpoint = try c.decode(Bool.self, forKey: .isCheckpoint)
        self.status = try c.decodeIfPresent(TopicProgress.self, forKey: .status) ?? .notStarted
        self.score = try c.decodeIfPresent(Double.self, forKey: .score)
        self.maxScore = try c.decodeIfPresent(Double.self, forKey: .maxScore)
        self.hours = try c.decodeIfPresent(Double.self, forKey: .hours) ?? 0
        self.chapterId = try c.decodeIfPresent(String.self, forKey: .chapterId)
        self.chapterName = try c.decodeIfPresent(String.self, forKey: .chapterName)
        self.chapterOrder = try c.decodeIfPresent(Double.self, forKey: .chapterOrder)
    }
}

struct DisciplineDetail: Hashable, Codable {
    let discipline: Discipline
    let topics: [Topic]
    let learningGroupId: String?
    /// Текущие баллы и потолок «по выставленному» — ровно так, как считает сайт ITHub.
    /// Числитель оценки 2-5 на сайте.
    var scoreForAnsweredTasks: Double = 0
    /// Знаменатель «по выставленному» — сумма maxScore тем, где препод работу зафиксировал.
    var maxScoreForAnsweredTasks: Double = 0

    init(discipline: Discipline, topics: [Topic], learningGroupId: String?, scoreForAnsweredTasks: Double = 0, maxScoreForAnsweredTasks: Double = 0) {
        self.discipline = discipline
        self.topics = topics
        self.learningGroupId = learningGroupId
        self.scoreForAnsweredTasks = scoreForAnsweredTasks
        self.maxScoreForAnsweredTasks = maxScoreForAnsweredTasks
    }

    enum CodingKeys: String, CodingKey {
        case discipline, topics, learningGroupId, scoreForAnsweredTasks, maxScoreForAnsweredTasks
    }

    /// Кастомный декодер — поля с баллами появились позже, в старом кэше их нет.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.discipline = try c.decode(Discipline.self, forKey: .discipline)
        self.topics = try c.decode([Topic].self, forKey: .topics)
        self.learningGroupId = try c.decodeIfPresent(String.self, forKey: .learningGroupId)
        self.scoreForAnsweredTasks = try c.decodeIfPresent(Double.self, forKey: .scoreForAnsweredTasks) ?? 0
        self.maxScoreForAnsweredTasks = try c.decodeIfPresent(Double.self, forKey: .maxScoreForAnsweredTasks) ?? 0
    }
}

enum ContentBlockKind: String, Hashable, Codable {
    case info
    case task
    case test
}

struct TopicContentBlock: Identifiable, Hashable, Codable {
    var id: String
    let kind: ContentBlockKind
    let name: String
    let body: String
    let maxScore: Double?
    let score: Double?
    let deadline: Date?
    let passDate: Date?
}

struct TopicDetail: Hashable, Codable {
    let topic: Topic
    let howToStudy: String?
    let blocks: [TopicContentBlock]
}

struct Lesson: Identifiable, Hashable, Codable {
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

enum AssignmentStatus: String, Hashable, Codable {
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

struct Assignment: Identifiable, Hashable, Codable {
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

struct GroupMate: Identifiable, Hashable, Codable {
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

struct Profile: Hashable, Codable {
    let lastName: String
    let firstName: String
    let middleName: String
    let email: String
    let avatar: String?
    let organization: String
    let group: String
    let speciality: String
    let learningGroupId: String?
    let groupMates: [GroupMate]
}
