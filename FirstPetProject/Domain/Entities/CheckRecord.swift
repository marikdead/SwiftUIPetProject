// MARK: - DOMAIN LAYER → Entity
// CheckRecord — SwiftData модель одного сохранённого чека.

import Foundation
import SwiftData

@Model
final class CheckRecord {
    var id: UUID
    var date: Date
    var billAmount: Double
    var tipPercentage: Double
    var tipAmount: Double
    var totalAmount: Double
    var numberOfPeople: Int
    var itemNames: [String]

    // Вычисляемое свойство — не хранится в базе, считается на лету
    var amountPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return totalAmount / Double(numberOfPeople)
    }

    init(
        billAmount: Double,
        tipPercentage: Double,
        tipAmount: Double,
        totalAmount: Double,
        numberOfPeople: Int,
        itemNames: [String]
    ) {
        self.id = UUID()
        self.date = Date()
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.numberOfPeople = numberOfPeople
        self.itemNames = itemNames
    }
}
