// Здесь хранится статическое меню кафе.
// В реальном приложении это был бы запрос к API или локальной БД.

import Foundation

struct MenuRepository {
    static let items: [MenuItem] = [

        // MARK: Кофе
        MenuItem(
            emoji: "☕️",
            name: "Эспрессо",
            description: "Двойной, плотный, без компромиссов",
            price: 180,
            category: .coffee
        ),
        MenuItem(
            emoji: "🥛",
            name: "Флэт уайт",
            description: "Двойной ристретто с бархатным молоком",
            price: 320,
            category: .coffee
        ),
        MenuItem(
            emoji: "🧊",
            name: "Айс латте",
            description: "Эспрессо, молоко, лёд — идеально летом",
            price: 350,
            category: .coffee
        ),
        MenuItem(
            emoji: "🍵",
            name: "Матча латте",
            description: "Церемониальный матча на овсяном молоке",
            price: 390,
            category: .coffee
        ),

        // MARK: Еда
        MenuItem(
            emoji: "🥐",
            name: "Круассан",
            description: "Слоёный, масляный, только из печи",
            price: 220,
            category: .food
        ),
        MenuItem(
            emoji: "🥑",
            name: "Тост с авокадо",
            description: "Ржаной хлеб, авокадо, яйцо пашот, микрозелень",
            price: 490,
            category: .food
        ),
        MenuItem(
            emoji: "🥗",
            name: "Боул с курицей",
            description: "Киноа, руккола, черри, заправка тахини",
            price: 580,
            category: .food
        ),
        MenuItem(
            emoji: "🧀",
            name: "Сырный сэндвич",
            description: "Чиабатта, три вида сыра, песто",
            price: 420,
            category: .food
        ),

        // MARK: Десерты
        MenuItem(
            emoji: "🍰",
            name: "Чизкейк",
            description: "Нью-йоркский, с ягодным соусом",
            price: 380,
            category: .dessert
        ),
        MenuItem(
            emoji: "🍫",
            name: "Брауни",
            description: "Тёмный шоколад 72%, хрустящая корочка",
            price: 290,
            category: .dessert
        ),
        MenuItem(
            emoji: "🧁",
            name: "Кардамоновый маффин",
            description: "Мягкий, ароматный, со сливочным кремом",
            price: 260,
            category: .dessert
        ),

        // MARK: Напитки
        MenuItem(
            emoji: "🍋",
            name: "Лимонад имбирь–лимон",
            description: "Свежий имбирь, лимон, мёд, газированная вода",
            price: 310,
            category: .drinks
        ),
        MenuItem(
            emoji: "🫐",
            name: "Смузи ягодный",
            description: "Черника, банан, кокосовое молоко",
            price: 360,
            category: .drinks
        ),
        MenuItem(
            emoji: "🍊",
            name: "Свежевыжатый апельсиновый",
            description: "Четыре апельсина, ничего лишнего",
            price: 340,
            category: .drinks
        ),
    ]
}
