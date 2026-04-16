// MARK: - PRESENTATION LAYER → View
// HistoryView — экран истории сохранённых чеков.
// Показывает список всех чеков, отсортированных по дате (новые сверху).

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CheckRecord.date, order: .reverse)
    private var records: [CheckRecord]
    @State private var selectedRecord: CheckRecord? = nil

    private let fetchUseCase = FetchChecksUseCase()
    private let formatter = CheckCurrencyFormatter()

    var body: some View {
        let palette = settings.palette

        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HistoryHeaderView(palette: palette)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if records.isEmpty {
                    HistoryEmptyView(palette: palette)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(records) { record in
                                HistoryRowCard(
                                    record: record,
                                    format: { formatter.format($0) },
                                    palette: palette,
                                    isExpanded: selectedRecord?.id == record.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            selectedRecord = selectedRecord?.id == record.id ? nil : record
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        
    }
}

// MARK: - Header

private struct HistoryHeaderView: View {
    let palette: AppPalette

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("История")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text("Все ваши визиты")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Empty State

private struct HistoryEmptyView: View {
    let palette: AppPalette

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧾")
                .font(.system(size: 56))
            Text("Пока нет сохранённых чеков")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textPrimary)
            Text("После оформления заказа нажмите\n«Сохранить чек» на экране итогов")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(palette.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Row Card

private struct HistoryRowCard: View {
    let record: CheckRecord
    let format: (Double) -> String
    let palette: AppPalette
    let isExpanded: Bool
    let onTap: () -> Void

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: record.date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header — всегда видна
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(palette.accentSoft)
                            .frame(width: 44, height: 44)
                        Text("🧾")
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(dateText)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.textPrimary)
                        HStack(spacing: 6) {
                            Label("\(record.numberOfPeople) чел.", systemImage: "person.2")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(palette.textMuted)
                            Text("·")
                                .foregroundStyle(palette.textMuted)
                            Text("\(Int(record.tipPercentage * 100))% чаевых")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(palette.textMuted)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(format(record.totalAmount))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.textPrimary)
                        Text(format(record.amountPerPerson) + " / чел.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.accentStart)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.textMuted)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                Divider()
                    .background(palette.border)
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    HistoryDetailRow(icon: "doc.text", title: "Счёт", value: format(record.billAmount), palette: palette)
                    Divider().background(palette.border).padding(.horizontal, 16)
                    HistoryDetailRow(icon: "star", title: "Чаевые", value: format(record.tipAmount), palette: palette, valueColor: palette.accentStart)
                    Divider().background(palette.border).padding(.horizontal, 16)
                    HistoryDetailRow(icon: "sum", title: "Итого", value: format(record.totalAmount), palette: palette, isBold: true)
                }
                .padding(.vertical, 4)

                if !record.itemNames.isEmpty {
                    Divider()
                        .background(palette.border)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Состав заказа", systemImage: "list.bullet")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.textMuted)

                        FlowLayout(items: record.itemNames) { name in
                            Text(name)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(palette.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(palette.secondarySurface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
            }
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isExpanded ? palette.accentStart.opacity(0.3) : palette.border, lineWidth: 1)
        )
        .shadow(color: isExpanded ? palette.accentStart.opacity(0.1) : .clear, radius: 12, y: 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isExpanded)
    }
}

private struct HistoryDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let palette: AppPalette
    var valueColor: Color? = nil
    var isBold: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(palette.textMuted)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: isBold ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isBold ? palette.textSecondary : palette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: isBold ? .bold : .medium, design: .rounded))
                .foregroundStyle(valueColor ?? palette.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - FlowLayout (чипы в несколько строк)

private struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    @State private var totalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= rowHeight
                            rowHeight = 0
                        }
                        rowHeight = max(rowHeight, d.height)
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { binding.wrappedValue = $0 }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .environment(AppSettings())
}
