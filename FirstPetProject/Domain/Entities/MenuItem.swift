// MenuItem — это позиция в меню кафе.
// Чистая модель данных, не знает про UI.
import Foundation

struct MenuItem: Identifiable, Hashable {
    let id: UUID
    let emoji: String
    let name: String
    let description: String
    let price: Double
    let category: MenuCategory

    init(
        id: UUID = UUID(),
        emoji: String,
        name: String,
        description: String,
        price: Double,
        category: MenuCategory
    ) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.description = description
        self.price = price
        self.category = category
    }
}

enum MenuCategory: String, CaseIterable {
    case coffee = "Кофе"
    case food = "Еда"
    case dessert = "Десерты"
    case drinks = "Напитки"
}

// Позиция в заказе: конкретный MenuItem + количество
struct MenuOrderItem: Identifiable {
    let id: UUID
    let menuItem: MenuItem
    var quantity: Int

    init(menuItem: MenuItem, quantity: Int = 1) {
        self.id = menuItem.id
        self.menuItem = menuItem
        self.quantity = quantity
    }

    var subtotal: Double {
        menuItem.price * Double(quantity)
    }
}
