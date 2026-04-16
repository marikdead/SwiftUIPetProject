//
//  SaveCheckUseCase.swift
//  FirstPetProject
//
//  Created by marikdead on 16.04.2026.
//

import SwiftData

protocol SaveCheckUseCaseProtocol {
    func execute(_ record: CheckRecord, context: ModelContext)
}

final class SaveCheckUseCase: SaveCheckUseCaseProtocol {
    func execute(_ record: CheckRecord, context: ModelContext) {
        context.insert(record)
        try? context.save()
    }
}
