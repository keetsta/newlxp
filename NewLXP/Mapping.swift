import Foundation
import ApolloAPI

// Mappers from generated GraphQL types into UI models.

enum LXPMapping {

    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let isoFormatterNoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func date(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return isoFormatter.date(from: raw) ?? isoFormatterNoFractional.date(from: raw)
    }

    static func fullName(last: String?, first: String?, middle: String?) -> String {
        [last, first, middle].compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func attendanceStatus(
        _ status: GraphQLEnum<LXPSchema.ClassAttendanceStatus>?,
        late: GraphQLEnum<LXPSchema.ClassAttendanceLateStatus>?,
        reason: String?,
        defaultIfMissing: AttendanceStatus = .scheduled
    ) -> AttendanceStatus {
        guard let status else { return defaultIfMissing }
        switch status {
        case .case(.exist): return .present
        case .case(.existOnline):
            // если нет уважительной причины — отметим как неуважительный онлайн
            return (reason?.isEmpty ?? true) ? .onlineNoReason : .onlineOfficial
        case .case(.notExist): return .absent
        default: return defaultIfMissing
        }
    }
}
