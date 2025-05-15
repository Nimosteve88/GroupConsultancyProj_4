//
//  MealDetailView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @State private var aiFeedback: String?
    @Namespace private var animation

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let imageName = meal.imageName {
                    Image(imageName)
                        .resizable()
                        .matchedGeometryEffect(id: imageName, in: animation)
                        .scaledToFit()
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                Text(meal.name)
                    .font(.largeTitle)
                    .bold()

                HStack {
                    Label("Carbs", systemImage: "leaf.fill")
                    Spacer()
                    Text("\(Int(meal.carbs)) g")
                        .font(.title3)
                }
                .padding(.horizontal)

                Button(action: {
                    AIService.shared.analyzeMeal(meal) { feedback in
                        aiFeedback = feedback
                    }
                }) {
                    Label("Analyze Meal", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if let feedback = aiFeedback {
                    Text(feedback)
                        .padding()
                        .background(Color.primaryBackground)
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .slide))
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
        }
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MealDetailView(meal: sampleMeals[0])
        .environmentObject(HealthKitService.shared)
}

