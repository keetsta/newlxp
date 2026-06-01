# NewLXP — ITHub LXP iOS Client

iOS-приложение — клиент образовательной платформы LXP колледжа ITHub. Минималистичный дизайн со «стеклянными» поверхностями. Привязано к боевому API `https://api.newlxp.ru/graphql`.

## Стек

- **Swift / SwiftUI** — только SwiftUI, минимально UIKit (только `UIDevice` для версии ОС, `UIImage` в `RemoteImageLoader`)
- **iOS 16.0+** (deployment target). UI работает на iOS 16-25, на iOS 26+ автоматически включается нативный `.glassEffect`. См. раздел «Совместимость».
- **Xcode** — проект в `NewLXP.xcodeproj`, открывать Xcode 26.4+
- **Apollo iOS 2.0.3** — GraphQL клиент, подключён через SPM
- **apollo-ios-cli 2.0.3** — лежит в корне проекта, кодген запускается командой `./apollo-ios-cli generate --ignore-version-mismatch`

## Совместимость и iOS-API

Минималка — **iOS 16**. Всё, что появилось позже, обёрнуто в `#available` или заменено на старый API:

- **Стеклянный эффект** — только через хелперы `lxpGlass(cornerRadius:tint:)`, `lxpGlassCapsule(tint:)`, `lxpGlassCircle(tint:)` из `GlassEffect.swift`. Внутри: `if #available(iOS 26.0, *) { .glassEffect(...) } else { .background(.ultraThinMaterial) + tint + thin border }`. Никогда не звать `.glassEffect` напрямую — фолбэк не сработает.
- **Стор** — `AppStore: ObservableObject` + `@Published`, во вьюхах `@EnvironmentObject`, в `LoginView` — `@ObservedObject`, в `NewLXPApp` — `@StateObject`. `@Observable` / `@Bindable` / `@Environment(AppStore.self)` НЕ использовать (iOS 17+).
- **TabView** — старый API `.tabItem { Label(...) }`. `Tab(...)` struct и `tabBarMinimizeBehavior` НЕ использовать (iOS 18+).
- **Анимации** — `.spring(response:dampingFraction:)` или `.easeInOut`. `.snappy` НЕ использовать (iOS 17+).
- **`onChange`** — старый синтаксис с одним параметром (`{ newValue in ... }`), НЕ новый `{ old, new in ... }` (iOS 17+).

При добавлении новой фичи проверяй availability нового API (Apple Docs → Availability). Если фича есть только на iOS 17+, либо обернуть в `#available`, либо найти эквивалент.

## Логирование

`print(...)` напрямую НЕ использовать. Только `LXPLog.debug("...")` из `Logging.swift` — он обёрнут в `#if DEBUG` и no-op в Release. Префиксы в строках сохраняем (`[LXP]`, `[Cache]`, `[LXP][img]`) для удобной фильтрации в консоли.

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
- `studentDisciplinesThroughClassesWithPagination` возвращает дубликаты по `name` (разные ID для разных семестров/групп) — склеиваем в `loadDisciplines` суммируя часы (но `maxScore` берём максимальный, не сумму — это нормировка, а не количество).
- Возвращает также записи прошлых семестров с `archivedAt = null` — фильтр через `activeDisciplines` (нужно ≥3 пары в кэше расписания, иначе считаем артефактом).
- `pageSize > 50` отвергается сервером.
- `studentId` для студента совпадает с `user.id` (один UUID), но всё равно ходим за `student.id` через `getMe`.
- **Баллы по дисциплине**: брать ТОЛЬКО `getStudentDiscipline.scoreForAnsweredTasks` / `.maxScoreForAnsweredTasks`. Не пересчитывать вручную из `topics[]`: `topicScore` иногда превышает `topic.maxScore` (бонусные баллы), темы дублируются через learning paths, и сумма `topic.maxScore` не равна знаменателю сайта. Сервер сам всё знает.
- `topicScore = 0` не означает «препод поставил 0» — может быть «ещё не оценено». Финальные оценки — статус `passed/failed/mastered/notMastered/overdue`.
- При сетевой ошибке «Сессия истекла» / «session expired» / «unauthorized» / «jwt expired» в `Networking.swift` автоматически дёргается `AuthRepository.refresh()` (один раз, через actor-координатор чтобы не было гонки). Если refresh упал — `TokenStore.clear()` + `isAuthenticated = false`, юзер на логине.

## Структура файлов

```
NewLXP/
├── NewLXPApp.swift          — @main, RootView (LoginView vs ContentView), bootstrap(), preferredColorScheme, ErrorBanner overlay
├── ContentView.swift        — TabView с тремя вкладками
├── LoginView.swift          — Экран входа (email + password)
├── HomeView.swift           — Главная: герой-карточка, метрики, дайджест, расписание дня
├── ScheduleView.swift       — Расписание + LessonDetailView + TopicDetailView + TopicContentBlockCard
├── ServicesView.swift       — Сервисы и все вложенные экраны (Profile, Assignments, Disciplines, Diary→Успеваемость, AttendanceOverview, Settings, About, GroupList, DigestDetail)
├── Components.swift         — Переиспользуемые компоненты (GlassCard, LessonRow, AttendanceBar, ProgressBar, CountTile, DisclosureRow, SectionHeader, LateBanner, DayChip, FilterPill, RussianPlural)
├── Models.swift             — UI-модели (Lesson, Discipline, DisciplineDetail, Topic, TopicDetail, TopicContentBlock, Profile, GroupMate, Assignment, Digest, …) — все Codable
├── AppData.swift            — MockData (пустые дефолты для signOut)
├── AppStore.swift           — ObservableObject singleton-стор: всё состояние, загрузка, дайджест, посещаемость, баллы (scores)
├── Cache.swift              — `DiskCache`: write-through JSON-кэш под `Library/Caches/LXPCache/` для тёплого старта
├── GlassEffect.swift        — `lxpGlass*` хелперы со SafeFallback на iOS 16-25 (`.ultraThinMaterial`)
├── AvatarView.swift         — Аватарка по URL через `RemoteImageLoader` + инициалы-фолбэк
├── Skeleton.swift           — Shimmer-плейсхолдеры (SkeletonRect, SkeletonLessonRow, SkeletonDisciplineCard, SkeletonAssignmentCard) для холодного старта
├── ErrorBanner.swift        — Транзиентный toast подписан на `store.lastError`, всплывает на 5 сек
├── Logging.swift            — `LXPLog.debug(...)` — `print` обёрнутый в `#if DEBUG`
├── Networking.swift         — TokenStore + Apollo client + AuthHeadersInterceptor + LXPError + автообновление токена (TokenRefreshCoordinator)
├── Repositories.swift       — Auth/Profile/Schedule/Disciplines/Tasks/Topic — обёртки над Apollo
├── Mapping.swift            — GraphQL enum → UI enum (attendance, topic status), DateFormatters
├── EditorContent.swift      — Парсер Editor.js + InlineHTML → AttributedString + SwiftUI рендер + RemoteImageLoader
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
- **Расписание** (`ScheduleView`) — листание по неделям (стрелки + кнопка «Сегодня» в тулбаре), week strip 7 дней, сводка посещаемости за просматриваемую неделю (`weekAttendance(forAnchor:)`), список пар дня. При выборе дня вне загруженного диапазона зовётся `store.ensureScheduleAround(date)`
- **Сервисы** (`ServicesView`) — профиль, плитки заданий и дисциплин, меню (успеваемость / посещаемость / о приложении), шестерёнка → SettingsView. Внутри:
  - **Успеваемость** (`DiaryView`) — журнал баллов и оценок 2-5 по активным дисциплинам. Заголовок дисциплины кликабелен → `DisciplineDetailView`. Список оценённых тем под ним кликабелен → `TopicDetailView`. Длинные списки сворачиваются с лимитом 3.
  - **Посещаемость** (`AttendanceOverviewView`) — переключатель Неделя/Месяц + навигация ‹›-стрелками по прошлым периодам. Строки дисциплин кликабельны → `DisciplineDetailView`. При уходе глубже -60 дней зовётся `ensurePastSchedule(days:)`.
  - **Настройки** — только цветовая тема (Системная / Светлая / Тёмная) через `@AppStorage("appearance")` + `.preferredColorScheme(...)` на корне, и кнопка выхода.

Детальные экраны через `NavigationLink` в каждом NavigationStack. Экран темы (`TopicDetailView`) — общий и используется отовсюду: из карточки пары, из списка тем дисциплины, из дайджеста, из успеваемости, из заданий (`Assignment` ведёт сразу в свою тему по `topicId`, отдельной AssignmentDetailView нет).

## Стор и загрузка данных

Всё состояние держит `AppStore.shared` (`final class AppStore: ObservableObject @MainActor`). Поля помечены `@Published`. Во вьюхах подписка через `@EnvironmentObject private var store: AppStore`. В `NewLXPApp` инжектится `@StateObject` + `.environmentObject(store)`. `RootView` смотрит на `store.isAuthenticated`.

Жизненный цикл:
1. `AppStore.init()` синхронно вызывает `hydrateFromCache()` — стор заполняется данными прошлого запуска из `DiskCache`. UI рендерится мгновенно.
2. `NewLXPApp.task` → `store.bootstrap()` (если есть токен) → `refreshAll`: сначала `loadProfile` (даёт `studentId`), затем параллельно через `withTaskGroup`: `loadSchedule`, `loadDisciplines`, `loadAssignments`. Если `studentId` уже сохранён в `TokenStore`, профиль грузится параллельно с остальным.
3. После `signIn` тоже зовётся `refreshAll`.
4. После каждой успешной сетевой загрузки — write-through в `DiskCache` (отдельный JSON-файл на ключ).

Кеши:
- **In-memory** (на сторе): `lessonsByDay: [Date: [Lesson]]` + `loadedRanges: [DateInterval]` — повторно одну неделю не качаем. `disciplineDetails: [String: DisciplineDetail]`, `topicDetails: [String: TopicDetail]` — лениво по запросу.
- **На диске** (`Library/Caches/LXPCache/*.json`, ключи `Profile/lessonsByDay/loadedRanges/disciplines/disciplineDetails/topicDetails/assignments`): сериализуются как `Codable` через `JSONEncoder`/`JSONDecoder` с `dateEncodingStrategy = .iso8601`. Все UI-модели — `Codable`. На decode-ошибке файл удаляется. **Почему JSON, а не Core Data**: данные мелкие (<100К суммарно), структура — это уже Swift-коллекции, никаких запросов по полям не нужно, миграции дешёвые (упал decode → грузим с сети). Core Data была бы оверкилл.
- При signOut и `TokenStore.clear()` чистится `MockData` (пустые) И `DiskCache.clearAll()`.

Производные данные (computed на сторе):
- `dailyDigest: Digest` — собирается из ближайшей пары (с `topicId`), открытых дедлайнов (с `topicId`), просроченных, итога по парам сегодня, посещаемости за неделю.
- `activeDisciplines: [Discipline]` — фильтр от мусора прошлых семестров: дисциплина считается активной если у неё в загруженном расписании ≥3 пар. Фолбэк — полный список, если расписание ещё не пришло.
- `scores(disciplineId:) -> ScoreMetric?` — баллы дисциплины: `earned` / `assigned` / `maxScore` берутся напрямую из `getStudentDiscipline.scoreForAnsweredTasks` / `maxScoreForAnsweredTasks` / `discipline.maxScore`. Шкала 2-5: <50%→2, <70%→3, <90%→4, ≥90%→5. Возвращает `nil` если стор ещё не загружен.
- `attendance(in: ClosedRange<Date>) -> AttendanceMetric`, `attendanceFor(disciplineTitle:in:)` — учитывают только пары с `attendance.hasVerdict`. Только `.absent` снимает часы.
- `weekAttendance()` / `monthAttendance()` — текущие календарные неделя (пн→сейчас) / месяц (1-е→сейчас).
- `weekAttendance(forAnchor:)` — для произвольной недели (пн→вс или пн→сейчас если это текущая).
- `pastLessons` — все прошедшие пары, отсортированные по убыванию даты.

## Модели данных

| Модель | Назначение |
|---|---|
| `Lesson` | Пара: `id, order, discipline, disciplineId, topic, topicId, teacher, location, start, end, attendance, lateMinutes, meetingLink, isOnline` |
| `AttendanceStatus` | `.present / .online / .absent / .noMark / .scheduled`. У `.absent` `tint == .red`, у `.noMark` — серый. `.online` (любой `EXIST_ONLINE`, с причиной или без) считается присутствием и зелёный. `hasVerdict` — true только для present/online/absent |
| `Discipline` | `id, title, code, totalHours, maxScore` (нормировка дисциплины, обычно 100) |
| `DisciplineDetail` | `discipline, topics, learningGroupId, scoreForAnsweredTasks, maxScoreForAnsweredTasks` (последние два — числитель/знаменатель оценки 2-5 от сервера) |
| `Topic` | `id, number, title, isCheckpoint, status: TopicProgress, score, maxScore, hours` |
| `TopicProgress` | `.notStarted / .inProgress / .passed / .failed / .checkpoint` (маппится из `LXPSchema.TopicStatus`) |
| `TopicDetail` | `topic, howToStudy?, blocks: [TopicContentBlock]` |
| `TopicContentBlock` | `id, kind: .info/.task/.test, name, body (Editor.js JSON), maxScore, score, deadline, passDate` |
| `Assignment` | `id, title, discipline, topic, topicId, deadline, status` |
| `Digest` | Однострочник + список `DigestEvent`-ов (могут содержать `topicId/lessonId/assignmentId/disciplineId` для навигации) |
| `Profile` | `…, avatar?, learningGroupId, groupMates: [GroupMate]` |
| `GroupMate` | `id, firstName, lastName, middleName, email, avatar, fullName, initials` |
| `AppStore.ScoreMetric` | `earned, assigned, maxScore` + computed `rate`, `fullRate`, `grade: Int?` |

Все модели `Codable` — кэшируются в `DiskCache`. У моделей с эволюционирующей схемой (`Discipline`, `DisciplineDetail`, `Profile`) — кастомный `init(from:)` с `decodeIfPresent`, чтобы старый JSON в кэше не выкидывался при добавлении полей.

## Дизайн-система

**Стеклянный эффект** — основной визуальный примитив, всегда через хелперы из `GlassEffect.swift`:
```swift
.lxpGlass(cornerRadius: 22)
.lxpGlass(cornerRadius: 20, tint: .orange.opacity(0.18))
.lxpGlassCapsule()
.lxpGlassCapsule(tint: .primary.opacity(0.18))
.lxpGlassCircle()
```
Никогда не вызывать `.glassEffect(...)` напрямую — пропустишь iOS 16-25 фолбэк (`.ultraThinMaterial` + тонкая обводка).

**Ключевые компоненты** (`Components.swift`):
- `GlassCard` — обёртка с padding + glassEffect
- `LessonRow` — строка пары (с `.contentShape(Rectangle())`)
- `AttendanceBadge` — бейдж посещаемости (compact и полный)
- `AttendanceDot` — цветная точка статуса (online ≡ present)
- `AttendanceBar` — прогресс-бар посещаемости (≥75% зелёный, ≥50% жёлтый, иначе красный)
- `ProgressBar(rate:color:)` — универсальный, цвет задаётся снаружи (например, по оценке)
- `CountTile` — плитка с числом
- `DisclosureRow` — строка меню с chevron
- `SectionHeader`, `LateBanner`, `DayChip`, `FilterPill`
- `RussianPlural` — русские склонения (one/few/many) + accusative для «через N минут»
- `AvatarView` (`AvatarView.swift`) — кружок-аватар с RemoteImageLoader-кэшем и фолбэком на инициалы
- `GradePill` — цветная пилюля 2-5 (`ServicesView.swift`)
- Skeleton (`Skeleton.swift`): `SkeletonRect`, `SkeletonLessonRow`, `SkeletonDisciplineCard`, `SkeletonAssignmentCard` — shimmer placeholders при холодном старте (вьюхи показывают их когда стор пустой И нет `lastError`).
- `ErrorBanner` (`ErrorBanner.swift`) — транзиентный toast в `RootView`, подписан на `store.lastError`.

**Hit area**: все карточки которые служат `label:` у `NavigationLink` имеют `.contentShape(Rectangle())` чтобы кликабельной была вся область, а не только текст.

**Типографика**: системные шрифты, `.monospacedDigit()` для чисел и времени, `.tracking(0.5–0.6)` для uppercase-подписей.

**Отступы**: горизонтальный padding 18pt, bottom 32pt, spacing между секциями 18pt.

## Editor.js

Тело контент-блоков темы (`TopicContentBlock.body`) приходит как JSON в формате [Editor.js](https://editorjs.io/). Парсит `EditorJSParser.parse(_:)`, рендерит `EditorContentView(blocks:)`. Поддерживаемые блоки: `header` (h1–h4), `paragraph`, `list` (ordered/unordered), `table` (с горизонтальным скроллом), `quote`, `delimiter`, `image` (через `RemoteImage` + `RemoteImageLoader` с in-memory кэшем, поддерживает `data.file.url`, `data.url`, `data.src`), `embed` (видео — открывается ссылкой). Inline-HTML внутри текста (`<strong>`, `<em>`, `<u>`, `<br>`, `&nbsp;`, `&lt;` …) разбирается в `AttributedString` через `InlineHTML.attributed(_:)`. Если строка не Editor.js — фолбэк на inline-HTML рендер.

## Билды и версия

- `MARKETING_VERSION = 1` (хардкод в pbxproj)
- `CURRENT_PROJECT_VERSION` = значение из `NewLXP/BuildNumber.txt`, инкрементится скриптом `scripts/bump-build.sh` на каждой сборке (build phase «Bump build number», `alwaysOutOfDate=YES`). Скрипт читает счётчик, +1, перезаписывает файл и патчит `CFBundleVersion` в `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` через `PlistBuddy`.
- `ENABLE_USER_SCRIPT_SANDBOXING = NO` (иначе скрипт не имеет доступа к файлам).

В UI билд показывается на экране «О приложении» (`AboutView`) рядом с версией, плюс модель устройства и iOS-версия через `UIDevice.current`.

## Иконка

Лежит в `Assets.xcassets/AppIcon.appiconset/`: `icon_light.png`, `icon_dark.png`, `icon_tinted.png` (1024×1024). Сгенерированы Python-скриптом с PIL.

## Локализация

Интерфейс на русском, single-language. `Locale("ru_RU")` хардкодится в `DateFormatter`-ах — это нужно чтобы даты («понедельник», «1 июня») форматировались по-русски независимо от системной локали устройства. Это **не i18n**, это управление форматом дат. String Catalog тут не помогает — даты строятся из локали. Если когда-нибудь понадобится англ — заменить на `.current` и завести каталог.

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
