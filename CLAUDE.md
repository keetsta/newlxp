# NewLXP — ITHub LXP iOS Client

iOS-приложение — клиент образовательной платформы LXP колледжа ITHub. Минималистичный дизайн под iOS 26 с использованием `.glassEffect`.

## Стек

- **Swift / SwiftUI** — только SwiftUI, без UIKit
- **iOS 26+** — используется `.glassEffect`, `.tabBarMinimizeBehavior`, нативный `Tab` API
- **Xcode** — проект в `NewLXP.xcodeproj`

## Структура файлов

```
NewLXP/
├── ContentView.swift     — TabView с тремя вкладками
├── HomeView.swift        — Главная: герой-карточка, метрики, дайджест, расписание дня
├── ScheduleView.swift    — Расписание: week strip, список пар по дате + все detail views пар
├── ServicesView.swift    — Сервисы: профиль, задания, дисциплины, дневник, посещаемость + все вложенные экраны
├── Components.swift      — Переиспользуемые компоненты (GlassCard, LessonRow, AttendanceBadge, CountTile и др.)
└── Models.swift          — Модели данных + MockData (весь контент — моковый)
```

## Навигация

Три вкладки в `TabView`:
- **Главная** (`HomeView`) — текущая/следующая пара, метрики дня, дайджест, список пар сегодня
- **Расписание** (`ScheduleView`) — week strip (±3 дня от сегодня), сводка посещаемости, список пар выбранного дня
- **Сервисы** (`ServicesView`) — профиль, задания, дисциплины, дневник, посещаемость, настройки

Детальные экраны открываются через `NavigationLink` внутри `NavigationStack` каждой вкладки.

## Модели данных

Все данные — статичный `MockData`. Реального API нет.

| Модель | Назначение |
|---|---|
| `Lesson` | Пара: дисциплина, тема, преподаватель, аудитория, время, посещаемость |
| `AttendanceStatus` | `.present / .onlineOfficial / .onlineNoReason / .absent / .scheduled` |
| `Discipline` | Дисциплина с часами и посещаемостью |
| `Topic` | Тема дисциплины (может быть checkpoint) |
| `Assignment` | Задание с дедлайном и статусом |
| `Digest` | Ежедневный дайджест (однострочник + тело) |
| `DiaryEntry` | Запись дневника (пройденная тема) |
| `Profile` | Профиль студента |

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
- `LessonRow` — строка пары (время | разделитель | дисциплина/тема/аудитория + dot)
- `AttendanceBadge` — бейдж посещаемости (compact и полный)
- `AttendanceDot` — цветная точка статуса
- `AttendanceBar` — прогресс-бар посещаемости (зелёный ≥75%, жёлтый ≥50%, красный)
- `CountTile` — плитка с числом и иконкой
- `DisclosureRow` — строка меню с chevron
- `SectionHeader` — заголовок секции (uppercase, tracking)
- `LateBanner` — баннер опоздания с оранжевым tint
- `DayChip` — чип дня в week strip
- `FilterPill` — фильтр-таблетка

**Типографика**: системные шрифты, `.monospacedDigit()` для чисел и времени, `.tracking(0.5–0.6)` для uppercase-подписей.

**Отступы**: горизонтальный padding 18pt, bottom 32pt, spacing между секциями 18pt.

## Локализация

Интерфейс на русском языке. Форматирование дат через `Locale(identifier: "ru_RU")`.
