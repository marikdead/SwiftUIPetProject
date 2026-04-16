//
//  FetchChecksUseCase.swift
//  FirstPetProject
//
//  Created by marikdead on 16.04.2026.
//

import SwiftData
import Foundation

protocol FetchChecksUseCaseProtocol {
    func execute(context: ModelContext) -> [CheckRecord]
}

final class FetchChecksUseCase: FetchChecksUseCaseProtocol {
    func execute(context: ModelContext) -> [CheckRecord] {
        let descriptor = FetchDescriptor<CheckRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
