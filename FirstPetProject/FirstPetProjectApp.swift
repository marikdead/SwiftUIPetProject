import SwiftUI
import SwiftData

@main
struct FirstPetProjectApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: CheckRecord.self)
        }
    }
}

struct RootView: View {
    @State private var router = AppRouter()
    @State private var settings = AppSettings()
    @State private var shellState = AppShellState()

    var body: some View {
        @Bindable var router = router
        @Bindable var settings = settings
        @Bindable var shellState = shellState

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
            .tabItem {
                Label("Меню", systemImage: "fork.knife")
            }

            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
            
            HistoryView()
                .tabItem { Label("История", systemImage: "clock") }
                .tag(AppTab.history)

            StatsView()
                .tabItem { Label("Статистика", systemImage: "chart.bar") }
                .tag(AppTab.stats)
        }
        .environment(router)
        .environment(settings)
        .environment(shellState)
        .preferredColorScheme(settings.themeMode.colorScheme)
        .tint(settings.palette.accentStart)
    }
}
