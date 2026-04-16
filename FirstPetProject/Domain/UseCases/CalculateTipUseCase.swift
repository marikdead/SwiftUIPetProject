// Use Case описывает ОДНО конкретное действие, которое может выполнить пользователь.
// Принцип: один Use Case = одна операция = один метод.
// Use Case — это посредник между ViewModel и бизнес-логикой.
// Если логика усложнится (например, добавятся налоги), мы меняем только Use Case — ViewModel не трогаем.

import Foundation

// Мы объявляем протокол, а не сразу класс. Это позволяет:
// 1. Легко подменять реализацию в тестах (mock-объект)
// 2. Явно описывать "контракт" — что умеет этот Use Case
// ViewModel будет держать ссылку НА ПРОТОКОЛ, а не на конкретный класс.

protocol CalculateTipUseCaseProtocol {
    /// Единственный метод Use Case — принимает параметры, возвращает готовую модель
    func execute(billAmount: Double, numberOfPeople: Int, tipPercentage: Double) -> TipCalculation
}

// Здесь — конкретная логика расчёта.
// Никакого @Published, никакого @State — это просто функция.

final class CalculateTipUseCase: CalculateTipUseCaseProtocol {

    func execute(billAmount: Double, numberOfPeople: Int, tipPercentage: Double) -> TipCalculation {
        // Просто создаём Entity с нужными значениями.
        // Вся математика — внутри самой Entity (см. computed properties).
        return TipCalculation(
            billAmount: max(0, billAmount),         // защита от отрицательных значений
            numberOfPeople: max(1, numberOfPeople), // минимум 1 человек
            tipPercentage: tipPercentage
        )
    }
}
