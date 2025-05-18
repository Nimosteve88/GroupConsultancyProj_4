//
//  Meal.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import Foundation

struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    var date: Date
    var imageName: String?

    init(id: UUID = UUID(), name: String, carbs: Double, protein: Double, fat: Double, fiber: Double, date: Date = Date(), imageName: String? = nil) {
        self.id = id; self.name = name; self.carbs = carbs; self.protein = protein; self.fat = fat; self.fiber = fiber; self.date = date; self.imageName = imageName
    }
}
