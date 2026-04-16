import Foundation

enum AppTab: Hashable {
    case menu
    case settings
    case stats
    case history
}

@Observable
final class AppShellState {
    var selectedTab: AppTab = .menu
}
