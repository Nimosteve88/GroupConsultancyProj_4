//
//  MealLogViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import Foundation
import Combine

class MealLogViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    private let storeKey = "loggedMeals"

    init() {
        loadMeals()
    }

    func add(_ meal: Meal) {
        meals.insert(meal, at: 0)
        saveMeals()
    }

    func remove(at offsets: IndexSet) {
        meals.remove(atOffsets: offsets)
        saveMeals()
    }

    private func loadMeals() {
        guard let data = UserDefaults.standard.data(forKey: storeKey) else { return }
        if let decoded = try? JSONDecoder().decode([Meal].self, from: data) {
            meals = decoded
        }
    }

    private func saveMeals() {
        if let encoded = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(encoded, forKey: storeKey)
        }
    }
}
