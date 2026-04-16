// MARK: - PRESENTATION LAYER → View
// StatsView — экран статистики по сохранённым чекам.
// Показывает средние значения и график последних 7 чеков.

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    
    // Автоматически следим за изменениями в базе
    @Query private var records: [CheckRecord]

    @State private var stats: CheckStats? = nil

    private let statsUseCase = CheckStatsUseCase()
    private let formatter = CheckCurrencyFormatter()

    var body: some View {
        let palette = settings.palette

        ZStack {
            palette.background.ignoresSafeArea()

            if let stats, stats.checksCount > 0 {
                ScrollView {
                    VStack(spacing: 20) {
                        StatsHeaderView(palette: palette)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        StatsCardsRow(
                            stats: stats,
                            format: { formatter.format($0) },
                            palette: palette
                        )
                        .padding(.horizontal, 20)

                        StatsChartCard(
                            stats: stats,
                            format: { formatter.format($0) },
                            palette: palette
                        )
                        .padding(.horizontal, 20)

                        StatsTotalCard(
                            stats: stats,
                            format: { formatter.format($0) },
                            palette: palette
                        )
                        .padding(.horizontal, 20)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
            } else {
                StatsEmptyView(palette: palette)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
        }
        .onAppear {
            updateStats()
        }
        // Пересчитываем статистику каждый раз, когда меняется массив records в базе
        .onChange(of: records) {
            updateStats()
        }
    }
    
    private func updateStats() {
        stats = statsUseCase.execute(records: records)
    }
}

// MARK: - Header

private struct StatsHeaderView: View {
    let palette: AppPalette

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Статистика")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text("Ваши траты в цифрах")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Empty State

private struct StatsEmptyView: View {
    let palette: AppPalette

    var body: some View {
        VStack(spacing: 0) {
            StatsHeaderView(palette: palette)

            Spacer()

            VStack(spacing: 16) {
                Text("📊")
                    .font(.system(size: 56))
                Text("Нет данных для анализа")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text("Сохраните несколько чеков,\nи здесь появится ваша статистика")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }
}

// MARK: - Stat Cards Row (средний чек + средние чаевые)

private struct StatsCardsRow: View {
    let stats: CheckStats
    let format: (Double) -> String
    let palette: AppPalette

    var body: some View {
        HStack(spacing: 12) {
            StatsSmallCard(
                icon: "doc.text",
                label: "Средний чек",
                value: format(stats.averageBill),
                palette: palette
            )
            StatsSmallCard(
                icon: "star",
                label: "Средние чаевые",
                value: "\(Int((stats.averageTip * 100).rounded()))%",
                palette: palette,
                accent: true
            )
        }
    }
}

private struct StatsSmallCard: View {
    let icon: String
    let label: String
    let value: String
    let palette: AppPalette
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent ? palette.accentSoft : palette.secondarySurface)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent ? palette.accentStart : palette.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(accent ? palette.accentStart : palette.textPrimary)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accent ? palette.accentStart.opacity(0.25) : palette.border, lineWidth: 1)
        )
    }
}

// MARK: - Chart Card

private struct StatsChartCard: View {
    let stats: CheckStats
    let format: (Double) -> String
    let palette: AppPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Последние визиты", systemImage: "chart.bar")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textMuted)

            if stats.recentTotals.isEmpty {
                Text("Недостаточно данных")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(palette.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            } else {
                Chart {
                    ForEach(stats.recentTotals.reversed(), id: \.date) { item in
                        BarMark(
                            x: .value("Дата", item.date, unit: .day),
                            y: .value("Сумма", item.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accentStart, palette.accentEnd],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.defaultDigits), centered: true)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(palette.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(palette.border)
                        AxisValueLabel()
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(palette.textMuted)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(20)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

// MARK: - Total Card

private struct StatsTotalCard: View {
    let stats: CheckStats
    let format: (Double) -> String
    let palette: AppPalette

    var body: some View {
        VStack(spacing: 0) {
            // Акцентная шапка с итогом
            VStack(spacing: 6) {
                Text("Потрачено всего")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textMuted)
                Text(format(stats.totalSpent))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText(value: stats.totalSpent))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                LinearGradient(
                    colors: [palette.accentStart.opacity(0.35), palette.accentEnd.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            Divider().background(palette.border)

            // Детали
            VStack(spacing: 0) {
                StatsTotalRow(
                    icon: "checkmark.circle",
                    title: "Всего визитов",
                    value: "\(stats.checksCount)",
                    palette: palette
                )
                Divider().background(palette.border).padding(.horizontal, 20)
                StatsTotalRow(
                    icon: "doc.text",
                    title: "Средний чек",
                    value: format(stats.averageBill),
                    palette: palette
                )
                Divider().background(palette.border).padding(.horizontal, 20)
                StatsTotalRow(
                    icon: "star",
                    title: "Средние чаевые",
                    value: "\(Int((stats.averageTip * 100).rounded()))%",
                    palette: palette,
                    valueColor: palette.accentStart
                )
            }
            .padding(.vertical, 8)
            .background(palette.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.border, lineWidth: 1)
        )
        .shadow(color: palette.accentStart.opacity(0.12), radius: 20, y: 8)
    }
}

private struct StatsTotalRow: View {
    let icon: String
    let title: String
    let value: String
    let palette: AppPalette
    var valueColor: Color? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(palette.textMuted)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(palette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor ?? palette.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

#Preview {
    StatsView()
        .environment(AppSettings())
}
