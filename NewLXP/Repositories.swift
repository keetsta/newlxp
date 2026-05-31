import Foundation
import ApolloAPI

// MARK: - Auth

struct LXPAuthResult {
    let accessToken: String
    let refreshToken: String
    let userId: String
    let isLead: Bool
}

enum AuthRepository {
    static func signIn(email: String, password: String) async throws -> LXPAuthResult {
        let input = LXPSchema.SignInInput(email: email, password: password)
        let data = try await LXP.apollo.fetchData(LXPSchema.SignInQuery(input: input))
        let p = data.signIn
        return LXPAuthResult(
            accessToken: p.accessToken,
            refreshToken: p.refreshToken,
            userId: p.user.id,
            isLead: p.user.isLead
        )
    }

    static func refresh() async throws -> Bool {
        guard let token = TokenStore.refreshToken, !token.isEmpty else { return false }
        let input = LXPSchema.RefreshTokenInput(token: token)
        let data = try await LXP.apollo.fetchData(LXPSchema.RefreshTokenQuery(input: input))
        TokenStore.accessToken = data.refreshToken.accessToken
        TokenStore.refreshToken = data.refreshToken.refreshToken
        return true
    }
}

// MARK: - Profile

enum ProfileRepository {
    static func me() async throws -> Profile {
        let data = try await LXP.apollo.fetchData(LXPSchema.GetMeQuery())
        let me = data.getMe
        let suborg = me.student?.suborganizations_V2.first?.suborganization.name
            ?? me.student?.learningGroups.first?.learningGroup.suborganization.name
            ?? ""
        let group = me.student?.learningGroups.first?.learningGroup.name ?? ""
        let speciality = me.student?.studentSpecialties.first?.specialty.name ?? ""
        return Profile(
            lastName: me.lastName ?? "",
            firstName: me.firstName ?? "",
            middleName: me.middleName ?? "",
            email: me.email,
            organization: suborg,
            department: "",
            group: group,
            speciality: speciality
        )
    }

    static func studentId() async throws -> String? {
        let data = try await LXP.apollo.fetchData(LXPSchema.GetMeQuery())
        return data.getMe.student?.id
    }
}

// MARK: - Schedule

enum ScheduleRepository {
    static func lessons(studentId: String, from: Date, to: Date) async throws -> [Lesson] {
        let f = LXPMapping.isoFormatter
        let input = LXPSchema.ClassesForStudentProfileInput(
            from: f.string(from: from),
            studentId: studentId,
            to: f.string(from: to)
        )
        let data = try await LXP.apollo.fetchData(
            LXPSchema.ClassesForStudentProfileQuery(input: input, studentId: studentId)
        )
        let classes = data.classesForStudentProfile

        let sorted = classes.sorted { lhs, rhs in
            (LXPMapping.date(lhs.from) ?? Date.distantPast) < (LXPMapping.date(rhs.from) ?? Date.distantPast)
        }

        // Group by day to compute order numbers per day.
        let cal = Calendar.current
        var perDayOrder: [Date: Int] = [:]

        return sorted.compactMap { c -> Lesson? in
            guard let start = LXPMapping.date(c.from),
                  let end = LXPMapping.date(c.to) else { return nil }
            let day = cal.startOfDay(for: start)
            perDayOrder[day, default: 0] += 1
            let order = perDayOrder[day]!

            let disciplineName = c.discipline?.name ?? c.name ?? "Занятие"
            let topicName: String = {
                if let topics = c.topics as [LXPSchema.ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Topic]?,
                   let first = topics.first { return first.name }
                return ""
            }()
            let teacherName: String = {
                guard let teachers = c.teachers, let first = teachers.first?.user else { return "" }
                return LXPMapping.fullName(last: first.lastName, first: first.firstName, middle: first.middleName)
            }()
            let location: String = {
                if let room = c.classroom?.name {
                    if let area = c.classroom?.buildingArea?.name { return "\(area) · \(room)" }
                    return "Ауд. \(room)"
                }
                if c.isOnline == true { return "Онлайн" }
                return ""
            }()

            let attendance = c.attendance?.first
            let status = LXPMapping.attendanceStatus(
                attendance?.status,
                late: attendance?.lateStatus,
                reason: attendance?.reason,
                defaultIfMissing: end < Date() ? .absent : .scheduled
            )
            let lateMinutes: Int? = (attendance?.lateStatus == .case(.late)) ? 1 : nil

            return Lesson(
                id: c.id,
                order: order,
                discipline: disciplineName,
                topic: topicName,
                teacher: teacherName,
                location: location,
                start: start,
                end: end,
                attendance: status,
                lateMinutes: lateMinutes
            )
        }
    }
}

// MARK: - Disciplines

enum DisciplinesRepository {
    static func list(studentId: String, page: Int = 1, pageSize: Int = 100) async throws -> [Discipline] {
        let input = LXPSchema.StudentDisciplinesThroughClassesWithPaginationInput(
            page: Int32(page), pageSize: Int32(pageSize), studentId: studentId
        )
        let data = try await LXP.apollo.fetchData(LXPSchema.StudentDisciplinesByClassesQuery(input: input))
        return data.studentDisciplinesThroughClassesWithPagination.items.map { item in
            Discipline(
                id: item.id,
                title: item.name,
                topicsCount: 0,
                activeDeadlineCount: 0,
                attendedHours: 0,
                totalHours: Int(item.studyHoursCount.rounded())
            )
        }
    }
}

// MARK: - Tasks (assignments)

enum TasksRepository {
    static func availableTasks(studentId: String, page: Int = 1, pageSize: Int = 50) async throws -> [Assignment] {
        let input = LXPSchema.StudentAvailableTasksInput(
            filters: .none,
            page: Int32(page),
            pageSize: Int32(pageSize),
            sorts: LXPSchema.StudentAvailableTasksSortInput(deadlineDate: .some(.case(.asc))),
            studentId: studentId
        )
        let data = try await LXP.apollo.fetchData(LXPSchema.StudentAvailableTasksQuery(input: input))
        return data.studentAvailableTasks.items.compactMap { item -> Assignment? in
            let resolvedTitle: String = {
                if let n = item.contentBlock.asTaskDisciplineTopicContentBlock?.name { return n }
                if let n = item.contentBlock.asTestDisciplineTopicContentBlock?.name { return n }
                if let n = item.contentBlock.asInfoDisciplineTopicContentBlock?.name { return n }
                return item.topic.name
            }()
            let deadline = LXPMapping.date(item.taskDeadline) ?? LXPMapping.date(item.testAvailableTo) ?? Date.distantFuture
            let status: AssignmentStatus = {
                if item.passDate != nil { return .submitted }
                if let dl = LXPMapping.date(item.taskDeadline), dl < Date() { return .overdue }
                return .open
            }()
            return Assignment(
                id: item.contentBlockId,
                title: resolvedTitle,
                discipline: "",
                topic: item.topic.name,
                deadline: deadline,
                status: status
            )
        }
    }
}
