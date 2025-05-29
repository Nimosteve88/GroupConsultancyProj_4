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

    let defaultType: MealType
    @State private var type: MealType

    @State private var name = ""
    @State private var carbs = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var date = Date()

    init(defaultType: MealType = .breakfast) {
        self.defaultType = defaultType
        _type = State(initialValue: defaultType)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Type") {
                    Picker("Meal Type", selection: $type) {
                        ForEach(MealType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard
                            let cd = Double(carbs),
                            let pd = Double(protein),
                            let fd = Double(fat),
                            let fib = Double(fiber),
                            !name.isEmpty
                        else { return }

                        let meal = Meal(
                            name: name,
                            type: type,
                            carbs: cd,
                            protein: pd,
                            fat: fd,
                            fiber: fib,
                            date: date
                        )
                        mealLogVM.add(meal)
                        dismiss()
                    }
                    .disabled(name.isEmpty
                              || Double(carbs) == nil
                              || Double(protein) == nil
                              || Double(fat) == nil
                              || Double(fiber) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


#Preview {
    AddMealView()
}
