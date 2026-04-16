`FirstPetProject` — iOS-приложение на `SwiftUI` для сценария кафе:

- на вкладке `Меню` собираешь заказ;
- на экране `Итог` выбираешь чаевые и количество людей;
- сохраняешь чек;
- на вкладках `История` и `Статистика` видишь сохраненные данные;
- в `Настройках` переключаешь тему.

Это хороший учебный пример, потому что тут есть сразу:

- UI на SwiftUI;
- разделение на слои (Domain/Presentation);
- навигация и табы;
- локальная база данных (`SwiftData`);
- базовая аналитика (средние значения, график).

---

Проект разделен на 2 слоя:

1. **Domain** — бизнес-правила и данные предметной области.
2. **Presentation** — интерфейс и состояние экрана.

Зачем это нужно:

- UI меняется часто, бизнес-правила — реже;
- код проще тестировать;
- проект легче расширять без “каши”.

Правило зависимости:

- `Presentation` может использовать `Domain`;
- `Domain` не должен зависеть от `SwiftUI`.

---

## Структура проекта

```text
FirstPetProject/
  FirstPetProjectApp.swift

  Domain/
    Data/
      MenuRepository.swift
    Entities/
      CheckRecord.swift
      MenuItem.swift
      TipCalculation.swift
    Router/
      AppRoute.swift
    Services/
      CheckCurrencyFormatter.swift
    UseCases/
      CalculateTipUseCase.swift
      SaveCheckUseCase.swift
      FetchChecksUseCase.swift
      CheckStatsUseCase.swift

  Presentation/
    Theme/
      AppTheme.swift
      AppShellState.swift
    ViewModel/
      MenuViewModel.swift
      TipCalculatorViewModel.swift
      HistoryViewModel.swift
      StatsViewModel.swift
    Views/
      MenuView.swift
      SummaryView.swift
      HistoryView.swift
      StatsView.swift
      SettingsView.swift
```

---

## Как приложение стартует

Точка входа: `FirstPetProjectApp.swift`.

Там создается `RootView`, и к нему подключаются:

- глобальные состояния через `.environment(...)`;
- общий контейнер данных SwiftData через `.modelContainer(for: CheckRecord.self)`.

Почему это критично:

- `SummaryView` сохраняет `CheckRecord` в `modelContext`;
- `HistoryView` и `StatsView` читают `CheckRecord` через `@Query`;
- если общего `modelContainer` нет, экраны не видят общие данные.

---

## Навигация и вкладки

### 1) Вкладки (`TabView`)

В `RootView` есть основные разделы:

- `Меню`
- `Настройки`
- `История`
- `Статистика`

Текущая вкладка хранится в `AppShellState`.

### 2) Навигация внутри вкладки (`NavigationStack`)

Внутри вкладки меню используется стек переходов:

- `MenuView` -> `SummaryView`

Маршруты описаны enum-ом `AppRoute`.  
Это типобезопасно: нельзя случайно передать “не тот” экран и “не те” данные.

---

## Модели данных (Entities)

## `MenuItem`

Описывает позицию меню:

- название, цена, категория, emoji, описание.

## `MenuOrderItem`

Связка:

- какая позиция выбрана;
- в каком количестве.

## `TipCalculation`

Результат расчета:

- сумма чека;
- процент чаевых;
- итог;
- сумма на человека.

## `CheckRecord` (`@Model`, SwiftData)

Сущность для сохранения чека в локальную базу:

- дата;
- сумма счета;
- процент/сумма чаевых;
- итог;
- число людей;
- список названий блюд.

---

## Use Case-ы: где живет “действие”

Use Case = одна бизнес-операция.

### `CalculateTipUseCase`

Считает чаевые и итог по входным параметрам.

### `SaveCheckUseCase`

Сохраняет `CheckRecord` в `ModelContext`.

### `FetchChecksUseCase`

Достает список чеков, сортируя по дате (новые выше).

### `CheckStatsUseCase`

На основе массива чеков считает:

- средний чек;
- средний процент чаевых;
- общую потраченную сумму;
- количество чеков;
- последние 7 сумм для графика.

Почему так:

- UI не знает “как именно считать” и “как именно сохранять”;
- UI просто вызывает действие.

---

## Экран `Menu`: как работает

Файлы:

- `MenuView.swift`
- `MenuViewModel.swift`
- `MenuRepository.swift`

Поток:

1. `MenuRepository` отдает список блюд.
2. `MenuViewModel` хранит выбранные количества.
3. `MenuView` показывает список и кнопки `+/-`.
4. Когда заказ не пустой, появляется нижняя панель с итогом.
5. Кнопка “Далее” делает `router.push(.summary(items:..., total:...))`.

Почему это хорошо:

- логика подсчета не в View;
- View остается “тонкой” и читаемой.

---

## Экран `Summary`: как работает

Файл: `SummaryView.swift`.

Что происходит:

1. Экран получает `orderItems` и `orderTotal`.
2. Создает `TipCalculatorViewModel` и подставляет сумму заказа.
3. Пользователь меняет процент чаевых и число людей.
4. ViewModel пересчитывает `TipCalculation`.
5. По кнопке “Сохранить чек” создается `CheckRecord`.
6. Вызывается `SaveCheckUseCase`.

Идея:

- экран показывает UI;
- ViewModel + UseCase делают вычисления и сохранение.

---

## Экраны `History` и `Stats`

### `HistoryView`

- читает записи через `@Query(sort: \CheckRecord.date, order: .reverse)`;
- показывает список сохраненных чеков;
- раскрывает детали по тапу.

### `StatsView`

- тоже читает записи через `@Query`;
- при изменении `records` пересчитывает статистику;
- показывает карточки и график (`Charts`) по последним чекам.

Почему данные обновляются автоматически:

- `@Query` подписан на изменения SwiftData;
- после `context.save()` обновление прилетает в UI.

---

## Темы и визуальная система

Файлы:

- `AppTheme.swift`
- `SettingsView.swift`

Принцип:

- вместо “жестких” цветов везде используются семантические цвета из `AppPalette`;
- тема переключается через `AppSettings`;
- `RootView` применяет ее через `.preferredColorScheme(...)`.

Почему это правильно:

- менять дизайн можно централизованно;
- меньше дублирования;
- легко добавить новые темы позже.

---

## Как читать этот проект, если ты учишь Swift с нуля

Рекомендуемый порядок:

1. `FirstPetProjectApp.swift` — понять старт приложения.
2. `AppRoute.swift` + `AppShellState.swift` — навигация и вкладки.
3. `MenuItem.swift`, `TipCalculation.swift`, `CheckRecord.swift` — модели.
4. `CalculateTipUseCase.swift` — базовая бизнес-логика.
5. `MenuViewModel.swift` и `TipCalculatorViewModel.swift` — состояние экрана.
6. `MenuView.swift` и `SummaryView.swift` — UI.
7. `SaveCheckUseCase`, `FetchChecksUseCase`, `CheckStatsUseCase` — работа с данными.
8. `HistoryView.swift`, `StatsView.swift` — отображение сохраненных данных.

Так ты идешь от “фундамента” к UI, а не наоборот.

---

## Почему проект написан именно так

- **Через слои** — чтобы было проще развивать и тестировать.
- **Через UseCase-ы** — чтобы бизнес-действия были явными и переиспользуемыми.
- **Через `@Query` + SwiftData** — чтобы хранить данные локально и автоматически обновлять UI.
- **Через enum-маршруты** — чтобы навигация была безопасной и понятной.
- **Через палитру темы** — чтобы интерфейс был консистентным и масштабируемым.

Это уже близко к подходу “как в реальных прод-проектах”, только в учебно-простой форме.

---

## Практика: как доучиваться на этом проекте

Сделай по очереди такие задачи:

1. Добавь новую категорию блюд и 3 позиции.
2. Добавь “сервисный сбор 5%” как отдельный UseCase.
3. Добавь фильтр истории “за последние 7 дней”.
4. Добавь новую карточку в статистику (например, “максимальный чек”).
5. Напиши 3 unit-теста для `CalculateTipUseCase`.

Если после каждой задачи ты можешь объяснить:

- где хранится состояние;
- где вычисления;
- где отображение;

значит ты реально учишь Swift, а не копируешь код.

---

## Частые вопросы новичка

**Почему столько файлов, нельзя ли все в одном?**  
Можно, но тогда быстро появится хаос. Разделение заранее экономит время.

**Почему ViewModel и UseCase отдельно?**  
ViewModel управляет состоянием экрана, UseCase — бизнес-действием. Это разные ответственности.

**Зачем протоколы у UseCase?**  
Для подмены реализаций в тестах и более гибкой архитектуры.

**Почему `@Model` только у `CheckRecord`?**  
Потому что сохраняем только чеки. `MenuItem` и `TipCalculation` — чистые модели в памяти.

---

## Следующий шаг

Если хочешь, следующим сообщением я сделаю для тебя продолжение:

- **“План обучения Swift на 4 недели”** прямо на основе этого проекта;
- с ежедневными маленькими задачами и проверочными вопросами “понял/не понял”.
# FirstPetProject

Учебный iOS-проект на `SwiftUI`, в котором ты одновременно изучаешь:
- структуру приложения (слои, роутинг, состояние),
- современный UI (карточки, градиенты, анимации),
- масштабируемость (темы, настройки, табы).

Проект сейчас работает как мини-приложение кафе:
1. На вкладке **Меню** собираешь заказ.
2. На экране **Итог** видишь разбивку, чаевые и сумму на человека.
3. На вкладке **Настройки** переключаешь тему (тёмная/светлая).

---

## Что уже реализовано

- архитектура с разделением на `Domain` и `Presentation`;
- типобезопасная навигация через `NavigationStack` + `AppRoute`;
- глобальные настройки приложения через `@Environment` (`AppSettings`);
- отдельная система тем (`AppThemeMode`, `AppPalette`);
- кастомный UI с анимациями и аккуратной декомпозицией на подкомпоненты;
- экран ручного ввода чека (`TipCalculatorView`) удалён, теперь основной flow: `Menu -> Summary`.

---

## Технологии

- **Swift 5+** — язык.
- **SwiftUI** — UI и декларативная сборка экранов.
- **Observation API**:
  - `@Observable` — реактивные модели (`ViewModel`, `Router`, `Settings`);
  - `@State` — владение объектом внутри View;
  - `@Environment` — доступ к глобальным объектам (router/settings/shell).
- **NavigationStack** — навигация внутри вкладки.
- **TabView** — корневые вкладки приложения (Меню/Настройки).
- **Foundation** — `UUID`, форматтеры, базовые типы.

---

## Актуальная структура проекта

```text
FirstPetProject/
  FirstPetProjectApp.swift
    # RootView: TabView + NavigationStack + environment-объекты

  Domain/
    Data/
      MenuRepository.swift
      # Статический источник данных меню

    Entities/
      MenuItem.swift
      TipCalculation.swift
      # Бизнес-модели без UI-зависимостей

    Router/
      AppRoute.swift
      # Маршруты и AppRouter

    UseCases/
      CalculateTipUseCase.swift
      # Бизнес-операция расчета чаевых

  Presentation/
    Theme/
      AppTheme.swift
      # AppSettings + AppPalette + AppThemeMode + Color(hex:)
      AppShellState.swift
      # Выбранная вкладка приложения (menu/settings)

    ViewModel/
      MenuViewModel.swift
      TipCalculatorViewModel.swift

    Views/
      MenuView.swift
      SummaryView.swift
      SettingsView.swift
```

---

## Как приложение устроено сверху вниз

### 1) Root: `FirstPetProjectApp.swift`

`RootView` держит три глобальных состояния:
- `AppRouter` — навигация внутри stack;
- `AppSettings` — тема и палитра;
- `AppShellState` — активная вкладка.

Упрощённо:

```swift
TabView(selection: $shellState.selectedTab) {
    NavigationStack(path: $router.path) {
        MenuView()
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .summary(let items, let total):
                    SummaryView(orderItems: items, orderTotal: total)
                }
            }
    }
    .tag(AppTab.menu)

    SettingsView()
        .tag(AppTab.settings)
}
.environment(router)
.environment(settings)
.environment(shellState)
.preferredColorScheme(settings.themeMode.colorScheme)
```

### 2) Domain

Здесь только предметная логика.

Пример: `TipCalculation` хранит входные данные и вычисляет:
- `tipAmount`
- `totalAmount`
- `amountPerPerson`
- `tipPerPerson`

### 3) Presentation

- `ViewModel` управляет состоянием и действиями;
- `View` только отображает и отправляет события;
- палитра (`AppPalette`) задаёт цвета для UI в обоих режимах темы.

---

## Подробно про экран меню

Файлы:
- `Presentation/Views/MenuView.swift`
- `Presentation/ViewModel/MenuViewModel.swift`
- `Domain/Data/MenuRepository.swift`

### Что делает `MenuViewModel`

- хранит все позиции: `allItems`;
- хранит выбранную категорию: `selectedCategory`;
- хранит заказ как словарь `itemID -> quantity`;
- вычисляет:
  - `filteredItems`,
  - `totalAmount`,
  - `totalQuantity`,
  - `orderedItems`.

Ключевой фрагмент:

```swift
var totalAmount: Double {
    allItems.reduce(0.0) { sum, item in
        let qty = orderItems[item.id] ?? 0
        return sum + item.price * Double(qty)
    }
}
```

### Что делает `MenuView`

Состоит из подкомпонентов:
- `MenuHeaderView`;
- `CategoryFilterBar`;
- `MenuItemRow`;
- `OrderSummaryBar`.

Переход на итог:

```swift
router.push(.summary(
    items: viewModel.orderedItems,
    total: viewModel.totalAmount
))
```

---

## Подробно про экран итогов (`SummaryView`)

`SummaryView` получает `orderItems` и `orderTotal`, затем:
- создаёт `TipCalculatorViewModel`;
- прокидывает `orderTotal` как сумму чека;
- даёт пользователю менять людей и чаевые;
- показывает детальную карточку разбивки.

Дополнительно теперь есть `SummaryQuickActions`:
- кнопка перехода в настройки;
- внутри вызывается:
  - `router.popToRoot()`
  - `shellState.selectedTab = .settings`

Это отличный пример взаимодействия **навигации + табов + глобального состояния**.

---

## Экран настроек (`SettingsView`)

Что есть сейчас:
- переключатель “Тёмная тема”.

Как работает:
- `Toggle` меняет `settings.isDarkMode`;
- это меняет `settings.themeMode`;
- `RootView` через `.preferredColorScheme(...)` и `settings.palette` обновляет весь UI.

---

## Система тем (важно)

`Presentation/Theme/AppTheme.swift`:

- `AppThemeMode` — `dark`/`light`;
- `AppSettings` — single source of truth для темы;
- `AppPalette` — набор семантических цветов.

Идея семантических цветов:
- не пишем в коде “фиолетовый #7C6AF5” напрямую в каждом месте;
- пишем “`palette.accentStart`”, “`palette.surface`”, “`palette.textPrimary`”.

Плюсы:
- легко менять дизайн;
- минимальный риск “забыли перекрасить половину приложения”;
- удобно масштабировать под новые темы.

---

## Анимации в проекте: что и где изучать

В проекте уже много живых примеров анимаций SwiftUI:

- `transition(.move(edge: .bottom).combined(with: .opacity))`
  - появление нижних панелей и карточек;
- `.animation(.spring(...), value: ...)`
  - плавные физичные переходы при смене состояния;
- `.contentTransition(.numericText())`
  - красивое “перетекание” цифр при изменении суммы/количества;
- `.scaleEffect(...)` + `.shadow(...)`
  - акцент на выбранных кнопках/чипах;
- condition-based rendering (`if viewModel.hasOrder { ... }`)
  - анимация появления/скрытия UI при изменении данных.

### Где смотреть код анимаций

- `Presentation/Views/MenuView.swift`
  - анимация счётчика, плашки заказа, карточек.
- `Presentation/Views/SummaryView.swift`
  - анимация итоговых значений, выборов чаевых и секций.

---

## Как добавить новую фичу (практический шаблон)

Пример: “добавить скидку 10% по промокоду”.

1. **Domain**: добавь правило в `CalculateTipUseCase` (или новый UseCase).
2. **ViewModel**: добавь состояние промокода + вызов пересчёта.
3. **View**: добавь поле/кнопку и отобрази результат.
4. **Theme**: при необходимости добавь новые цвета в `AppPalette`.
5. **README**: обнови документацию под новую логику (очень полезная привычка).

---

## Что и где менять быстро (шпаргалка)

- изменить меню позиций: `Domain/Data/MenuRepository.swift`;
- изменить модель позиции: `Domain/Entities/MenuItem.swift`;
- изменить бизнес-формулы чаевых: `Domain/UseCases/CalculateTipUseCase.swift` и/или `Domain/Entities/TipCalculation.swift`;
- изменить логику выбора и подсчёта заказа: `Presentation/ViewModel/MenuViewModel.swift`;
- изменить внешний вид экрана меню: `Presentation/Views/MenuView.swift`;
- изменить итоговый экран и панель перехода в настройки: `Presentation/Views/SummaryView.swift`;
- изменить тему/палитру: `Presentation/Theme/AppTheme.swift`;
- изменить вкладки: `FirstPetProjectApp.swift` + `Presentation/Theme/AppShellState.swift`.

---

## Почему старый `TipCalculatorView` удалён

Ранее был отдельный экран ручного ввода суммы чека.  
Сейчас UX логичнее:
- пользователь сначала собирает заказ;
- сумма приходит автоматически в `Summary`;
- там же выбираются чаевые и количество людей.

Это уменьшает лишние шаги и лучше отражает сценарий “заказ в кафе”.

---

## Мини-словарь терминов

- `@Observable` — автоматическое обновление UI при изменении свойств.
- `@State` — владение состоянием внутри конкретной View.
- `@Environment` — внедрение зависимостей “сверху вниз”.
- `TabView` — переключение между корневыми разделами.
- `NavigationStack` — стек переходов внутри раздела.
- `UseCase` — одна бизнес-операция.
- `Entity` — чистая модель предметной области.
- `Computed property` — вычисляемое свойство без хранения.

---

## Что полезно добавить следующим шагом

- сохранение темы в `UserDefaults` (чтобы не сбрасывалась после перезапуска);
- unit-тесты для `CalculateTipUseCase` и `MenuViewModel`;
- вынос форматирования денег в отдельный сервис;
- подготовка локализации (`Localizable.strings`);
- backend/JSON-источник меню вместо статического репозитория.

---

Если хочешь, следующим сообщением могу добавить отдельный раздел в README:
**“Пошаговый разбор анимаций с мини-экспериментами”** (что именно поменять в параметрах `spring`, чтобы руками увидеть разницу).
# FirstPetProject

Учебный iOS-проект на SwiftUI с акцентом на **чистую структуру кода**:
- отдельный слой бизнес-логики (`Domain`);
- отдельный слой интерфейса (`Presentation`);
- типобезопасная навигация через `NavigationStack` + собственный роутер;
- два пользовательских сценария:
  - калькулятор чаевых;
  - меню кафе + итог заказа.

README написан для человека с нулевым опытом в Swift и показывает:
- какие технологии используются;
- где что лежит;
- как данные текут по проекту;
- где менять код, если хочешь добавить фичу.

---

## 1) Что делает приложение

Приложение содержит 2 основных экрана (и один итоговый):

1. **MenuView** — выбираешь позиции из меню, считаешь сумму заказа.
2. **SummaryView** — видишь выбранные позиции, выбираешь чаевые и количество людей, получаешь итог “сколько платит каждый”.
3. **TipCalculatorView** — отдельный экран калькулятора чаевых (через роутинг поддерживается).

---

## 2) Технологии и почему они здесь

- **Swift 5+** — язык разработки.
- **SwiftUI** — декларативный UI-фреймворк Apple.
- **Observation (`@Observable`, `@Bindable`)** — современная реактивность состояния (вместо старых `ObservableObject/@Published` паттернов).
- **NavigationStack** — стековая навигация между экранами.
- **MVVM + UseCase + Domain-подход** — чтобы UI не смешивался с бизнес-логикой.
- **Foundation** — базовые типы и утилиты (`UUID`, `NumberFormatter`, и т.д.).

---

## 3) Структура проекта (по папкам)

```text
FirstPetProject/
  FirstPetProjectApp.swift                # Точка входа + RootView + NavigationStack

  Domain/
    Entities/
      MenuItem.swift                      # Модели меню/заказа
      TipCalculation.swift                # Модель результата расчета чаевых

    Data/
      MenuRepository.swift                # Статическое меню (пока без API)

    UseCases/
      CalculateTipUseCase.swift           # Бизнес-операция "посчитать чаевые"

    Router/
      AppRoute.swift                      # Маршруты + AppRouter

  Presentation/
    ViewModel/
      TipCalculatorViewModel.swift        # Логика экрана чаевых
      MenuViewModel.swift                 # Логика экрана меню

    Views/
      TipCalculatorView.swift             # UI калькулятора
      MenuView.swift                      # UI меню
      SummaryView.swift                   # UI итогового экрана
```

---

## 4) Точка входа и навигация

Приложение стартует из `FirstPetProjectApp.swift`.

Ключевая идея: `RootView` держит роутер и прокидывает его в `environment`, а `NavigationStack` подписан на `router.path`.

```swift
@State private var router = AppRouter()

NavigationStack(path: $router.path) {
    MenuView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .tipCalculator:
                TipCalculatorView()
            case .menu:
                MenuView()
            case .summary(let items, let total):
                SummaryView(orderItems: items, orderTotal: total)
            }
        }
}
.environment(router)
```

### Что важно новичку:
- `NavigationStack` хранит историю экранов (как стек).
- `AppRoute` — `enum`, где перечислены все маршруты приложения.
- Для перехода используется `router.push(...)`, для возврата — `router.pop()`.

---

## 5) Архитектура: как устроены слои

### 5.1 Domain (бизнес-логика, без UI)

Файлы:
- `Domain/Entities/MenuItem.swift`
- `Domain/Entities/TipCalculation.swift`
- `Domain/UseCases/CalculateTipUseCase.swift`
- `Domain/Data/MenuRepository.swift`

Здесь **нет SwiftUI**, только логика и модели.

Пример entity (`TipCalculation`) с вычисляемыми свойствами:

```swift
struct TipCalculation {
    let billAmount: Double
    let numberOfPeople: Int
    let tipPercentage: Double

    var tipAmount: Double { billAmount * tipPercentage }
    var totalAmount: Double { billAmount + tipAmount }

    var amountPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return totalAmount / Double(numberOfPeople)
    }
}
```

### 5.2 Use Case (одна операция = один класс/протокол)

`CalculateTipUseCase` инкапсулирует “действие пользователя”: посчитать чаевые.

```swift
protocol CalculateTipUseCaseProtocol {
    func execute(billAmount: Double, numberOfPeople: Int, tipPercentage: Double) -> TipCalculation
}
```

```swift
final class CalculateTipUseCase: CalculateTipUseCaseProtocol {
    func execute(billAmount: Double, numberOfPeople: Int, tipPercentage: Double) -> TipCalculation {
        TipCalculation(
            billAmount: max(0, billAmount),
            numberOfPeople: max(1, numberOfPeople),
            tipPercentage: tipPercentage
        )
    }
}
```

### 5.3 Presentation (View + ViewModel)

ViewModel хранит состояние экрана и дергает UseCase.  
View только рисует UI и отправляет действия в ViewModel.

Пример (связка ViewModel → UseCase):

```swift
final class TipCalculatorViewModel {
    private let calculateTipUseCase: CalculateTipUseCaseProtocol
    private(set) var calculation: TipCalculation?

    init(calculateTipUseCase: CalculateTipUseCaseProtocol = CalculateTipUseCase()) {
        self.calculateTipUseCase = calculateTipUseCase
        recalculate()
    }

    func recalculate() {
        calculation = calculateTipUseCase.execute(
            billAmount: billAmount,
            numberOfPeople: numberOfPeople,
            tipPercentage: selectedTipPercentage
        )
    }
}
```

---

## 6) Поток данных (очень важно понять)

На примере калькулятора чаевых:

1. Пользователь вводит сумму в `TextField` (`TipCalculatorView`).
2. View вызывает `viewModel.updateBillAmount(...)`.
3. ViewModel обновляет `billAmountText` и вызывает `recalculate()`.
4. `recalculate()` дергает `CalculateTipUseCase`.
5. UseCase возвращает `TipCalculation`.
6. ViewModel кладет результат в `calculation`.
7. SwiftUI автоматически перерисовывает UI, потому что ViewModel помечена `@Observable`.

Это базовый цикл в SwiftUI-проектах:  
**действие пользователя → изменение состояния → перерисовка интерфейса**.

---

## 7) Экран меню: где что менять

### Где лежит:
- UI: `Presentation/Views/MenuView.swift`
- Логика: `Presentation/ViewModel/MenuViewModel.swift`
- Данные: `Domain/Data/MenuRepository.swift`
- Модель: `Domain/Entities/MenuItem.swift`

### Добавить новую позицию меню
Идешь в `MenuRepository.items` и добавляешь `MenuItem`:

```swift
MenuItem(
    emoji: "🥤",
    name: "Колд брю",
    description: "Холодный кофе долгой экстракции",
    price: 330,
    category: .coffee
)
```

### Добавить новую категорию
1. В `MenuCategory` добавить case:
```swift
case tea = "Чай"
```
2. В `MenuRepository` добавить позиции с `category: .tea`.
3. `CategoryFilterBar` сам подхватит её через `MenuCategory.allCases`.

### Изменить расчёт общей суммы заказа
Смотри `MenuViewModel.totalAmount`:

```swift
var totalAmount: Double {
    allItems.reduce(0.0) { sum, item in
        let qty = orderItems[item.id] ?? 0
        return sum + item.price * Double(qty)
    }
}
```

Если хочешь скидки/налоги — меняй именно тут (или вынеси в отдельный UseCase, когда логика станет сложной).

---

## 8) Экран итогов: что происходит

`SummaryView` получает:
- массив заказанных позиций (`orderItems`);
- сумму заказа (`orderTotal`).

Инициализирует `TipCalculatorViewModel`, подставляет `orderTotal` как сумму чека, а дальше использует ту же логику чаевых:

```swift
let vm = TipCalculatorViewModel()
vm.updateBillAmount(String(orderTotal))
_viewModel = State(initialValue: vm)
```

То есть ты **переиспользуешь одну и ту же бизнес-логику** в двух местах.

---

## 9) Форматирование денег

В проекте форматирование вынесено во ViewModel (`formatCurrency`), например:

```swift
let formatter = NumberFormatter()
formatter.numberStyle = .decimal
formatter.minimumFractionDigits = 2
formatter.maximumFractionDigits = 2
formatter.groupingSeparator = " "
formatter.decimalSeparator = ","
```

Это удобно для обучения, но в “боевом” проекте можно:
- вынести в отдельный `CurrencyFormatter` сервис;
- переиспользовать в разных ViewModel без копипаста.

---

## 10) Как добавить новый экран (пошагово)

Пример: “Хочу экран `AboutView`”.

1. Создать файл `Presentation/Views/AboutView.swift`.
2. Добавить route в `AppRoute`:
```swift
case about
```
3. Добавить обработку в `navigationDestination` в `RootView`:
```swift
case .about:
    AboutView()
```
4. Из нужного места вызвать:
```swift
router.push(.about)
```

---

## 11) Как добавить новую бизнес-логику правильно

Пример: “добавить сервисный сбор 5%”.

Рекомендуемый путь:
1. Создаешь новую entity/расширяешь `TipCalculation` (если нужно).
2. Меняешь `CalculateTipUseCase` (или создаешь новый UseCase).
3. ViewModel просто получает новый результат и показывает.
4. View почти не трогаешь (только отображение новых полей).

Идея: **сложность должна жить в Domain, а не в View**.

---

## 12) Мини-словарь Swift/SwiftUI терминов из проекта

- `struct` — тип-значение (часто для моделей и View).
- `class` — ссылочный тип (здесь используется для ViewModel/Router).
- `enum` — набор фиксированных вариантов (`AppRoute`, `MenuCategory`).
- `@State` — локальное состояние View.
- `@Environment` — доступ к объектам из окружения SwiftUI.
- `@Observable` — автоматически уведомляет UI о смене состояния.
- `Binding` — двусторонняя связь (например, TextField ↔ ViewModel).
- `computed property` — вычисляемое свойство (`var totalAmount: Double { ... }`).
- `guard` — ранняя проверка условий.
- `protocol` — контракт поведения (для DI/тестируемости).
