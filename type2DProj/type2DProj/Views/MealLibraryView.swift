//
//  MealLibraryView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

struct MealLibraryView: View {
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @State private var showAdd = false

    private func removeMeals(at offsets: IndexSet) {
        for index in offsets {
            let meal = mealLogVM.meals[index]
            mealLogVM.remove(meal)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(mealLogVM.meals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        VStack(alignment: .leading) {
                            Text(meal.name).font(.headline)
                            Text("Carbs: \(Int(meal.carbs)) g • Protein: \(Int(meal.protein)) g")
                                .font(.subheadline).foregroundColor(.secondary)
                            Text("Calories: \(Int(meal.calories)) kcal")
                                .font(.subheadline).foregroundColor(.secondary)
                            Text(meal.date, style: .time).font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: removeMeals)
            }
            .navigationTitle("Meal Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMealView().environmentObject(mealLogVM)
            }
        }
    }
}



#Preview {
    let session = SessionStore()
    MealLibraryView()
        .environmentObject(HealthKitService.shared)
        .environmentObject(MealLogViewModel(session: session))
}
