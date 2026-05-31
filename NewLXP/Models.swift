import Foundation
import SwiftUI

// MARK: - Models

enum AttendanceStatus: Hashable {
    case present
    case onlineOfficial
    case onlineNoReason
    case absent
    case scheduled

    var label: String {
        switch self {
        case .present: "Был"
        case .onlineOfficial: "Был онлайн"
        case .onlineNoReason: "Был онлайн"
        case .absent: "Не был"
        case .scheduled: "Запланировано"
        }
    }

    /// Подпись-причина под основным статусом. Показывается только при отклонении.
    var reason: String? {
        switch self {
        case .onlineNoReason: "без причины"
        default: nil
        }
    }

    var shortLabel: String {
        switch self {
        case .present: "Был"
        case .onlineOfficial, .onlineNoReason: "Онлайн"
        case .absent: "Не был"
        case .scheduled: ""
        }
    }

    var tint: Color {
        switch self {
        case .present, .onlineOfficial: .green
        case .onlineNoReason: .red
        case .absent, .scheduled: .secondary
        }
    }

    var symbol: String {
        switch self {
        case .present: "checkmark.circle.fill"
        case .onlineOfficial: "wifi.circle.fill"
        case .onlineNoReason: "wifi.circle"
        case .absent: "xmark.circle"
        case .scheduled: "circle.dotted"
        }
    }
}

struct Discipline: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let title: String
    let topicsCount: Int
    let activeDeadlineCount: Int
    let attendedHours: Int
    let totalHours: Int

    var attendanceRate: Double {
        guard totalHours > 0 else { return 0 }
        return Double(attendedHours) / Double(totalHours)
    }
}

struct Topic: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let number: String
    let title: String
    let isCheckpoint: Bool
}

struct Lesson: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let order: Int
    let discipline: String
    let topic: String
    let teacher: String
    let location: String
    let start: Date
    let end: Date
    let attendance: AttendanceStatus
    var lateMinutes: Int? = nil

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
    let deadline: Date
    let status: AssignmentStatus
}

struct DigestEvent: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let symbol: String
    let tint: Color
    let title: String
    let detail: String
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
    let date: Date
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
}
