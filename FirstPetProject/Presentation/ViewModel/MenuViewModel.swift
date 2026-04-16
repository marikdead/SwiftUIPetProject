// MenuViewModel управляет состоянием экрана меню:
// какие позиции выбраны, сколько штук, фильтр по категории.
//
// Не импортирует SwiftUI — только Foundation.

import Foundation

@Observable
final class MenuViewModel {
    // Переменные
    /// Все доступные позиции меню (из репозитория)
    let allItems: [MenuItem] = MenuRepository.items
    /// Текущий фильтр по категории. nil = показать всё
    var selectedCategory: MenuCategory? = nil
    /// Текущий заказ: id позиции → количество
    private(set) var orderItems: [UUID: Int] = [:]

    // Computed
    /// Позиции, отфильтрованные по категории
    var filteredItems: [MenuItem] {
        guard let category = selectedCategory else { return allItems }
        return allItems.filter { $0.category == category }
    }

    /// Итоговая сумма заказа
    var totalAmount: Double {
        allItems.reduce(0.0) { sum, item in
            let qty = orderItems[item.id] ?? 0
            return sum + item.price * Double(qty)
        }
    }

    /// Общее количество позиций в заказе (для бейджа)
    var totalQuantity: Int {
        orderItems.values.reduce(0, +)
    }

    /// Заказ в виде массива для передачи на SummaryView
    var orderedItems: [MenuOrderItem] {
        allItems
            .compactMap { item -> MenuOrderItem? in
                guard let qty = orderItems[item.id], qty > 0 else { return nil }
                return MenuOrderItem(menuItem: item, quantity: qty)
            }
    }

    /// Есть хотя бы одна позиция в заказе
    var hasOrder: Bool {
        totalQuantity > 0
    }

    // Actions

    /// Количество данного item в заказе
    func quantity(for item: MenuItem) -> Int {
        orderItems[item.id] ?? 0
    }

    /// Добавить одну единицу позиции
    func add(_ item: MenuItem) {
        orderItems[item.id, default: 0] += 1
    }

    /// Убрать одну единицу позиции (минимум 0)
    func remove(_ item: MenuItem) {
        guard let current = orderItems[item.id], current > 0 else { return }
        if current == 1 {
            orderItems.removeValue(forKey: item.id)
        } else {
            orderItems[item.id] = current - 1
        }
    }

    /// Выбрать категорию (повторный тап = сбросить фильтр)
    func selectCategory(_ category: MenuCategory) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }

    /// Очистить весь заказ
    func clearOrder() {
        orderItems = [:]
    }

    /// Форматирование данных перед показом
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted) ₽"
    }
}
