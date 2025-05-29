//
//  MealLibraryView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

struct MealCard: View {
    let meal: Meal
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            HStack {
                Text(meal.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(meal.calories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("Carbs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.carbs))g")
                        .font(.subheadline)
                        .bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Protein")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.protein))g")
                        .font(.subheadline)
                        .bold()
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("Fat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.fat))g")
                        .font(.subheadline)
                        .bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Fibers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.fiber))g")
                        .font(.subheadline)
                        .bold()
                }
            }
        }
        .padding(16)
        .frame(minHeight: 150)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary, lineWidth: 3)// Change color and width as needed
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MealLibraryView: View {
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @State private var selectedType: MealType? = nil  // nil = All
    @State private var showAdd = false

    // Today's meals
    private var todayMeals: [Meal] {
        mealLogVM.meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    // Filter by selected type
    private var filteredMeals: [Meal] {
        guard let type = selectedType else { return todayMeals }
        return todayMeals.filter { $0.type == type }
    }

    // Aggregated stats
    private var totalCalories: Double {
        filteredMeals.reduce(0) { $0 + $1.calories }
    }
    private var totalCarbs: Double {
        filteredMeals.reduce(0) { $0 + $1.carbs }
    }
    private var totalProtein: Double {
        filteredMeals.reduce(0) { $0 + $1.protein }
    }

    // Grid layout
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                pickerSection
                statsSection
                mealsGrid
                Spacer()
            }
            .navigationTitle("Log Meal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMealView(defaultType: selectedType ?? .breakfast)
                    .environmentObject(mealLogVM)
            }
        }
    }

    // MARK: - Subviews
    private var pickerSection: some View {
        Picker(selection: $selectedType, label: Text("Meal Type")) {
            Text("All").tag(Optional<MealType>(nil))
            ForEach(MealType.allCases, id: \ .self) { type in
                Text(type.rawValue).tag(Optional(type))
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(title: "Calories", value: String(format: "%.0f kcal", totalCalories), icon: "flame.fill")
            StatCard(title: "Carbs", value: String(format: "%.0f g", totalCarbs), icon: "leaf.fill")
            StatCard(title: "Protein", value: String(format: "%.0f g", totalProtein), icon: "bolt.fill")
        }
        .padding(.horizontal)
    }

    private var mealsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredMeals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        MealCard(meal: meal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button(role: .destructive) {
                            mealLogVM.remove(meal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .padding(8) // outer padding
                }
            }
            .padding(.horizontal)
        }
    }
}

// Preview
#Preview {
    let session = SessionStore()
    MealLibraryView()
        .environmentObject(MealLogViewModel(session: session))
}

