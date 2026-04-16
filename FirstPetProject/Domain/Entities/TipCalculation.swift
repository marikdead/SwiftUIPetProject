// Слой Domain — это сердце приложения. Он НЕ знает про SwiftUI, UIKit или что угодно ещё.
// Здесь только бизнес-логика в чистом виде.
// Этот слой можно переиспользовать в любом другом проекте — хоть в iOS, хоть на сервере.

import Foundation

// Entity — это просто модель данных, которая описывает предметную область.
// В нашем случае — результат расчёта чаевых.
// Это не ViewModel, не State — это просто "что такое результат расчёта чаевых" с точки зрения бизнеса.
struct TipCalculation {
    /// Сумма чека, введённая пользователем
    let billAmount: Double

    /// Количество людей, которые делят счёт
    let numberOfPeople: Int

    /// Процент чаевых (например, 0.15 для 15%)
    let tipPercentage: Double

    // Computed properties — вычисляемые свойства, не хранят значение, вычисляют при обращении
    /// Сумма чаевых от всего чека
    var tipAmount: Double {
        billAmount * tipPercentage
    }

    /// Итоговая сумма: чек + чаевые
    var totalAmount: Double {
        billAmount + tipAmount
    }

    /// Сколько платит каждый человек
    var amountPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return totalAmount / Double(numberOfPeople)
    }

    /// Чаевые на одного человека
    var tipPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return tipAmount / Double(numberOfPeople)
    }
}
