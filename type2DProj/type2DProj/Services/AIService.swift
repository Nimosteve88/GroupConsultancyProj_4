//
//  AIService.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import Foundation

class AIService {
    static let shared = AIService()

    private init() {}

    func analyzeMeal(_ meal: Meal, completion: @escaping (String) -> Void) {
        // TODO: integrate with backend/ML model
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion("This meal is well-balanced for your carbs target.")
        }
    }
}
