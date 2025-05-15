//
//  Meal.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import Foundation

struct Meal: Identifiable {
    let id = UUID()
    let name: String
    let carbs: Double  // grams of carbohydrates
    let imageName: String?
}

// Sample data for development/testing
let sampleMeals: [Meal] = [
    Meal(name: "Oatmeal with Berries", carbs: 45, imageName: "oatmeal"),
    Meal(name: "Grilled Chicken Salad", carbs: 12, imageName: "salad"),
    Meal(name: "Apple and Peanut Butter", carbs: 30, imageName: "apple_pb")
]

