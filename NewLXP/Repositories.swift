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

struct MeBundle {
    let userId: String
    let studentId: String?
    let profile: Profile
}

enum ProfileRepository {
    static func fetchMe() async throws -> MeBundle {
        let data = try await LXP.apollo.fetchData(LXPSchema.GetMeQuery())
        let me = data.getMe
        let firstGroup = me.student?.learningGroups.first?.learningGroup
        let suborg = me.student?.suborganizations_V2.first?.suborganization.name ?? ""
        let group = firstGroup?.name ?? ""
        let learningGroupId = firstGroup?.id
        let speciality = me.student?.studentSpecialties.first?.specialty.name ?? ""

        let myUserId = me.id
        let mates: [GroupMate] = (firstGroup?.students ?? [])
            .filter { $0.id != myUserId }
            .map { s in
                GroupMate(
                    id: s.id,
                    firstName: s.firstName ?? "",
                    lastName: s.lastName ?? "",
                    middleName: s.middleName,
                    email: s.email,
                    avatar: s.avatar
                )
            }
            .sorted { $0.lastName < $1.lastName }

        let profile = Profile(
            lastName: me.lastName ?? "",
            firstName: me.firstName ?? "",
            middleName: me.middleName ?? "",
            email: me.email,
            organization: suborg,
            department: "",
            group: group,
            speciality: speciality,
            learningGroupId: learningGroupId,
            groupMates: mates
        )
        return MeBundle(userId: me.id, studentId: me.student?.id, profile: profile)
    }
}

// MARK: - Schedule

enum ScheduleRepository {
    static func lessons(studentId: String, from: Date, to: Date) async throws -> [Lesson] {
        let f = LXPMapping.isoFormatter
        let interval = LXPSchema.ManyClassesFilterDateIntervalInput(
            from: f.string(from: from),
            to: f.string(from: to)
        )
        let filters = LXPSchema.ManyClassesFilterInput(
            interval: interval,
            roles: .some([.case(.student)]),
            studentsIds: .some([studentId])
        )
        let input = LXPSchema.ManyClassesInput(
            filters: filters, page: 1, pageSize: 50
        )
        let data = try await LXP.apollo.fetchData(
            LXPSchema.StudentClassesQuery(input: input, studentId: studentId)
        )
        let classes = data.manyClasses

        let sorted = classes.sorted { lhs, rhs in
            (LXPMapping.date(lhs.from) ?? Date.distantPast) < (LXPMapping.date(rhs.from) ?? Date.distantPast)
        }

        let cal = Calendar.current
        var perDayOrder: [Date: Int] = [:]

        return sorted.compactMap { c -> Lesson? in
            guard let start = LXPMapping.date(c.from),
                  let end = LXPMapping.date(c.to) else { return nil }
            let day = cal.startOfDay(for: start)
            perDayOrder[day, default: 0] += 1
            let order = perDayOrder[day]!

            let disciplineName = c.discipline?.name ?? c.name ?? "Занятие"
            let topicName = c.topics.first?.name ?? ""
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
                defaultIfMissing: end < Date() ? .noMark : .scheduled
            )
            let lateMinutes: Int? = (attendance?.lateStatus == .case(.late)) ? 1 : nil

            return Lesson(
                id: c.id,
                order: order,
                discipline: disciplineName,
                disciplineId: c.discipline?.id,
                topic: topicName,
                topicId: c.topics.first?.id,
                teacher: teacherName,
                location: location,
                start: start,
                end: end,
                attendance: status,
                lateMinutes: lateMinutes,
                meetingLink: c.meetingLink.flatMap { URL(string: $0) },
                isOnline: c.isOnline ?? false
            )
        }
    }
}

// MARK: - Disciplines

enum DisciplinesRepository {
    static func list(studentId: String, page: Int = 1, pageSize: Int = 50) async throws -> [Discipline] {
        let input = LXPSchema.StudentDisciplinesThroughClassesWithPaginationInput(
            page: Int32(page), pageSize: Int32(pageSize), studentId: studentId
        )
        let data = try await LXP.apollo.fetchData(LXPSchema.StudentDisciplinesByClassesQuery(input: input))
        return data.studentDisciplinesThroughClassesWithPagination.items
            .filter { $0.archivedAt == nil }
            .map { item in
                Discipline(
                    id: item.id,
                    title: item.name,
                    code: item.code,
                    totalHours: Int(item.studyHoursCount.rounded())
                )
            }
    }

    static func detail(studentId: String, disciplineId: String) async throws -> DisciplineDetail {
        let input = LXPSchema.GetStudentDisciplineInput(disciplineId: disciplineId, studentId: studentId)
        let data = try await LXP.apollo.fetchData(LXPSchema.GetStudentDisciplineQuery(input: input))
        let d = data.getStudentDiscipline
        let discipline = Discipline(
            id: d.discipline.id,
            title: d.discipline.name,
            code: d.discipline.code,
            totalHours: Int(d.discipline.studyHoursCount.rounded())
        )
        let topics: [Topic] = d.topics
            .sorted { ($0.topic.order) < ($1.topic.order) }
            .map { t in
                let isCheck = t.topic.isCheckPoint
                let progress: TopicProgress = LXPMapping.topicStatus(t.status, isCheckpoint: isCheck)
                return Topic(
                    id: t.topicId,
                    number: numberFor(order: t.topic.order),
                    title: t.topic.name,
                    isCheckpoint: isCheck,
                    status: progress,
                    score: t.topicScore,
                    maxScore: t.topic.maxScore,
                    hours: t.topic.studyHoursCount
                )
            }
        return DisciplineDetail(discipline: discipline, topics: topics, learningGroupId: d.learningGroupId)
    }

    private static func numberFor(order: Double) -> String {
        if order.rounded() == order { return String(Int(order)) }
        return String(format: "%.1f", order)
    }
}

// MARK: - Topic detail

enum TopicRepository {
    static func detail(studentId: String, topicId: String) async throws -> TopicDetail {
        let input = LXPSchema.GetStudentTopicInput(studentId: studentId, topicId: topicId)
        let data = try await LXP.apollo.fetchData(LXPSchema.GetStudentTopicQuery(input: input))
        let st = data.getStudentTopic.topic
        let isCheck = st.topic.isCheckPoint
        let topic = Topic(
            id: st.topicId,
            number: numberFor(order: st.topic.order),
            title: st.topic.name,
            isCheckpoint: isCheck,
            status: LXPMapping.topicStatus(st.status, isCheckpoint: isCheck),
            score: st.topicScore,
            maxScore: st.topic.maxScore,
            hours: st.topic.studyHoursCount
        )
        let blocks: [TopicContentBlock] = st.contentBlocks
            .sorted { lhs, rhs in
                let lo = lhs.contentBlock.asTaskDisciplineTopicContentBlock?.order
                    ?? lhs.contentBlock.asTestDisciplineTopicContentBlock?.order
                    ?? lhs.contentBlock.asInfoDisciplineTopicContentBlock?.order
                    ?? 0
                let ro = rhs.contentBlock.asTaskDisciplineTopicContentBlock?.order
                    ?? rhs.contentBlock.asTestDisciplineTopicContentBlock?.order
                    ?? rhs.contentBlock.asInfoDisciplineTopicContentBlock?.order
                    ?? 0
                return lo < ro
            }
            .map { b -> TopicContentBlock in
                let kind: ContentBlockKind = {
                    switch b.kind {
                    case .case(.info): return .info
                    case .case(.task): return .task
                    case .case(.test): return .test
                    default: return .info
                    }
                }()
                let info = b.contentBlock.asInfoDisciplineTopicContentBlock
                let task = b.contentBlock.asTaskDisciplineTopicContentBlock
                let test = b.contentBlock.asTestDisciplineTopicContentBlock
                let id = info?.id ?? task?.id ?? test?.id ?? b.contentBlockId
                let name = info?.name ?? task?.name ?? test?.name ?? "Блок"
                let body = info?.body ?? task?.body ?? test?.body ?? ""
                let maxScore = task?.maxScore ?? test?.maxScore
                return TopicContentBlock(
                    id: id,
                    kind: kind,
                    name: name,
                    body: body,
                    maxScore: maxScore,
                    score: b.testScore,
                    deadline: LXPMapping.date(b.taskDeadline),
                    passDate: LXPMapping.date(b.passDate)
                )
            }
        return TopicDetail(topic: topic, howToStudy: st.topic.content.howStudyIt, blocks: blocks)
    }

    private static func numberFor(order: Double) -> String {
        if order.rounded() == order { return String(Int(order)) }
        return String(format: "%.1f", order)
    }
}

enum TasksRepository {
    static func availableTasks(studentId: String, page: Int = 1, pageSize: Int = 50) async throws -> [Assignment] {
        let input = LXPSchema.StudentAvailableTasksInput(
            filters: .some(LXPSchema.StudentAvailableTasksFilterInput(
                fromArchivedDiscipline: .some(false)
            )),
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
                topicId: item.topic.id,
                deadline: deadline,
                status: status
            )
        }
    }
}
