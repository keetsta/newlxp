# NewLXP — ITHub LXP iOS Client

iOS-приложение — клиент образовательной платформы LXP колледжа ITHub. Минималистичный дизайн под iOS 26 с использованием `.glassEffect`. Привязано к боевому API `https://api.newlxp.ru/graphql`.

## Стек

- **Swift / SwiftUI** — только SwiftUI, минимально UIKit (только `UIDevice` для версии ОС)
- **iOS 26+** — используется `.glassEffect`, `.tabBarMinimizeBehavior`, нативный `Tab` API, `@Observable`
- **Xcode** — проект в `NewLXP.xcodeproj`, открывать Xcode 26.4+
- **Apollo iOS 2.0.3** — GraphQL клиент, подключён через SPM
- **apollo-ios-cli 2.0.3** — лежит в корне проекта, кодген запускается командой `./apollo-ios-cli generate --ignore-version-mismatch`

## API

Эндпоинт: `https://api.newlxp.ru/graphql`. Все запросы требуют header `apollo-require-preflight: true` (CSRF guard на бэке) и `Authorization: Bearer <accessToken>` после логина.

**Авторизация**: query `signIn(input: SignInInput!) { accessToken refreshToken user { id isLead } }` (это именно `query`, не mutation). Refresh — `refreshToken(input: { token })`.

Ключевые операции (см. `NewLXP/GraphQL/Operations/`):
- `Auth.graphql` — `SignIn`, `RefreshToken`
- `Profile.graphql` — `GetMe` (включая `student.learningGroups[].learningGroup.students` для одногруппников)
- `Schedule.graphql` — `StudentClasses` через `manyClasses(input: { filters: { interval, roles: [STUDENT], studentsIds: [...] }, page, pageSize: 50 })`. **Важно**: `classesForStudentProfile` для студента запрещён сервером (FORBIDDEN), используется только `manyClasses` с фильтром по роли STUDENT
- `Disciplines.graphql` — `StudentDisciplinesByClasses` (max pageSize=50), `GetStudentDiscipline` (без `averageAttendance` — поле падает 500 на бэке)
- `Tasks.graphql` — `StudentAvailableTasks` с union типом `DisciplineTopicContentBlock` (Info / Task / Test)
- `Topic.graphql` — `GetStudentTopic` с `contentBlocks[].contentBlock { ... on TaskDisciplineTopicContentBlock { body } }` и `topic.content.howStudyIt`

**Известные грабли API**:
- `getMe.student.learningGroups[].learningGroup.suborganization` — иногда падает 500 (внутри одной из групп). Не запрашивать.
- `studentDisciplinesThroughClassesWithPagination` возвращает дубликаты по `name` (разные ID для разных семестров/групп) — склеиваем в `loadDisciplines` суммируя часы.
- `pageSize > 50` отвергается сервером.
- `studentId` для студента совпадает с `user.id` (один UUID), но всё равно ходим за `student.id` через `getMe`.

## Структура файлов

```
NewLXP/
├── NewLXPApp.swift          — @main, RootView (LoginView vs ContentView), bootstrap()
├── ContentView.swift        — TabView с тремя вкладками
├── LoginView.swift          — Экран входа (email + password)
├── HomeView.swift           — Главная: герой-карточка, метрики, дайджест, расписание дня
├── ScheduleView.swift       — Расписание + LessonDetailView + TopicDetailView + TopicContentBlockCard
├── ServicesView.swift       — Сервисы и все вложенные экраны (Profile, Assignments, Disciplines, Diary, AttendanceOverview, Settings, About, GroupList, DigestDetail)
├── Components.swift         — Переиспользуемые компоненты
├── Models.swift             — UI-модели (Lesson, Discipline, Topic, Profile, GroupMate, …)
├── AppData.swift            — MockData (пустые дефолты для signOut)
├── AppStore.swift           — @Observable singleton-стор: всё состояние, загрузка, дайджест, посещаемость
├── Networking.swift         — TokenStore + Apollo client + AuthHeadersInterceptor + LXPError
├── Repositories.swift       — Auth/Profile/Schedule/Disciplines/Tasks/Topic — обёртки над Apollo
├── Mapping.swift             — GraphQL enum → UI enum (attendance, topic status), DateFormatters
├── EditorContent.swift      — Парсер Editor.js + InlineHTML → AttributedString + SwiftUI рендер
├── BuildNumber.txt          — счётчик билда (инкрементится скриптом)
└── GraphQL/
    ├── LXPSchema/           — сгенерированный код (схема + типы + операции)
    └── Operations/*.graphql — исходные операции
```

```
scripts/
└── bump-build.sh            — pre-build скрипт инкремента CFBundleVersion
```

## Навигация

Три вкладки в `TabView`:
- **Главная** (`HomeView`) — текущая/следующая пара, плитки с количеством, карточка дайджеста (NavigationLink → DigestDetailView), список пар сегодня
- **Расписание** (`ScheduleView`) — листание по неделям (стрелки + кнопка «Сегодня» в тулбаре), week strip 7 дней, сводка посещаемости за неделю, список пар дня. При выборе дня вне загруженного диапазона зовётся `store.ensureScheduleAround(date)`
- **Сервисы** (`ServicesView`) — профиль, плитки заданий и дисциплин, меню (дневник / посещаемость / о приложении), шестерёнка → SettingsView

Детальные экраны через `NavigationLink` в каждом NavigationStack. Экран темы (`TopicDetailView`) — общий и используется отовсюду: из карточки пары, из списка тем дисциплины, из дайджеста, из дневника, из заданий (`Assignment` ведёт сразу в свою тему по `topicId`, отдельной AssignmentDetailView нет).

## Стор и загрузка данных

Всё состояние держит `AppStore.shared` (`@Observable @MainActor final class`). Во вьюхах подписываемся через `@Environment(AppStore.self) private var store`. `RootView` смотрит на `store.isAuthenticated`.

Жизненный цикл:
1. `NewLXPApp.task` → `store.bootstrap()` (если есть токен).
2. `bootstrap` → `refreshAll`: сначала `loadProfile` (даёт `studentId`), затем параллельно через `withTaskGroup`: `loadSchedule`, `loadDisciplines`, `loadAssignments`.
3. После `signIn` тоже зовётся `refreshAll`.

Кеши:
- `lessonsByDay: [Date: [Lesson]]` + `loadedRanges: [DateInterval]` — повторно одну неделю не качаем.
- `disciplineDetails: [String: DisciplineDetail]`, `topicDetails: [String: TopicDetail]` — лениво по запросу.
- При signOut всё чистится в `MockData` (пустые значения).

Производные данные (computed на сторе):
- `dailyDigest: Digest` — собирается из ближайшей пары (с `topicId`), открытых дедлайнов (с `topicId`), просроченных, итога по парам сегодня, посещаемости за неделю.
- `diary: [DiaryEntry]` — из `pastLessons` (все прошедшие пары, включая `.noMark`).
- `attendance(in: ClosedRange<Date>) -> AttendanceMetric`, `attendanceFor(disciplineTitle:in:)` — учитывают только пары с `attendance.hasVerdict`. Только `.absent` снимает часы.
- `weekAttendance()`, `monthAttendance()` — обёртки над `attendance(in:)`.

## Модели данных

| Модель | Назначение |
|---|---|
| `Lesson` | Пара: `id, order, discipline, disciplineId, topic, topicId, teacher, location, start, end, attendance, lateMinutes` |
| `AttendanceStatus` | `.present / .online / .absent / .noMark / .scheduled`. У `.absent` `tint == .red`, у `.noMark` — серый. `.online` (любой `EXIST_ONLINE`, с причиной или без) считается присутствием и зелёный. `hasVerdict` — true только для present/online/absent |
| `Discipline` | `id, title, code, totalHours` (без процентов/дедлайнов — их нет в API списка) |
| `DisciplineDetail` | `discipline, topics, learningGroupId` |
| `Topic` | `id, number, title, isCheckpoint, status: TopicProgress, score, maxScore, hours` |
| `TopicProgress` | `.notStarted / .inProgress / .passed / .failed / .checkpoint` (маппится из `LXPSchema.TopicStatus`) |
| `TopicDetail` | `topic, howToStudy?, blocks: [TopicContentBlock]` |
| `TopicContentBlock` | `id, kind: .info/.task/.test, name, body (Editor.js JSON), maxScore, score, deadline, passDate` |
| `Assignment` | `id, title, discipline, topic, topicId, deadline, status` |
| `Digest` | Однострочник + список `DigestEvent`-ов (могут содержать `topicId/lessonId/assignmentId/disciplineId` для навигации) |
| `DiaryEntry` | `discipline, topic, topicId, date, attendance` |
| `Profile` | `…, learningGroupId, groupMates: [GroupMate]` |
| `GroupMate` | `id, firstName, lastName, middleName, email, avatar, fullName, initials` |

## Дизайн-система

**Стеклянный эффект** — основной визуальный примитив:
```swift
.glassEffect(.regular, in: .rect(cornerRadius: 22))
.glassEffect(.regular.tint(.orange.opacity(0.18)), in: .rect(cornerRadius: 20))
.glassEffect(.regular, in: .capsule)
.glassEffect(.regular, in: .circle)
```

**Ключевые компоненты** (`Components.swift`):
- `GlassCard` — обёртка с padding + glassEffect
- `LessonRow` — строка пары (с `.contentShape(Rectangle())`)
- `AttendanceBadge` — бейдж посещаемости (compact и полный)
- `AttendanceDot` — цветная точка статуса (online ≡ present)
- `AttendanceBar` — прогресс-бар посещаемости (≥75% зелёный, ≥50% жёлтый, иначе красный)
- `CountTile` — плитка с числом
- `DisclosureRow` — строка меню с chevron
- `SectionHeader`, `LateBanner`, `DayChip`, `FilterPill`

**Hit area**: все карточки которые служат `label:` у `NavigationLink` имеют `.contentShape(Rectangle())` чтобы кликабельной была вся область, а не только текст.

**Типографика**: системные шрифты, `.monospacedDigit()` для чисел и времени, `.tracking(0.5–0.6)` для uppercase-подписей.

**Отступы**: горизонтальный padding 18pt, bottom 32pt, spacing между секциями 18pt.

## Editor.js

Тело контент-блоков темы (`TopicContentBlock.body`) приходит как JSON в формате [Editor.js](https://editorjs.io/). Парсит `EditorJSParser.parse(_:)`, рендерит `EditorContentView(blocks:)`. Поддерживаемые блоки: `header` (h1–h4), `paragraph`, `list` (ordered/unordered), `table` (с горизонтальным скроллом), `quote`, `delimiter`, `image` (через `AsyncImage`, поддерживает `data.file.url` и `data.url`), `embed` (видео — открывается ссылкой). Inline-HTML внутри текста (`<strong>`, `<em>`, `<u>`, `<br>`, `&nbsp;`, `&lt;` …) разбирается в `AttributedString` через `InlineHTML.attributed(_:)`. Если строка не Editor.js — фолбэк на inline-HTML рендер.

## Билды и версия

- `MARKETING_VERSION = 1` (хардкод в pbxproj)
- `CURRENT_PROJECT_VERSION` = значение из `NewLXP/BuildNumber.txt`, инкрементится скриптом `scripts/bump-build.sh` на каждой сборке (build phase «Bump build number», `alwaysOutOfDate=YES`). Скрипт читает счётчик, +1, перезаписывает файл и патчит `CFBundleVersion` в `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` через `PlistBuddy`.
- `ENABLE_USER_SCRIPT_SANDBOXING = NO` (иначе скрипт не имеет доступа к файлам).

В UI билд показывается на экране «О приложении» (`AboutView`) рядом с версией, плюс модель устройства и iOS-версия через `UIDevice.current`.

## Иконка

Лежит в `Assets.xcassets/AppIcon.appiconset/`: `icon_light.png`, `icon_dark.png`, `icon_tinted.png` (1024×1024). Сгенерированы Python-скриптом с PIL.

## Локализация

Интерфейс на русском. Форматирование дат через `Locale(identifier: "ru_RU")`.

## Сборка из CLI

```bash
DEVELOPER_DIR=/Applications/Xcode-26.4.0.app/Contents/Developer xcodebuild \
  -project NewLXP.xcodeproj -scheme NewLXP \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Кодген GraphQL

После изменения `*.graphql` или `schema.graphqls`:
```bash
./apollo-ios-cli fetch-schema   # обновить схему
./apollo-ios-cli generate --ignore-version-mismatch
```

Конфигурация — `apollo-codegen-config.json`. `--ignore-version-mismatch` нужен потому, что CLI 2.0.3, а Apollo iOS pinned на минорно-разной версии 2.x.
