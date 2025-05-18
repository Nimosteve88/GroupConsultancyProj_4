//
//  AdviceEngine.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import Foundation
import Combine

class AdviceEngine: ObservableObject {
    static let shared = AdviceEngine()

    @Published var currentAdvice: String = ""
    @Published var riskLevel: RiskLevel = .low

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Observe meal and glucose changes to update advice
    }

    func generateAdvice(meals: [Meal], glucoseSamples: [GlucoseSample]) {
        // Stub logic for risk and advice
        riskLevel = .medium
        currentAdvice = "Consider a 10-min walk to stabilize your glucose."
    }
}
