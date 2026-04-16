// MARK: - DOMAIN LAYER → Service
// CheckCurrencyFormatter — переиспользуемый форматтер денег.
// Используется в HistoryView и StatsView.
// (В MenuViewModel форматтер пока дублируется — это нормально для учебного проекта,
//  но в будущем можно заменить и там на этот класс.)

import Foundation

final class CheckCurrencyFormatter {
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.decimalSeparator = ","
        return f
    }()

    func format(_ value: Double) -> String {
        (formatter.string(from: NSNumber(value: value)) ?? "0,00") + " ₽"
    }
}
