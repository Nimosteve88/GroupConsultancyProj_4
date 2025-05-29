//
//  Meal.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import Foundation

enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    var id: String { rawValue }
}

struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: MealType
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    var calories: Double
    var date: Date
    var imageName: String?

    init(id: UUID = UUID(), name: String, type: MealType, carbs: Double, protein: Double, fat: Double, fiber: Double, date: Date = Date(), imageName: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        // calories formula: fat*9 + carbs*4 + protein*4
        self.calories = fat * 9 + carbs * 4 + protein * 4
        self.date = date
        self.imageName = imageName
    }
}
