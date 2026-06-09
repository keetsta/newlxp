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
            avatar: me.avatar,
            organization: suborg,
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
                    totalHours: Int(item.studyHoursCount.rounded()),
                    maxScore: item.maxScore
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
            totalHours: Int(d.discipline.studyHoursCount.rounded()),
            maxScore: d.discipline.maxScore
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
                    hours: t.topic.studyHoursCount,
                    chapterId: t.topic.chapter.id,
                    chapterName: t.topic.chapter.name,
                    chapterOrder: t.topic.chapter.order
                )
            }
        return DisciplineDetail(
            discipline: discipline,
            topics: topics,
            learningGroupId: d.learningGroupId,
            scoreForAnsweredTasks: d.scoreForAnsweredTasks,
            maxScoreForAnsweredTasks: d.maxScoreForAnsweredTasks
        )
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

        // Бэк отдаёт два пересекающихся списка:
        //  • `topic.content.blocks` — ВСЕ блоки темы (info/task/test) в том
        //    же виде, как показывает сайт. Включая info-блоки с критериями
        //    и требованиями к отчёту, которые в `contentBlocks` для студента
        //    периодически отсутствуют.
        //  • `contentBlocks` (StudentTopicContentBlock) — мета по студенту:
        //    дедлайн, баллы, окно сдачи. Без `body`/`name` дублей.
        // Берём `content.blocks` как источник истины по составу темы и
        // накладываем студенческую мету из `contentBlocks` по id.
        struct StudentMeta {
            let testScore: Double?
            let taskDeadline: String?
            let passDate: String?
        }
        var metaById: [String: StudentMeta] = [:]
        for b in st.contentBlocks {
            let id = b.contentBlock.asInfoDisciplineTopicContentBlock?.id
                ?? b.contentBlock.asTaskDisciplineTopicContentBlock?.id
                ?? b.contentBlock.asTestDisciplineTopicContentBlock?.id
                ?? b.contentBlockId
            metaById[id] = StudentMeta(
                testScore: b.testScore,
                taskDeadline: b.taskDeadline,
                passDate: b.passDate
            )
        }

        let blocks: [TopicContentBlock] = st.topic.content.blocks
            .sorted { lhs, rhs in
                let lo = lhs.asTaskDisciplineTopicContentBlock?.order
                    ?? lhs.asTestDisciplineTopicContentBlock?.order
                    ?? lhs.asInfoDisciplineTopicContentBlock?.order
                    ?? 0
                let ro = rhs.asTaskDisciplineTopicContentBlock?.order
                    ?? rhs.asTestDisciplineTopicContentBlock?.order
                    ?? rhs.asInfoDisciplineTopicContentBlock?.order
                    ?? 0
                return lo < ro
            }
            .map { b -> TopicContentBlock in
                let info = b.asInfoDisciplineTopicContentBlock
                let task = b.asTaskDisciplineTopicContentBlock
                let test = b.asTestDisciplineTopicContentBlock
                let kind: ContentBlockKind = {
                    if task != nil { return .task }
                    if test != nil { return .test }
                    return .info
                }()
                let id = info?.id ?? task?.id ?? test?.id ?? UUID().uuidString
                let name = info?.name ?? task?.name ?? test?.name ?? "Блок"
                let body = info?.body ?? task?.body ?? test?.body ?? ""
                let maxScore = task?.maxScore ?? test?.maxScore
                let meta = metaById[id]
                return TopicContentBlock(
                    id: id,
                    kind: kind,
                    name: name,
                    body: body,
                    maxScore: maxScore,
                    score: meta?.testScore,
                    deadline: LXPMapping.date(meta?.taskDeadline),
                    passDate: LXPMapping.date(meta?.passDate)
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
    /// Загружает все доступные студенту задания/КТ. Прежде была одна страница
    /// pageSize=50 — этого хватало пока заданий было мало, но реальные курсы
    /// уже превышают лимит. Идём по `hasMore`, склеиваем страницы.
    /// Info-блоки сервер тоже отдаёт сюда — отфильтровываем на клиенте.
    static func availableTasks(studentId: String, pageSize: Int = 50, maxPages: Int = 20) async throws -> [Assignment] {
        var page = 1
        var collected: [Assignment] = []
        while page <= maxPages {
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
            let payload = data.studentAvailableTasks
            for item in payload.items {
                guard let assignment = mapAssignment(item) else { continue }
                collected.append(assignment)
            }
            if !payload.hasMore { break }
            page += 1
        }
        return collected
    }

    private static func mapAssignment(_ item: LXPSchema.StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item) -> Assignment? {
        // Тип блока. Info — это материал, не задание; в список не показываем.
        let kind: ContentBlockKind = {
            switch item.kind {
            case .case(.task): return .task
            case .case(.test): return .test
            default: return .info
            }
        }()
        guard kind != .info else { return nil }

        let resolvedTitle: String = {
            if let n = item.contentBlock.asTaskDisciplineTopicContentBlock?.name { return n }
            if let n = item.contentBlock.asTestDisciplineTopicContentBlock?.name { return n }
            if let n = item.contentBlock.asInfoDisciplineTopicContentBlock?.name { return n }
            return item.topic.name
        }()
        let maxScore: Double? =
            item.contentBlock.asTaskDisciplineTopicContentBlock?.maxScore
            ?? item.contentBlock.asTestDisciplineTopicContentBlock?.maxScore
        let deadline = LXPMapping.date(item.taskDeadline)
            ?? LXPMapping.date(item.testAvailableTo)
            ?? Date.distantFuture
        let status: AssignmentStatus = {
            if item.passDate != nil { return .submitted }
            if let dl = LXPMapping.date(item.taskDeadline), dl < Date() { return .overdue }
            return .open
        }()
        return Assignment(
            id: item.contentBlockId,
            title: resolvedTitle,
            discipline: item.topic.chapter.discipline.name,
            topic: item.topic.name,
            topicId: item.topic.id,
            deadline: deadline,
            status: status,
            kind: kind,
            isCheckpoint: item.topic.isCheckPoint,
            maxScore: maxScore
        )
    }
}

// MARK: - Answers / file uploads

enum AnswersRepository {
    /// Загружает уже отправленные студентом ответы для блока задания.
    /// `getStudentTask_v2` создаёт связку студент↔блок при первом обращении,
    /// поэтому даже если ответов нет — вызов не падает.
    static func fetchAnswers(studentId: String, topicId: String, contentBlockId: String) async throws -> [StudentTaskAnswer] {
        let input = LXPSchema.GetStudentTaskInput(
            contentBlockId: contentBlockId,
            studentId: studentId,
            topicId: topicId
        )
        let data = try await LXP.apollo.fetchData(LXPSchema.GetStudentTaskQuery(input: input))
        guard let task = data.getStudentTask_v2 else { return [] }
        return task.studentAnswers
            .map { a in
                StudentTaskAnswer(
                    id: a.id,
                    text: a.text,
                    content: a.content,
                    filesUrls: a.filesUrls,
                    createdAt: LXPMapping.date(a.createdAt) ?? Date(),
                    isEdited: a.isEdited
                )
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Создаёт новый ответ. `text` обязателен (бэк требует non-null), `filesUrl` —
    /// уже загруженные через presigned PUT URL'ы файлов.
    static func createAnswer(topicId: String, contentBlockId: String, text: String, filesUrl: [String]) async throws -> StudentTaskAnswer {
        let input = LXPSchema.CreateAnswerInput(
            contentBlockId: contentBlockId,
            filesUrl: filesUrl,
            text: text,
            topicId: topicId
        )
        let data = try await LXP.apollo.performData(LXPSchema.CreateAnswerMutation(input: input))
        let a = data.createAnswer
        return StudentTaskAnswer(
            id: a.id,
            text: a.text,
            content: a.content,
            filesUrls: a.filesUrls,
            createdAt: LXPMapping.date(a.createdAt) ?? Date(),
            isEdited: false
        )
    }

    /// Удаляет ранее отправленный ответ. После — нужно перезапросить список.
    static func deleteAnswer(answerId: String, studentId: String, topicId: String, contentBlockId: String) async throws {
        let input = LXPSchema.DeleteAnswerInputV2(
            answerId: answerId,
            contentBlockId: contentBlockId,
            studentId: studentId,
            topicId: topicId
        )
        _ = try await LXP.apollo.performData(LXPSchema.DeleteAnswerV2Mutation(input: input))
    }
}

enum UploadRepository {
    /// Получает временный (presigned) PUT URL у бэка. Загрузка идёт прямо
    /// в S3 — мимо нашего GraphQL.
    static func presignedUrl(fileName: String, fileExtension: String) async throws -> URL {
        let input = LXPSchema.GetFileUploadUrlInput(
            fileExtensionV2: .some(fileExtension),
            fileName: .some(fileName)
        )
        let data = try await LXP.apollo.fetchData(LXPSchema.GetFileUploadUrlQuery(input: input))
        guard let url = URL(string: data.getFileUploadUrl.url) else {
            throw LXPError.server("Некорректный URL загрузки")
        }
        return url
    }

    /// Аплоадит data PUT-ом и возвращает «постоянную» URL без query-параметров,
    /// которую и хранит бэк в `filesUrls`.
    static func uploadFile(data: Data, fileName: String, fileExtension: String, mimeType: String) async throws -> String {
        let putURL = try await presignedUrl(fileName: fileName, fileExtension: fileExtension)
        LXPLog.debug("[LXP][upload] presigned host=\(putURL.host ?? "?") path=\(putURL.path)")
        var req = URLRequest(url: putURL)
        req.httpMethod = "PUT"
        req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        let (_, resp) = try await URLSession.shared.upload(for: req, from: data)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            LXPLog.debug("[LXP][upload] PUT failed code=\(code)")
            throw LXPError.server("Не удалось загрузить файл (код \(code))")
        }
        // Бэк сохраняет ссылку без presigned-параметров — обрезаем query.
        var comps = URLComponents(url: putURL, resolvingAgainstBaseURL: false)
        comps?.query = nil
        comps?.fragment = nil
        let publicUrl = comps?.url?.absoluteString ?? putURL.absoluteString
        LXPLog.debug("[LXP][upload] OK \(publicUrl)")
        return publicUrl
    }
}
