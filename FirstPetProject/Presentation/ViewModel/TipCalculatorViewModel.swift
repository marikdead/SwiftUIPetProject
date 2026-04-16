// Слой Presentation — это всё, что связано с отображением данных на экране.
// ViewModel — посредник между View и Domain.
// Главные правила ViewModel:
// 1. ViewModel НЕ импортирует SwiftUI (только Foundation + Combine/Observable)
// 2. ViewModel НИЧЕГО не знает про конкретный View
// 3. ViewModel держит состояние экрана и вызывает Use Cases
// 4. View только читает из ViewModel и вызывает её методы

import Foundation
import Combine

// @Observable — это современный способ делать реактивные модели в SwiftUI.
// Когда меняется любое свойство, помеченное @Observable — View автоматически перерисовывается.

@Observable
final class TipCalculatorViewModel {
    // Эти свойства двусторонне привязаны к View через Binding

    /// Текстовое поле суммы чека — храним строку, потому что пользователь вводит текст
    var billAmountText: String = ""

    /// Количество людей
    var numberOfPeople: Int = 2

    /// Выбранный процент чаевых (0.0 = нет чаевых, 0.15 = 15%, и т.д.)
    var selectedTipPercentage: Double = 0.15

    // MARK: - Output State (то, что показываем пользователю)
    // Это результат расчёта. View только читает их — не меняет напрямую.

    /// Текущий результат расчёта. Optional — пока сумма не введена, расчёта нет.
    private(set) var calculation: TipCalculation?

    // MARK: - Dependency (зависимость)
    // ViewModel получает Use Case через инициализатор (Dependency Injection).
    // Это значит: ViewModel не создаёт Use Case сама — ей его "дают снаружи".
    // Плюс: в тестах можно передать MockCalculateTipUseCase и тестировать ViewModel изолированно.

    private let calculateTipUseCase: CalculateTipUseCaseProtocol

    // MARK: - Init
    init(calculateTipUseCase: CalculateTipUseCaseProtocol = CalculateTipUseCase()) {
        self.calculateTipUseCase = calculateTipUseCase
        // Запускаем первый расчёт сразу с дефолтными значениями
        recalculate()
    }

    // MARK: - Доступные варианты чаевых
    // Это тоже бизнес-данные — какие проценты показывать пользователю.
    // Выносим сюда (а не в View), потому что View не должен знать бизнес-логику.

    let tipOptions: [Double] = [0.0, 0.10, 0.15, 0.18, 0.20, 0.25]

    // MARK: - Computed: преобразованная сумма чека
    // Конвертируем строку из текстового поля в Double для расчёта

    private var billAmount: Double {
        // Заменяем запятую на точку — на случай если у пользователя русская локаль
        let normalized = billAmountText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    // MARK: - Форматированные значения для отображения
    // Форматирование — это задача Presentation слоя. Не Domain!

    /// "15%" — строка для отображения процента
    func formattedPercentage(_ percentage: Double) -> String {
        let value = Int(percentage * 100)
        return value == 0 ? "Без\nчаевых" : "\(value)%"
    }

    /// Форматируем Double в строку вида "1 234,50 ₽"
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0,00"
        return "\(formatted) ₽"
    }

    // MARK: - Actions (действия, которые вызывает View)

    /// Вызывается каждый раз, когда изменяется любой input
    func recalculate() {
        calculation = calculateTipUseCase.execute(
            billAmount: billAmount,
            numberOfPeople: numberOfPeople,
            tipPercentage: selectedTipPercentage
        )
    }

    /// Выбор процента чаевых
    func selectTip(_ percentage: Double) {
        selectedTipPercentage = percentage
        recalculate()
    }

    /// Изменение количества людей
    func changePeople(by delta: Int) {
        let newValue = numberOfPeople + delta
        guard newValue >= 1 && newValue <= 20 else { return }
        numberOfPeople = newValue
        recalculate()
    }

    /// Обновление суммы чека
    func updateBillAmount(_ text: String) {
        billAmountText = text
        recalculate()
    }
}
