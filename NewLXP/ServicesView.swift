import SwiftUI

struct ServicesView: View {
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    quickAccess
                    menu
                    logoutButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Сервисы")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var profileHeader: some View {
        NavigationLink {
            ProfileView()
        } label: {
            HStack(spacing: 14) {
                Text(initials)
                    .font(.headline.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(AppStore.shared.profile.lastName) \(AppStore.shared.profile.firstName)")
                        .font(.headline)
                    Text(AppStore.shared.profile.group)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let f = AppStore.shared.profile.firstName.first.map { String($0) } ?? ""
        let l = AppStore.shared.profile.lastName.first.map { String($0) } ?? ""
        return l + f
    }

    private var quickAccess: some View {
        HStack(spacing: 12) {
            NavigationLink { AssignmentsView() } label: {
                CountTile(title: "Задания", value: AppStore.shared.assignmentsCount, symbol: "tray.full")
            }
            .buttonStyle(.plain)
            NavigationLink { DisciplinesView() } label: {
                CountTile(title: "Дисциплины", value: AppStore.shared.disciplinesCount, symbol: "books.vertical")
            }
            .buttonStyle(.plain)
        }
    }

    private var menu: some View {
        VStack(spacing: 0) {
            NavigationLink { DiaryView() } label: {
                DisclosureRow(title: "Дневник", subtitle: "История пройденных тем", symbol: "book.closed")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 56).opacity(0.4)
            NavigationLink { AttendanceOverviewView() } label: {
                DisclosureRow(title: "Посещаемость",
                              subtitle: "Сводка по дисциплинам",
                              symbol: "chart.bar")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 56).opacity(0.4)
            NavigationLink { AboutView() } label: {
                DisclosureRow(title: "О приложении", symbol: "info.circle")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
        } label: {
            HStack {
                Spacer()
                Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.body.weight(.semibold))
                Spacer()
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

struct AssignmentsView: View {
    @State private var query = ""
    @State private var filter: AssignmentStatus? = nil

    private var items: [Assignment] {
        AppStore.shared.assignments.filter {
            (filter == nil || $0.status == filter) &&
            (query.isEmpty ||
             $0.title.localizedCaseInsensitiveContains(query) ||
             $0.discipline.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                filtersRow
                ForEach(items) { item in
                    NavigationLink {
                        AssignmentDetailView(assignment: item)
                    } label: {
                        AssignmentCard(assignment: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .searchable(text: $query, prompt: "Поиск")
        .navigationTitle("Задания")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "Все", isSelected: filter == nil) { filter = nil }
                FilterPill(title: "Открытые", isSelected: filter == .open) { filter = .open }
                FilterPill(title: "Сданные", isSelected: filter == .submitted) { filter = .submitted }
                FilterPill(title: "Просроченные", isSelected: filter == .overdue) { filter = .overdue }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(isSelected ? .regular.tint(.primary.opacity(0.18)) : .regular,
                              in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

struct AssignmentCard: View {
    let assignment: Assignment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(assignment.discipline.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .lineLimit(1)
                Spacer()
                statusPill
            }
            Text(assignment.title)
                .font(.body.weight(.semibold))
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(deadlineText)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var deadlineText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, HH:mm"
        return "Срок: " + f.string(from: assignment.deadline)
    }

    private var statusPill: some View {
        Text(assignment.status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular, in: .capsule)
    }
}

struct AssignmentDetailView: View {
    let assignment: Assignment
    @State private var draft: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(assignment.discipline.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)
                        Text(assignment.title)
                            .font(.title3.weight(.semibold))
                        Text(assignment.topic)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Условие")
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Write an essay on \"A famous street\".")
                            Text("Your essay should be 180–200 words long.")
                            Text("Speak about:\n• where it is\n• the history of the street\n• why it is famous\n\nInclude pictures in your essay (inside the text). Attach the essay here.")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Ваш ответ")
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Сообщение", text: $draft, axis: .vertical)
                            .lineLimit(4...8)
                            .textFieldStyle(.plain)
                        HStack {
                            Button {
                            } label: {
                                Label("Прикрепить файл", systemImage: "paperclip")
                            }
                            Spacer()
                            Button {
                            } label: {
                                Text("Отправить")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .glassEffect(.regular.tint(.primary.opacity(0.2)), in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 22))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle(assignment.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DisciplinesView: View {
    @State private var query = ""

    private var items: [Discipline] {
        if query.isEmpty { return AppStore.shared.disciplines }
        return AppStore.shared.disciplines.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(items) { discipline in
                    NavigationLink {
                        DisciplineDetailView(discipline: discipline)
                    } label: {
                        DisciplineCard(discipline: discipline)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .searchable(text: $query, prompt: "Поиск")
        .navigationTitle("Дисциплины")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DisciplineCard: View {
    let discipline: Discipline

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(discipline.title)
                .font(.body.weight(.semibold))
                .lineLimit(2)
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(discipline.attendanceRate * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text("· \(discipline.attendedHours) из \(discipline.totalHours) ч")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if discipline.activeDeadlineCount > 0 {
                    Text("\(discipline.activeDeadlineCount) дедлайн")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .glassEffect(.regular, in: .capsule)
                }
            }
            AttendanceBar(rate: discipline.attendanceRate)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

struct DisciplineDetailView: View {
    let discipline: Discipline

    private var topics: [Topic] { AppStore.shared.topicsForRussian }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(discipline.title)
                            .font(.title3.weight(.semibold))
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Посещаемость")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text("\(Int(discipline.attendanceRate * 100))%")
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Часов")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text("\(discipline.attendedHours)/\(discipline.totalHours)")
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                            }
                        }
                        AttendanceBar(rate: discipline.attendanceRate)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Разделы и темы", trailing: "\(discipline.topicsCount)")
                    VStack(spacing: 0) {
                        ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                            NavigationLink {
                                TopicDetailView(disciplineTitle: discipline.title,
                                                topicTitle: topic.title)
                            } label: {
                                TopicRow(topic: topic)
                            }
                            .buttonStyle(.plain)
                            if index < topics.count - 1 {
                                Divider().padding(.leading, 16).opacity(0.4)
                            }
                        }
                    }
                    .glassEffect(.regular, in: .rect(cornerRadius: 22))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Дисциплина")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TopicRow: View {
    let topic: Topic

    var body: some View {
        HStack(spacing: 14) {
            Text(topic.number)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .frame(width: 36, alignment: .leading)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(.subheadline)
                    .lineLimit(2)
                if topic.isCheckpoint {
                    Text("Контрольная точка")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.4)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct DiaryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(AppStore.shared.diary) { entry in
                    HStack(spacing: 14) {
                        Image(systemName: "book.closed")
                            .font(.body.weight(.medium))
                            .frame(width: 32, height: 32)
                            .glassEffect(.regular, in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.discipline)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                            Text(entry.topic)
                                .font(.subheadline)
                        }
                        Spacer()
                        Text(entry.date, format: .dateTime.day().month())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                    .padding(16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Дневник")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AttendanceOverviewView: View {
    private var disciplines: [Discipline] { AppStore.shared.disciplines }
    private var totalAttended: Int { disciplines.reduce(0) { $0 + $1.attendedHours } }
    private var totalHours: Int { disciplines.reduce(0) { $0 + $1.totalHours } }
    private var rate: Double {
        totalHours > 0 ? Double(totalAttended) / Double(totalHours) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summary
                legend
                list
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Посещаемость")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        GlassCard(padding: 20, corner: 26) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Семестр".uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(rate * 100))%")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("\(totalAttended) из \(totalHours) ч")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                AttendanceBar(rate: rate)
            }
        }
    }

    private var legend: some View {
        VStack(spacing: 0) {
            legendRow(.present)
            Divider().padding(.leading, 44).opacity(0.4)
            legendRow(.onlineOfficial)
            Divider().padding(.leading, 44).opacity(0.4)
            legendRow(.onlineNoReason)
            Divider().padding(.leading, 44).opacity(0.4)
            legendRow(.absent)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private func legendRow(_ s: AttendanceStatus) -> some View {
        HStack(spacing: 14) {
            Image(systemName: s.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(s.tint)
                .frame(width: 28)
            Text(s.label).font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "По дисциплинам")
            VStack(spacing: 12) {
                ForEach(disciplines) { d in
                    DisciplineCard(discipline: d)
                }
            }
        }
    }
}

struct ProfileView: View {
    private var p: Profile { AppStore.shared.profile }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                avatar
                infoBlock(title: "Личная информация",
                          rows: [
                            ("Фамилия", p.lastName),
                            ("Имя", p.firstName),
                            ("Отчество", p.middleName),
                            ("Email", p.email)
                          ])
                infoBlock(title: "Организация",
                          rows: [
                            ("Учреждение", p.organization),
                            ("Кафедра", p.department),
                            ("Группа", p.group),
                            ("Специальность", p.speciality)
                          ])
                NavigationLink {
                    GroupListView(group: p.group)
                } label: {
                    DisclosureRow(title: "Группа \(p.group)",
                                  subtitle: "Список одногруппников",
                                  symbol: "person.3")
                        .padding(16)
                        .glassEffect(.regular, in: .rect(cornerRadius: 22))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var avatar: some View {
        VStack(spacing: 12) {
            Text(initials)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .frame(width: 96, height: 96)
                .glassEffect(.regular, in: .circle)
            Text("\(p.lastName) \(p.firstName) \(p.middleName)")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var initials: String {
        let f = p.firstName.first.map { String($0) } ?? ""
        let l = p.lastName.first.map { String($0) } ?? ""
        return l + f
    }

    private func infoBlock(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.0)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .leading)
                        Text(row.1)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    if i < rows.count - 1 {
                        Divider().padding(.leading, 16).opacity(0.4)
                    }
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }
}

struct GroupListView: View {
    let group: String

    private let names = [
        "Афрафейн Антон Менуевич",
        "Беляев Михаил Евгеньевич",
        "Григорьев Сергей Максимович",
        "Денос Тимофей Алексеевич",
        "Злобин Матвей Владимирович",
        "Кавеев Ренат Руслановоч",
        "Каргаполов Алёна Сергеевна",
        "Кравченко Даниил Владиславович",
        "Крестьянкин Фёдор Романович",
        "Курилкин Глеб Дмитриевич",
        "Минестина Эвелина Руслановна",
        "Мирсков Владимир Александрович"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(names, id: \.self) { name in
                    HStack(spacing: 14) {
                        Text(initials(for: name))
                            .font(.caption.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .glassEffect(.regular, in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name).font(.subheadline)
                            Text(email(for: name))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle(group)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let l = parts.first.flatMap { $0.first }.map { String($0) } ?? ""
        let f = (parts.count > 1 ? parts[1].first : nil).map { String($0) } ?? ""
        return l + f
    }

    private func email(for name: String) -> String {
        let translit = name.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .prefix(8)
        return "\(translit)@it.ithub.ru"
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var theme = "Системная"
    @State private var locale = "Русский"
    @State private var notifications = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    settingRow("Цветовая тема", value: theme)
                    settingRow("Локализация", value: locale)
                    settingToggle("Уведомления", isOn: $notifications)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func settingRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func settingToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).font(.subheadline)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .frame(width: 88, height: 88)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                    Text("ITHub LXP").font(.title3.weight(.semibold))
                    Text("Версия 2.118+102")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                VStack(spacing: 0) {
                    DisclosureRow(title: "Условия использования", symbol: "doc.text")
                        .padding(16)
                    Divider().padding(.leading, 56).opacity(0.4)
                    DisclosureRow(title: "Политика конфиденциальности", symbol: "lock.shield")
                        .padding(16)
                    Divider().padding(.leading, 56).opacity(0.4)
                    DisclosureRow(title: "Открыть в веб-версии", symbol: "safari")
                        .padding(16)
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(AppStore.shared.digests) { digest in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ежедневный дайджест".uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                            Text(digest.oneLine)
                                .font(.subheadline.weight(.semibold))
                            Text(digest.date, format: .dateTime.day().month().hour().minute())
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Уведомления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

struct DigestDetailView: View {
    let digest: Digest

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(digest.date, format: .dateTime.day().month().year())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)
                        Text("Ежедневный дайджест")
                            .font(.title3.weight(.semibold))
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(digest.events.enumerated()), id: \.element.id) { index, event in
                        HStack(spacing: 14) {
                            Image(systemName: event.symbol)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(event.tint)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(event.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        if index < digest.events.count - 1 {
                            Divider().padding(.leading, 58).opacity(0.4)
                        }
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Дайджест")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ServicesView()
}
