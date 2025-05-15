//
//  MealLibraryView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

struct MealLibraryView: View {
    @State private var searchText = ""
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var filteredMeals: [Meal] {
        if searchText.isEmpty { return sampleMeals }
        return sampleMeals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredMeals) { meal in
                        NavigationLink(destination: MealDetailView(meal: meal)) {
                            MealCard(meal: meal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Library")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}

struct MealCard: View {
    let meal: Meal
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading) {
            if let imageName = meal.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            }
            Text(meal.name)
                .font(.headline)
                .padding(.top, 8)
            Text("\(Int(meal.carbs)) g carbs")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
#Preview {
    MealLibraryView()
        .environmentObject(HealthKitService.shared)
}
