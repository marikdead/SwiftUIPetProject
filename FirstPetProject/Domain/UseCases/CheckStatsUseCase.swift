//
//  CheckStatsUseCase.swift
//  FirstPetProject
//
//  Created by marikdead on 16.04.2026.
//

import Foundation

struct CheckStats {
    let averageBill: Double
    let averageTip: Double
    let totalSpent: Double
    let checksCount: Int
    // для графика — последние 7 записей
    let recentTotals: [(date: Date, total: Double)]
}

protocol CheckStatsUseCaseProtocol {
    func execute(records: [CheckRecord]) -> CheckStats
}

final class CheckStatsUseCase: CheckStatsUseCaseProtocol {
    func execute(records: [CheckRecord]) -> CheckStats {
        guard !records.isEmpty else {
            return CheckStats(averageBill: 0, averageTip: 0,
                              totalSpent: 0, checksCount: 0, recentTotals: [])
        }
        let avgBill = records.map(\.billAmount).reduce(0, +) / Double(records.count)
        let avgTip  = records.map(\.tipPercentage).reduce(0, +) / Double(records.count)
        let total   = records.map(\.totalAmount).reduce(0, +)
        let recent  = Array(records.prefix(7)).map { ($0.date, $0.totalAmount) }
        return CheckStats(averageBill: avgBill, averageTip: avgTip,
                          totalSpent: total, checksCount: records.count,
                          recentTotals: recent)
    }
}
