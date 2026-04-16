// AppRoute — перечисление всех экранов приложения.
// Используется NavigationStack для типобезопасной навигации.

import SwiftUI

enum AppRoute: Hashable {
    case summary(items: [MenuOrderItem], total: Double)
}

// Так как MenuOrderItem не Hashable по умолчанию (содержит UUID),
// реализуем вручную через id позиций.
extension AppRoute {
    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.summary(let a, let at), .summary(let b, let bt)):
            return at == bt && a.map(\.id) == b.map(\.id)
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .summary(let items, let total):
            hasher.combine(0)
            hasher.combine(items.map(\.id))
            hasher.combine(total)
        }
    }
}


@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
