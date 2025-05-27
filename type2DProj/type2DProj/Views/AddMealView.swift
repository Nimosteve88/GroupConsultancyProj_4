//
//  AddMealView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI

struct AddMealView: View {
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var carbs = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section("Meal Info") {
                    TextField("Name", text: $name)
                    TextField("Carbs (g)", text: $carbs).keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein).keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat).keyboardType(.decimalPad)
                    TextField("Fiber (g)", text: $fiber).keyboardType(.decimalPad)
                    DatePicker("Time", selection: $date)
                }
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    guard let cd = Double(carbs), let pd = Double(protein), let fd = Double(fat), let fd2 = Double(fiber), !name.isEmpty else { return }
                    mealLogVM.add(Meal(name: name, carbs: cd, protein: pd, fat: fd, fiber: fd2,calories: (fd*9)+(cd*4)+(pd*4) ,date: date))
                    dismiss() } }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

#Preview {
    AddMealView()
}
