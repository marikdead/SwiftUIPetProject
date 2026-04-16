import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let palette = settings.palette

        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Настройки")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                    Text("Персонализация интерфейса")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Тёмная тема")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.textPrimary)
                            Text("Включите, чтобы использовать текущий тёмный стиль")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(palette.textMuted)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { settings.isDarkMode },
                                set: { settings.isDarkMode = $0 }
                            )
                        )
                        .labelsHidden()
                    }
                    .padding(16)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }

                Spacer()
            }
            .padding(20)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
}
