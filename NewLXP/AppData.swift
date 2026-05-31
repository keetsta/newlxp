import Foundation
import SwiftUI

enum MockData {
    static let profile = Profile(
        lastName: "Кавеев",
        firstName: "Ренат",
        middleName: "Руслановоч",
        email: "kaveev25@it.ithub.ru",
        organization: "ITHub Москва",
        department: "Кафедра ИБ и СА",
        group: "ИИБ2.25",
        speciality: "Информационная безопасность"
    )

    static let disciplines: [Discipline] = [
        Discipline(title: "Английский язык A2", topicsCount: 28, activeDeadlineCount: 1, attendedHours: 42, totalHours: 56),
        Discipline(title: "Английский язык B1", topicsCount: 24, activeDeadlineCount: 2, attendedHours: 38, totalHours: 48),
        Discipline(title: "Введение в программирование", topicsCount: 18, activeDeadlineCount: 1, attendedHours: 30, totalHours: 36),
        Discipline(title: "Информационные технологии в современном мире", topicsCount: 16, activeDeadlineCount: 0, attendedHours: 17, totalHours: 32),
        Discipline(title: "Литература", topicsCount: 12, activeDeadlineCount: 0, attendedHours: 8, totalHours: 24),
        Discipline(title: "Русский язык. Коммуникативные практики", topicsCount: 14, activeDeadlineCount: 1, attendedHours: 20, totalHours: 28),
        Discipline(title: "История", topicsCount: 20, activeDeadlineCount: 0, attendedHours: 28, totalHours: 40)
    ]

    static let topicsForRussian: [Topic] = [
        Topic(number: "1.1", title: "Знакомство с предметом «Русский язык. Коммуникативные практики». Входное тестирование", isCheckpoint: false),
        Topic(number: "1.2", title: "Логические ошибки в речи", isCheckpoint: false),
        Topic(number: "1.3", title: "Гора: как рассказать историю из жизни", isCheckpoint: false),
        Topic(number: "1.4", title: "Creative task", isCheckpoint: false),
        Topic(number: "C1", title: "Checkpoint 4. Part 2", isCheckpoint: true)
    ]

    static func date(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        let day = cal.date(byAdding: .day, value: dayOffset, to: base)!
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    static let todayLessons: [Lesson] = [
        Lesson(order: 1,
               discipline: "Английский язык B1",
               topic: "1.1 Do you live in the past, present or future? Part 1",
               teacher: "Минестина Эвелина Руслановна",
               location: "Ауд. 312",
               start: date(9, 0),
               end: date(10, 30),
               attendance: .present),
        Lesson(order: 2,
               discipline: "Английский язык B1",
               topic: "1.1 Do you live in the past, present or future? Part 2",
               teacher: "Минестина Эвелина Руслановна",
               location: "Ауд. 312",
               start: date(10, 40),
               end: date(12, 10),
               attendance: .onlineOfficial),
        Lesson(order: 3,
               discipline: "Русский язык. Коммуникативные практики",
               topic: "Знакомство с предметом. Входное тестирование",
               teacher: "Краевнина Алёна Сергеевна",
               location: "Ауд. 415",
               start: date(13, 0),
               end: date(14, 30),
               attendance: .present,
               lateMinutes: 12),
        Lesson(order: 4,
               discipline: "Литература",
               topic: "Стендалить и саморепетавать",
               teacher: "Кархалогов Алёна Сергеевна",
               location: "Ауд. 207",
               start: date(14, 40),
               end: date(16, 10),
               attendance: .scheduled),
        Lesson(order: 5,
               discipline: "Введение в программирование",
               topic: "Checkpoint 4. Part 2",
               teacher: "Денос Тимофей Алексеевич",
               location: "Комп. класс 2",
               start: date(16, 20),
               end: date(17, 50),
               attendance: .scheduled)
    ]

    static let yesterdayLessons: [Lesson] = [
        Lesson(order: 1,
               discipline: "История",
               topic: "XX век: ключевые события",
               teacher: "Гриценко Алексей Петрович",
               location: "Ауд. 109",
               start: date(9, 0, dayOffset: -1),
               end: date(10, 30, dayOffset: -1),
               attendance: .present),
        Lesson(order: 2,
               discipline: "Английский язык A2",
               topic: "1.2 Free time",
               teacher: "Минестина Эвелина Руслановна",
               location: "Ауд. 312",
               start: date(10, 40, dayOffset: -1),
               end: date(12, 10, dayOffset: -1),
               attendance: .onlineNoReason),
        Lesson(order: 3,
               discipline: "Информационные технологии в современном мире",
               topic: "Облачные сервисы",
               teacher: "Денос Тимофей Алексеевич",
               location: "Комп. класс 2",
               start: date(13, 0, dayOffset: -1),
               end: date(14, 30, dayOffset: -1),
               attendance: .absent),
        Lesson(order: 4,
               discipline: "Введение в программирование",
               topic: "Условные операторы",
               teacher: "Денос Тимофей Алексеевич",
               location: "Комп. класс 2",
               start: date(14, 40, dayOffset: -1),
               end: date(16, 10, dayOffset: -1),
               attendance: .present)
    ]

    static let dayBeforeYesterdayLessons: [Lesson] = [
        Lesson(order: 1,
               discipline: "Литература",
               topic: "Серебряный век русской поэзии",
               teacher: "Кархалогов Алёна Сергеевна",
               location: "Ауд. 207",
               start: date(9, 0, dayOffset: -2),
               end: date(10, 30, dayOffset: -2),
               attendance: .onlineOfficial,
               lateMinutes: 7),
        Lesson(order: 2,
               discipline: "Английский язык B1",
               topic: "Past Simple",
               teacher: "Минестина Эвелина Руслановна",
               location: "Ауд. 312",
               start: date(10, 40, dayOffset: -2),
               end: date(12, 10, dayOffset: -2),
               attendance: .onlineOfficial),
        Lesson(order: 3,
               discipline: "Русский язык. Коммуникативные практики",
               topic: "Логические ошибки в речи",
               teacher: "Краевнина Алёна Сергеевна",
               location: "Ауд. 415",
               start: date(13, 0, dayOffset: -2),
               end: date(14, 30, dayOffset: -2),
               attendance: .present)
    ]

    static let tomorrowLessons: [Lesson] = [
        Lesson(order: 1,
               discipline: "Английский язык A2",
               topic: "1.3 My weekend",
               teacher: "Минестина Эвелина Руслановна",
               location: "Ауд. 312",
               start: date(9, 0, dayOffset: 1),
               end: date(10, 30, dayOffset: 1),
               attendance: .scheduled),
        Lesson(order: 2,
               discipline: "Введение в программирование",
               topic: "Циклы while и for",
               teacher: "Денос Тимофей Алексеевич",
               location: "Комп. класс 2",
               start: date(10, 40, dayOffset: 1),
               end: date(12, 10, dayOffset: 1),
               attendance: .scheduled),
        Lesson(order: 3,
               discipline: "История",
               topic: "Холодная война",
               teacher: "Гриценко Алексей Петрович",
               location: "Ауд. 109",
               start: date(13, 0, dayOffset: 1),
               end: date(14, 30, dayOffset: 1),
               attendance: .scheduled)
    ]

    static let dayAfterTomorrowLessons: [Lesson] = [
        Lesson(order: 1,
               discipline: "Русский язык. Коммуникативные практики",
               topic: "Гора: как рассказать историю из жизни",
               teacher: "Краевнина Алёна Сергеевна",
               location: "Ауд. 415",
               start: date(10, 40, dayOffset: 2),
               end: date(12, 10, dayOffset: 2),
               attendance: .scheduled),
        Lesson(order: 2,
               discipline: "Информационные технологии в современном мире",
               topic: "Информационная безопасность",
               teacher: "Денос Тимофей Алексеевич",
               location: "Комп. класс 2",
               start: date(13, 0, dayOffset: 2),
               end: date(14, 30, dayOffset: 2),
               attendance: .scheduled)
    ]

    static func lessons(on date: Date) -> [Lesson] {
        let cal = Calendar.current
        let buckets: [[Lesson]] = [
            dayBeforeYesterdayLessons,
            yesterdayLessons,
            todayLessons,
            tomorrowLessons,
            dayAfterTomorrowLessons
        ]
        for bucket in buckets {
            if let first = bucket.first, cal.isDate(first.start, inSameDayAs: date) {
                return bucket
            }
        }
        return []
    }

    static let assignments: [Assignment] = [
        Assignment(title: "Checkpoint 4. Part 2",
                   discipline: "Русский язык. Коммуникативные практики",
                   topic: "Логические ошибки в речи",
                   deadline: date(23, 59),
                   status: .open),
        Assignment(title: "Creative task",
                   discipline: "Русский язык. Коммуникативные практики",
                   topic: "Гора: как рассказать историю из жизни",
                   deadline: date(23, 59, dayOffset: 2),
                   status: .open),
        Assignment(title: "Гора: как рассказать историю из жизни",
                   discipline: "Русский язык. Коммуникативные практики",
                   topic: "Гора: как рассказать историю из жизни",
                   deadline: date(23, 59, dayOffset: 5),
                   status: .open),
        Assignment(title: "Логические ошибки в речи",
                   discipline: "Русский язык. Коммуникативные практики",
                   topic: "Логические ошибки в речи",
                   deadline: date(23, 59, dayOffset: -3),
                   status: .submitted),
        Assignment(title: "Входное тестирование",
                   discipline: "Русский язык. Коммуникативные практики",
                   topic: "Знакомство с предметом",
                   deadline: date(23, 59, dayOffset: -1),
                   status: .overdue)
    ]

    static let digests: [Digest] = [
        Digest(date: date(8, 0),
               oneLine: "5 пар сегодня, ближайший дедлайн — Checkpoint 4. Part 2 в 23:59",
               events: [
                   DigestEvent(symbol: "clock.badge.exclamationmark.fill", tint: .red,
                               title: "Checkpoint 4. Part 2",
                               detail: "Срок сегодня в 23:59 · Русский язык"),
                   DigestEvent(symbol: "clock.badge.exclamationmark.fill", tint: .orange,
                               title: "Creative task",
                               detail: "Срок через 2 дня · Русский язык"),
                   DigestEvent(symbol: "calendar.badge.clock", tint: .blue,
                               title: "Литература перенесена",
                               detail: "Ауд. 207 → Комп. класс 2"),
                   DigestEvent(symbol: "books.vertical.fill", tint: .purple,
                               title: "Новые материалы",
                               detail: "Введение в программирование · Условные операторы"),
                   DigestEvent(symbol: "calendar", tint: .secondary,
                               title: "5 пар сегодня",
                               detail: "09:00–17:50 · Английский, Русский, Литература, Программирование")
               ]),
        Digest(date: date(8, 0, dayOffset: -1),
               oneLine: "Сдан Checkpoint 3, новая тема по B1: Past Simple",
               events: [
                   DigestEvent(symbol: "checkmark.circle.fill", tint: .green,
                               title: "Checkpoint 3 сдан",
                               detail: "Русский язык · Логические ошибки в речи"),
                   DigestEvent(symbol: "books.vertical.fill", tint: .purple,
                               title: "Новая тема: Past Simple",
                               detail: "Английский язык B1 · Следующая пара в 10:40"),
                   DigestEvent(symbol: "wifi.circle", tint: .red,
                               title: "Онлайн без причины",
                               detail: "Английский A2 · влияет на посещаемость"),
                   DigestEvent(symbol: "calendar", tint: .secondary,
                               title: "4 пары вчера",
                               detail: "История, Английский A2, ИТ, Программирование")
               ]),
        Digest(date: date(8, 0, dayOffset: -2),
               oneLine: "3 пары, обнови материалы по программированию",
               events: [
                   DigestEvent(symbol: "books.vertical.fill", tint: .purple,
                               title: "Обновлены материалы",
                               detail: "Введение в программирование · Условные операторы"),
                   DigestEvent(symbol: "chart.bar.fill", tint: .green,
                               title: "Посещаемость за неделю 80%",
                               detail: "8 из 10 пар · хороший результат"),
                   DigestEvent(symbol: "calendar", tint: .secondary,
                               title: "3 пары",
                               detail: "Литература, Английский B1, Русский язык")
               ])
    ]

    static let diary: [DiaryEntry] = [
        DiaryEntry(discipline: "Английский язык A2", topic: "Free time", date: date(0, dayOffset: -7)),
        DiaryEntry(discipline: "Английский язык B1", topic: "Past Simple", date: date(0, dayOffset: -5)),
        DiaryEntry(discipline: "Введение в программирование", topic: "Условные операторы", date: date(0, dayOffset: -3)),
        DiaryEntry(discipline: "Информационные технологии в современном мире", topic: "Облачные сервисы", date: date(0, dayOffset: -2)),
        DiaryEntry(discipline: "История", topic: "XX век: ключевые события", date: date(0, dayOffset: -1))
    ]

    static var nextLesson: Lesson? {
        let now = Date()
        return todayLessons.first { $0.end > now } ?? nil
    }

    static var currentLesson: Lesson? {
        let now = Date()
        return todayLessons.first { $0.start <= now && $0.end >= now }
    }

    static var nearestDeadline: Assignment? {
        assignments
            .filter { $0.status == .open }
            .sorted { $0.deadline < $1.deadline }
            .first
    }

    static var unreadNotifications: Int { 3 }
    static var assignmentsCount: Int { 152 }
    static var disciplinesCount: Int { 13 }
}
