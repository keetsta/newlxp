import Foundation
import SwiftUI

@Observable
@MainActor
final class AppStore {
    static let shared = AppStore()

    // Auth
    var isAuthenticated: Bool = TokenStore.accessToken?.isEmpty == false
    var authError: String?
    var isAuthLoading: Bool = false

    // Profile
    var profile: Profile = MockData.profile

    // Schedule
    var lessonsByDay: [Date: [Lesson]] = [:]
    var isScheduleLoading: Bool = false

    // Disciplines
    var disciplines: [Discipline] = MockData.disciplines

    // Assignments
    var assignments: [Assignment] = MockData.assignments

    // Read-only digest mock for now (нет API эндпоинта в схеме)
    var digests: [Digest] = MockData.digests

    // Diary mock until API endpoint clarified
    var diary: [DiaryEntry] = MockData.diary

    // Topics — пока моковые, требуется отдельный экран дисциплины через getStudentDiscipline
    var topicsForRussian: [Topic] = MockData.topicsForRussian

    // Counters
    var unreadNotifications: Int = 0

    var assignmentsCount: Int { assignments.count }
    var disciplinesCount: Int { disciplines.count }

    var fullName: String {
        [profile.lastName, profile.firstName, profile.middleName]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }

    private init() {}

    // MARK: - Lessons

    func lessons(on date: Date) -> [Lesson] {
        let key = Calendar.current.startOfDay(for: date)
        return lessonsByDay[key] ?? []
    }

    var todayLessons: [Lesson] { lessons(on: Date()) }

    var currentLesson: Lesson? {
        let now = Date()
        return todayLessons.first { $0.start <= now && $0.end >= now }
    }

    var nextLesson: Lesson? {
        let now = Date()
        return todayLessons.first { $0.start > now }
    }

    var nearestDeadline: Assignment? {
        assignments
            .filter { $0.status == .open }
            .sorted { $0.deadline < $1.deadline }
            .first
    }

    // MARK: - Loading

    func bootstrap() async {
        guard isAuthenticated else { return }
        await refreshAll()
    }

    func refreshAll() async {
        async let _ = loadProfile()
        async let _ = loadSchedule()
        async let _ = loadDisciplines()
        async let _ = loadAssignments()
        _ = await (loadProfile(), loadSchedule(), loadDisciplines(), loadAssignments())
    }

    func loadProfile() async {
        do {
            let p = try await ProfileRepository.me()
            self.profile = p
            // Persist student id for subsequent calls.
            if TokenStore.userId == nil {
                if let sid = try? await ProfileRepository.studentId() {
                    TokenStore.userId = sid
                }
            }
        } catch {
            // Keep existing profile on failure.
        }
    }

    func loadSchedule() async {
        isScheduleLoading = true
        defer { isScheduleLoading = false }
        guard let studentId = await currentStudentId() else { return }
        let cal = Calendar.current
        let from = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: Date()))!
        let to = cal.date(byAdding: .day, value: 14, to: cal.startOfDay(for: Date()))!
        do {
            let lessons = try await ScheduleRepository.lessons(studentId: studentId, from: from, to: to)
            var bucket: [Date: [Lesson]] = [:]
            for l in lessons {
                let day = cal.startOfDay(for: l.start)
                bucket[day, default: []].append(l)
            }
            self.lessonsByDay = bucket
        } catch {
            // keep existing
        }
    }

    func loadDisciplines() async {
        guard let studentId = await currentStudentId() else { return }
        do {
            let list = try await DisciplinesRepository.list(studentId: studentId)
            if !list.isEmpty { self.disciplines = list }
        } catch {}
    }

    func loadAssignments() async {
        guard let studentId = await currentStudentId() else { return }
        do {
            let list = try await TasksRepository.availableTasks(studentId: studentId)
            if !list.isEmpty { self.assignments = list }
        } catch {}
    }

    private func currentStudentId() async -> String? {
        if let id = TokenStore.userId, !id.isEmpty { return id }
        do {
            let id = try await ProfileRepository.studentId()
            TokenStore.userId = id
            return id
        } catch {
            return nil
        }
    }

    // MARK: - Sign in / out

    func signIn(email: String, password: String) async {
        isAuthLoading = true
        authError = nil
        defer { isAuthLoading = false }
        do {
            let r = try await AuthRepository.signIn(email: email, password: password)
            TokenStore.accessToken = r.accessToken
            TokenStore.refreshToken = r.refreshToken
            TokenStore.userId = r.userId
            self.isAuthenticated = true
            await self.refreshAll()
        } catch {
            self.authError = error.localizedDescription
        }
    }

    func signOut() {
        TokenStore.clear()
        isAuthenticated = false
        profile = MockData.profile
        lessonsByDay = [:]
        disciplines = MockData.disciplines
        assignments = MockData.assignments
    }
}
